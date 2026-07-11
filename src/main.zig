const std = @import("std");
const Io = std.Io;
const zline = @import("zline");

const FileEntry = zline.walker.FileEntry;

const Progress = struct {
    done: std.atomic.Value(usize),
    total: usize,
    finished: std.atomic.Value(bool),

    fn init(total: usize) Progress {
        return .{
            .done = std.atomic.Value(usize).init(0),
            .total = total,
            .finished = std.atomic.Value(bool).init(false),
        };
    }

    fn inc(self: *Progress) void {
        _ = self.done.fetchAdd(1, .monotonic);
    }

    fn finish(self: *Progress) void {
        self.finished.store(true, .release);
    }
};

const ChunkResult = struct {
    counts: zline.walker.CountsByLang,
    arena: std.heap.ArenaAllocator,
};

fn countChunk(entries: []const FileEntry, io: Io, progress: *Progress) ChunkResult {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();
    var counts = zline.walker.CountsByLang.init(allocator);
    for (entries) |fe| {
        const fc = zline.counter.countFile(allocator, io, fe.path, fe.lang) catch continue;
        const gop = counts.getOrPut(fe.lang.name) catch continue;
        if (gop.found_existing) {
            gop.value_ptr.files += fc.files;
            gop.value_ptr.lines += fc.lines;
            gop.value_ptr.code += fc.code;
            gop.value_ptr.comments += fc.comments;
            gop.value_ptr.blanks += fc.blanks;
        } else {
            gop.value_ptr.* = fc;
        }
        progress.inc();
    }
    return .{ .counts = counts, .arena = arena };
}

const ThreadArg = struct {
    entries: []const FileEntry,
    out: *ChunkResult,
    io: Io,
    progress: *Progress,
};

fn threadRun(ta: *ThreadArg) void {
    ta.out.* = countChunk(ta.entries, ta.io, ta.progress);
}

fn reportProgress(io: Io, progress: *Progress) void {
    var buf: [256]u8 = undefined;
    var writer = Io.File.writer(Io.File.stderr(), io, &buf);
    const w = &writer.interface;

    while (!progress.finished.load(.acquire)) {
        const done = progress.done.load(.acquire);
        const pct = if (progress.total > 0) done * 100 / progress.total else 0;
        w.print("\rCounting files... [{d}/{d}] {d}%", .{ done, progress.total, pct }) catch {};
        w.flush() catch {};
        Io.sleep(io, Io.Duration.fromMilliseconds(50), .real) catch {};
    }

    const done = progress.done.load(.acquire);
    w.print("\rCounting files... [{d}/{d}] 100%\n", .{ done, progress.total }) catch {};
    w.flush() catch {};
}

const Args = struct {
    path: []const u8 = ".",
    help: bool = false,
    version: bool = false,
    sort_by: SortBy = .name,
    jobs: ?usize = null,
    fields: []const Field = &.{},
};

const SortBy = enum {
    name,
    files,
    lines,
    code,
    comments,
    blanks,
};

const Field = enum {
    language,
    files,
    lines,
    code,
    comments,
    blanks,
};

const all_fields = [_]Field{ .language, .files, .lines, .code, .comments, .blanks };

fn parseSortBy(s: []const u8) !SortBy {
    if (std.mem.eql(u8, s, "name")) return .name;
    if (std.mem.eql(u8, s, "files")) return .files;
    if (std.mem.eql(u8, s, "lines")) return .lines;
    if (std.mem.eql(u8, s, "code")) return .code;
    if (std.mem.eql(u8, s, "comments")) return .comments;
    if (std.mem.eql(u8, s, "blanks")) return .blanks;
    return error.InvalidSortField;
}

fn parseFields(allocator: std.mem.Allocator, s: []const u8) ![]const Field {
    var list: std.ArrayList(Field) = .empty;
    var it = std.mem.splitScalar(u8, s, ',');
    while (it.next()) |token| {
        const trimmed = std.mem.trim(u8, token, " ");
        if (std.mem.eql(u8, trimmed, "language")) {
            try list.append(allocator, .language);
        } else if (std.mem.eql(u8, trimmed, "files")) {
            try list.append(allocator, .files);
        } else if (std.mem.eql(u8, trimmed, "lines")) {
            try list.append(allocator, .lines);
        } else if (std.mem.eql(u8, trimmed, "code")) {
            try list.append(allocator, .code);
        } else if (std.mem.eql(u8, trimmed, "comments")) {
            try list.append(allocator, .comments);
        } else if (std.mem.eql(u8, trimmed, "blanks")) {
            try list.append(allocator, .blanks);
        } else {
            return error.InvalidField;
        }
    }
    return list.toOwnedSlice(allocator);
}

fn printHelp(io: Io) void {
    var buf: [1024]u8 = undefined;
    var writer = Io.File.writer(Io.File.stderr(), io, &buf);
    const w = &writer.interface;

    w.print(
        \\Usage: zline [OPTIONS] [PATH]
        \\
        \\Count lines of code in a directory.
        \\
        \\Arguments:
        \\  PATH                 Directory to scan (default: current directory)
        \\
        \\Options:
        \\  -h, --help           Show this help message
        \\  -v, --version        Show version information
        \\  -j, --jobs N         Number of parallel jobs (default: CPU count)
        \\  --sort FIELD         Sort output by: name, files, lines, code, comments, blanks (default: name)
        \\  --fields FIELDS      Comma-separated columns to show: language, files, lines, code, comments, blanks
    , .{}) catch {};
    w.print("\n", .{}) catch {};
    w.flush() catch {};
}

fn printVersion(io: Io) void {
    var buf: [64]u8 = undefined;
    var writer = Io.File.writer(Io.File.stdout(), io, &buf);
    const w = &writer.interface;
    w.print("zline 0.1.0\n", .{}) catch {};
    w.flush() catch {};
}

fn writeSpaces(w: anytype, n: usize) !void {
    var i: usize = 0;
    while (i < n) : (i += 1)
        try w.writeByte(' ');
}

fn writeCellRJust(w: anytype, s: []const u8, width: usize) !void {
    const pad = width -| s.len;
    var i: usize = 0;
    while (i < pad) : (i += 1)
        try w.writeByte(' ');
    try w.writeAll(s);
}

fn writeCellRJustNum(w: anytype, n: u64, width: usize) !void {
    var num_buf: [32]u8 = undefined;
    const s = try std.fmt.bufPrint(&num_buf, "{d}", .{n});
    const pad = width -| s.len;
    var i: usize = 0;
    while (i < pad) : (i += 1)
        try w.writeByte(' ');
    try w.writeAll(s);
}

fn digitCount(n: u64) usize {
    if (n == 0) return 1;
    var count: usize = 0;
    var tmp = n;
    while (tmp > 0) : (tmp /= 10)
        count += 1;
    return count;
}

fn formatDuration(w: anytype, ns: u64) !void {
    if (ns >= 1_000_000_000) {
        const s = ns / 1_000_000_000;
        const tenths = (ns % 1_000_000_000) / 100_000_000;
        try w.print("{d}.{d}s", .{ s, tenths });
    } else if (ns >= 1_000_000) {
        const ms = ns / 1_000_000;
        try w.print("{d}ms", .{ms});
    } else {
        const us = ns / 1_000;
        try w.print("{d}µs", .{us});
    }
}

fn printResults(io: Io, totals: zline.walker.CountsByLang, sort_by: SortBy, scan_ns: u64, count_ns: u64, fields: []const Field) !void {
    const entry_count = totals.count();
    if (entry_count == 0) return;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var sorted = try std.ArrayList(zline.walker.CountsByLang.Entry).initCapacity(allocator, entry_count);

    var it = totals.iterator();
    while (it.next()) |entry| {
        try sorted.append(allocator, entry);
    }

    const SortContext = struct {
        sort_by: SortBy,
        fn lessThan(self: @This(), a: zline.walker.CountsByLang.Entry, b: zline.walker.CountsByLang.Entry) bool {
            switch (self.sort_by) {
                .name => return std.mem.order(u8, a.key_ptr.*, b.key_ptr.*) == .lt,
                .files => return b.value_ptr.files < a.value_ptr.files,
                .lines => return b.value_ptr.lines < a.value_ptr.lines,
                .code => return b.value_ptr.code < a.value_ptr.code,
                .comments => return b.value_ptr.comments < a.value_ptr.comments,
                .blanks => return b.value_ptr.blanks < a.value_ptr.blanks,
            }
        }
    };
    const ctx: SortContext = .{ .sort_by = sort_by };
    std.mem.sort(zline.walker.CountsByLang.Entry, sorted.items, ctx, SortContext.lessThan);

    var lang_width: usize = @max(@as(usize, "Language".len), "TOTAL".len);
    var files_width: usize = "Files".len;
    var lines_width: usize = "Lines".len;
    var code_width: usize = "Code".len;
    var comments_width: usize = "Comments".len;
    var blanks_width: usize = "Blanks".len;

    for (sorted.items) |entry| {
        const c = entry.value_ptr;
        if (c.language.name.len > lang_width) lang_width = c.language.name.len;
        if (digitCount(c.files) > files_width) files_width = digitCount(c.files);
        if (digitCount(c.lines) > lines_width) lines_width = digitCount(c.lines);
        if (digitCount(c.code) > code_width) code_width = digitCount(c.code);
        if (digitCount(c.comments) > comments_width) comments_width = digitCount(c.comments);
        if (digitCount(c.blanks) > blanks_width) blanks_width = digitCount(c.blanks);
    }

    var total_files: u64 = 0;
    var total_lines: u64 = 0;
    var total_code: u64 = 0;
    var total_comments: u64 = 0;
    var total_blanks: u64 = 0;
    for (sorted.items) |entry| {
        const c = entry.value_ptr;
        total_files += c.files;
        total_lines += c.lines;
        total_code += c.code;
        total_comments += c.comments;
        total_blanks += c.blanks;
    }
    if (digitCount(total_files) > files_width) files_width = digitCount(total_files);
    if (digitCount(total_lines) > lines_width) lines_width = digitCount(total_lines);
    if (digitCount(total_code) > code_width) code_width = digitCount(total_code);
    if (digitCount(total_comments) > comments_width) comments_width = digitCount(total_comments);
    if (digitCount(total_blanks) > blanks_width) blanks_width = digitCount(total_blanks);

    var buf: [4096]u8 = undefined;
    var writer = Io.File.writer(Io.File.stdout(), io, &buf);
    const w = &writer.interface;

    const gap: usize = 3;
    const widths = [_]usize{ lang_width, files_width, lines_width, code_width, comments_width, blanks_width };
    const headers = [_][]const u8{ "Language", "Files", "Lines", "Code", "Comments", "Blanks" };

    try w.print("\n", .{});

    try w.writeByte(' ');
    for (fields, 0..) |f, fi| {
        if (fi > 0) try writeSpaces(w, gap);
        try writeCellRJust(w, headers[@intFromEnum(f)], widths[@intFromEnum(f)]);
    }
    try w.writeByte('\n');

    var sep_chars: usize = 1;
    for (fields, 0..) |f, fi| {
        if (fi > 0) sep_chars += gap;
        sep_chars += widths[@intFromEnum(f)];
    }
    const sep = "─";
    const sep_bytes = sep_chars * sep.len;
    var sep_buf: [1024]u8 = undefined;
    var pos: usize = 0;
    while (pos < sep_bytes) : (pos += sep.len)
        @memcpy(sep_buf[pos..][0..sep.len], sep);
    try w.writeAll(sep_buf[0..sep_bytes]);
    try w.writeByte('\n');

    for (sorted.items) |entry| {
        const c = entry.value_ptr;
        try w.writeByte(' ');
        for (fields, 0..) |f, fi| {
            if (fi > 0) try writeSpaces(w, gap);
            switch (f) {
                .language => try writeCellRJust(w, c.language.name, widths[@intFromEnum(f)]),
                .files => try writeCellRJustNum(w, c.files, widths[@intFromEnum(f)]),
                .lines => try writeCellRJustNum(w, c.lines, widths[@intFromEnum(f)]),
                .code => try writeCellRJustNum(w, c.code, widths[@intFromEnum(f)]),
                .comments => try writeCellRJustNum(w, c.comments, widths[@intFromEnum(f)]),
                .blanks => try writeCellRJustNum(w, c.blanks, widths[@intFromEnum(f)]),
            }
        }
        try w.writeByte('\n');
    }

    try w.writeAll(sep_buf[0..sep_bytes]);
    try w.writeByte('\n');

    try w.writeByte(' ');
    for (fields, 0..) |f, fi| {
        if (fi > 0) try writeSpaces(w, gap);
        switch (f) {
            .language => try writeCellRJust(w, "TOTAL", widths[@intFromEnum(f)]),
            .files => try writeCellRJustNum(w, total_files, widths[@intFromEnum(f)]),
            .lines => try writeCellRJustNum(w, total_lines, widths[@intFromEnum(f)]),
            .code => try writeCellRJustNum(w, total_code, widths[@intFromEnum(f)]),
            .comments => try writeCellRJustNum(w, total_comments, widths[@intFromEnum(f)]),
            .blanks => try writeCellRJustNum(w, total_blanks, widths[@intFromEnum(f)]),
        }
    }
    try w.writeByte('\n');

    try w.print("\n", .{});

    const lang_label = if (entry_count == 1) "language" else "languages";
    const file_label = if (total_files == 1) "file" else "files";
    const line_label = if (total_lines == 1) "line" else "lines";

    try w.print("\nScan: ", .{});
    try formatDuration(w, scan_ns);
    try w.print(" · Count: ", .{});
    try formatDuration(w, count_ns);
    try w.print(" · {d} {s} ({d} {s}, {d} {s})\n", .{
        entry_count, lang_label, total_files, file_label, total_lines, line_label,
    });

    try w.flush();
}

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    const io = init.io;

    const parsed_args = parseArgs(arena, args) catch |err| {
        std.debug.print("error: {s}\n\n", .{@errorName(err)});
        printHelp(io);
        return;
    };

    if (parsed_args.help) {
        printHelp(io);
        return;
    }
    if (parsed_args.version) {
        printVersion(io);
        return;
    }

    const t0 = Io.Timestamp.now(io, .awake).nanoseconds;

    {
        var buf: [256]u8 = undefined;
        var writer = Io.File.writer(Io.File.stderr(), io, &buf);
        const w = &writer.interface;
        w.print("Scanning '{s}'...", .{parsed_args.path}) catch {};
        w.flush() catch {};
    }

    const entries = try zline.walker.collectFiles(arena, io, parsed_args.path);
    const t1 = Io.Timestamp.now(io, .awake).nanoseconds;

    {
        var buf: [256]u8 = undefined;
        var writer = Io.File.writer(Io.File.stderr(), io, &buf);
        const w = &writer.interface;
        w.print(" found {d} source files\n", .{entries.len}) catch {};
        w.flush() catch {};
    }

    if (entries.len == 0) {
        var buf: [256]u8 = undefined;
        var writer = Io.File.writer(Io.File.stderr(), io, &buf);
        const w = &writer.interface;
        w.print("No source files found in '{s}'.\n", .{parsed_args.path}) catch {};
        w.flush() catch {};
        return;
    }

    const cpu_count = try std.Thread.getCpuCount();
    const n_jobs = parsed_args.jobs orelse @max(cpu_count, 1);
    const chunk_size = (entries.len + n_jobs - 1) / n_jobs;
    const n_chunks = @min(n_jobs, entries.len);

    const threads = try arena.alloc(std.Thread, n_chunks - 1);
    const results = try arena.alloc(ChunkResult, n_chunks);

    var progress = Progress.init(entries.len);

    const reporter = try std.Thread.spawn(.{}, reportProgress, .{ io, &progress });

    var i: usize = 0;
    var chunk_i: usize = 0;
    var threads_spawned: usize = 0;
    while (i < entries.len and chunk_i < n_chunks) : (chunk_i += 1) {
        const end = @min(i + chunk_size, entries.len);

        if (chunk_i == n_chunks - 1) {
            results[chunk_i] = countChunk(entries[i..end], io, &progress);
        } else {
            const ta = try arena.create(ThreadArg);
            ta.* = .{ .entries = entries[i..end], .out = &results[chunk_i], .io = io, .progress = &progress };
            threads[threads_spawned] = try std.Thread.spawn(.{}, threadRun, .{ta});
            threads_spawned += 1;
        }
        i = end;
    }

    for (threads[0..threads_spawned]) |t| {
        t.join();
    }

    progress.finish();
    reporter.join();
    const t2 = Io.Timestamp.now(io, .awake).nanoseconds;

    var totals = zline.walker.CountsByLang.init(arena);

    for (results[0..chunk_i]) |*cr| {
        var it = cr.counts.iterator();
        while (it.next()) |entry| {
            const gop = try totals.getOrPut(entry.key_ptr.*);
            if (gop.found_existing) {
                gop.value_ptr.files += entry.value_ptr.files;
                gop.value_ptr.lines += entry.value_ptr.lines;
                gop.value_ptr.code += entry.value_ptr.code;
                gop.value_ptr.comments += entry.value_ptr.comments;
                gop.value_ptr.blanks += entry.value_ptr.blanks;
            } else {
                gop.value_ptr.* = entry.value_ptr.*;
            }
        }
    }

    const show_fields = fields: {
        if (parsed_args.fields.len == 0) break :fields &all_fields;

        const has_language = for (parsed_args.fields) |f| {
            if (f == .language) break true;
        } else false;
        if (has_language) break :fields parsed_args.fields;

        var list = try std.ArrayList(Field).initCapacity(arena, parsed_args.fields.len + 1);
        list.appendAssumeCapacity(.language);
        for (parsed_args.fields) |f| list.appendAssumeCapacity(f);
        break :fields try list.toOwnedSlice(arena);
    };
    try printResults(io, totals, parsed_args.sort_by,
        @as(u64, @intCast(t1 - t0)), @as(u64, @intCast(t2 - t1)), show_fields);
}

fn parseArgs(arena: std.mem.Allocator, args: []const []const u8) !Args {
    var result: Args = .{};

    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            result.help = true;
        } else if (std.mem.eql(u8, arg, "--version") or std.mem.eql(u8, arg, "-v")) {
            result.version = true;
        } else if (std.mem.eql(u8, arg, "--sort")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            result.sort_by = try parseSortBy(args[i]);
        } else if (std.mem.eql(u8, arg, "--jobs") or std.mem.eql(u8, arg, "-j")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            result.jobs = std.fmt.parseInt(usize, args[i], 10) catch return error.InvalidJobCount;
        } else if (std.mem.eql(u8, arg, "--fields")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            result.fields = try parseFields(arena, args[i]);
        } else if (std.mem.startsWith(u8, arg, "-")) {
            return error.UnknownFlag;
        } else {
            result.path = arg;
        }
    }
    return result;
}

test "parseArgs default path" {
    const args = &[_][]const u8{"zline"};
    const parsed = try parseArgs(std.testing.allocator, args);
    try std.testing.expectEqualStrings(".", parsed.path);
    try std.testing.expect(!parsed.help);
    try std.testing.expect(!parsed.version);
}

test "parseArgs custom path" {
    const args = &[_][]const u8{"zline", "src"};
    const parsed = try parseArgs(std.testing.allocator, args);
    try std.testing.expectEqualStrings("src", parsed.path);
}

test "parseArgs help flag" {
    const args = &[_][]const u8{"zline", "--help"};
    const parsed = try parseArgs(std.testing.allocator, args);
    try std.testing.expect(parsed.help);
}

test "parseArgs jobs and sort" {
    const args = &[_][]const u8{"zline", "-j", "4", "--sort", "code", "/tmp"};
    const parsed = try parseArgs(std.testing.allocator, args);
    try std.testing.expectEqual(@as(?usize, 4), parsed.jobs);
    try std.testing.expectEqual(SortBy.code, parsed.sort_by);
    try std.testing.expectEqualStrings("/tmp", parsed.path);
}

test "parseArgs unknown flag" {
    const args = &[_][]const u8{"zline", "--bad-flag"};
    const result = parseArgs(std.testing.allocator, args);
    try std.testing.expectError(error.UnknownFlag, result);
}
