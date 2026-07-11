const std = @import("std");
const builtin = @import("builtin");
const Io = std.Io;
const zline = @import("zline");
const cli = @import("cli.zig");
const table = @import("table.zig");

const FileEntry = zline.walker.FileEntry;

const ChunkResult = struct {
    counts: zline.walker.CountsByLang,
    arena: std.heap.ArenaAllocator,
};

fn countChunk(entries: []const FileEntry, io: Io, thread_idx: usize, thread_counts: []std.atomic.Value(usize), gpa: std.mem.Allocator) ChunkResult {
    var arena = std.heap.ArenaAllocator.init(gpa);
    const allocator = arena.allocator();
    var counts = zline.walker.CountsByLang.init(allocator);
    for (entries) |fe| {
        const fc = zline.counter.countFile(allocator, io, fe.path, fe.lang) catch |err| {
            var buf2: [256]u8 = undefined;
            var ew = Io.File.writer(Io.File.stderr(), io, &buf2);
            ew.interface.print("warning: {s}: {s}\n", .{ fe.path, @errorName(err) }) catch {};
            ew.flush() catch {};
            _ = thread_counts[thread_idx].fetchAdd(1, .monotonic);
            continue;
        };
        const gop = counts.getOrPut(fe.lang.name) catch {
            var buf2: [256]u8 = undefined;
            var ew = Io.File.writer(Io.File.stderr(), io, &buf2);
            ew.interface.print("warning: out of memory for {s}\n", .{fe.lang.name}) catch {};
            ew.flush() catch {};
            _ = thread_counts[thread_idx].fetchAdd(1, .monotonic);
            continue;
        };
        if (gop.found_existing) {
            gop.value_ptr.files += fc.files;
            gop.value_ptr.lines += fc.lines;
            gop.value_ptr.code += fc.code;
            gop.value_ptr.comments += fc.comments;
            gop.value_ptr.blanks += fc.blanks;
        } else {
            gop.value_ptr.* = fc;
        }
        _ = thread_counts[thread_idx].fetchAdd(1, .monotonic);
    }
    return .{ .counts = counts, .arena = arena };
}

const ThreadArg = struct {
    entries: []const FileEntry,
    out: *ChunkResult,
    io: Io,
    thread_idx: usize,
    thread_counts: []std.atomic.Value(usize),
    gpa: std.mem.Allocator,
};

fn reportProgress(io: Io, total: usize, finished: *std.atomic.Value(bool), thread_counts: []std.atomic.Value(usize)) void {
    var buf: [256]u8 = undefined;
    var writer = Io.File.writer(Io.File.stderr(), io, &buf);
    const w = &writer.interface;

    while (!finished.load(.acquire)) {
        var done: usize = 0;
        for (thread_counts) |*tc| {
            done += tc.load(.acquire);
        }
        const pct = if (total > 0) done * 100 / total else 0;
        w.print("\rCounting files... [{d}/{d}] {d}%", .{ done, total, pct }) catch {};
        w.flush() catch {};
        Io.sleep(io, Io.Duration.fromMilliseconds(50), .awake) catch break;
    }

    var done: usize = 0;
    for (thread_counts) |*tc| {
        done += tc.load(.acquire);
    }
    w.print("\rCounting files... [{d}/{d}] 100%\n", .{ done, total }) catch {};
    w.flush() catch {};
}

fn isArchive(path: []const u8) bool {
    if (std.mem.endsWith(u8, path, ".tar")) return true;
    if (std.mem.endsWith(u8, path, ".tar.gz")) return true;
    if (std.mem.endsWith(u8, path, ".tar.bz2")) return true;
    if (std.mem.endsWith(u8, path, ".tar.xz")) return true;
    if (std.mem.endsWith(u8, path, ".tgz")) return true;
    if (std.mem.endsWith(u8, path, ".tbz2")) return true;
    if (std.mem.endsWith(u8, path, ".txz")) return true;
    if (std.mem.endsWith(u8, path, ".zip")) return true;
    if (std.mem.endsWith(u8, path, ".whl")) return true;
    if (std.mem.endsWith(u8, path, ".deb")) return true;
    return false;
}

fn extractArchive(arena: std.mem.Allocator, io: Io, path: []const u8) ![]const u8 {
    const ts = Io.Timestamp.now(io, .awake).nanoseconds;
    var rng = std.Random.DefaultPrng.init(@intCast(ts));
    var tmp_buf: [64]u8 = undefined;
    const tmp_name = try std.fmt.bufPrint(&tmp_buf, "zline-{x}", .{rng.random().int(u32)});
    const tmp_dir = try std.fs.path.join(arena, &.{ "/tmp", tmp_name });
    try Io.Dir.createDirPath(Io.Dir.cwd(), io, tmp_dir);

    if (std.mem.endsWith(u8, path, ".zip") or std.mem.endsWith(u8, path, ".whl")) {
        _ = try std.process.run(arena, io, .{ .argv = &.{ "unzip", "-q", "-o", path, "-d", tmp_dir } });
    } else if (std.mem.endsWith(u8, path, ".deb")) {
        _ = try std.process.run(arena, io, .{ .argv = &.{ "dpkg-deb", "-x", path, tmp_dir } });
    } else {
        _ = try std.process.run(arena, io, .{ .argv = &.{ "tar", "-xf", path, "-C", tmp_dir } });
    }

    return tmp_dir;
}

fn cleanupDir(io: Io, path: []const u8) void {
    Io.Dir.deleteTree(Io.Dir.cwd(), io, path) catch {};
}

pub fn main(init: std.process.Init) !void {
    if (builtin.mode == .Debug) {
        var debug: std.heap.DebugAllocator(.{ .thread_safe = true }) = .init;
        const gpa = debug.allocator();
        defer {
            const check = debug.deinit();
            if (check == .leak) @panic("memory leak detected");
        }
        std.debug.print("debug: leak detection enabled\n", .{});
        try run(init, gpa);
    } else {
        try run(init, std.heap.page_allocator);
    }
}

fn run(init: std.process.Init, gpa: std.mem.Allocator) !void {
    var main_arena = std.heap.ArenaAllocator.init(gpa);
    defer main_arena.deinit();
    const arena = main_arena.allocator();

    const io = init.io;
    const args = try init.minimal.args.toSlice(arena);

    const parsed_args = cli.parseArgs(arena, args) catch |err| {
        std.debug.print("error: {s}\n\n", .{@errorName(err)});
        cli.printHelp(io);
        return;
    };

    if (parsed_args.help) {
        cli.printHelp(io);
        return;
    }
    if (parsed_args.version) {
        cli.printVersion(io);
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

    var scan_path = parsed_args.path;
    var cleanup_path: ?[]const u8 = null;
    defer if (cleanup_path) |cp| cleanupDir(io, cp);
    if (isArchive(parsed_args.path)) {
        scan_path = extractArchive(arena, io, parsed_args.path) catch |err| {
            var ebuf: [256]u8 = undefined;
            var ew = Io.File.writer(Io.File.stderr(), io, &ebuf);
            ew.interface.print("error: cannot extract {s}: {s}\n", .{ parsed_args.path, @errorName(err) }) catch {};
            ew.flush() catch {};
            return;
        };
        cleanup_path = scan_path;
    }

    const entries = zline.walker.collectFiles(arena, io, scan_path, parsed_args.hidden) catch |err| {
        var ebuf: [256]u8 = undefined;
        var ew = Io.File.writer(Io.File.stderr(), io, &ebuf);
        ew.interface.print("error: {s}: {s}\n", .{ scan_path, @errorName(err) }) catch {};
        ew.flush() catch {};
        return;
    };
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
    const n_jobs = @max(1, parsed_args.jobs orelse @max(cpu_count, 1));
    const chunk_size = (entries.len + n_jobs - 1) / n_jobs;
    const n_chunks = @min(n_jobs, entries.len);

    const threads = try arena.alloc(std.Thread, n_chunks - 1);
    const results = try arena.alloc(ChunkResult, n_chunks);
    const thread_counts = try arena.alloc(std.atomic.Value(usize), n_chunks);
    for (thread_counts) |*tc| {
        tc.* = std.atomic.Value(usize).init(0);
    }

    var finished: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);

    const reporter = try std.Thread.spawn(.{}, reportProgress, .{ io, entries.len, &finished, thread_counts });

    const Run = struct { fn f(arg: *ThreadArg) void { arg.out.* = countChunk(arg.entries, arg.io, arg.thread_idx, arg.thread_counts, arg.gpa); } };

    var i: usize = 0;
    var chunk_i: usize = 0;
    var threads_spawned: usize = 0;
    while (i < entries.len and chunk_i < n_chunks) : (chunk_i += 1) {
        const end = @min(i + chunk_size, entries.len);

        if (chunk_i == n_chunks - 1) {
            results[chunk_i] = countChunk(entries[i..end], io, chunk_i, thread_counts, gpa);
        } else {
            const ta = try arena.create(ThreadArg);
            ta.* = .{ .entries = entries[i..end], .out = &results[chunk_i], .io = io, .thread_idx = chunk_i, .thread_counts = thread_counts, .gpa = gpa };
            threads[threads_spawned] = try std.Thread.spawn(.{}, Run.f, .{ta});
            threads_spawned += 1;
        }
        i = end;
    }

    for (threads[0..threads_spawned]) |t| {
        t.join();
    }

    finished.store(true, .release);
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

    for (results[0..chunk_i]) |*cr| {
        cr.arena.deinit();
    }

    const show_fields = fields: {
        if (parsed_args.fields.len == 0) break :fields &cli.all_fields;

        const has_language = for (parsed_args.fields) |f| {
            if (f == .language) break true;
        } else false;
        if (has_language) break :fields parsed_args.fields;

        const result = try arena.alloc(cli.Field, parsed_args.fields.len + 1);
        result[0] = .language;
        @memcpy(result[1..][0..parsed_args.fields.len], parsed_args.fields);
        break :fields result;
    };
    try table.printResults(io, totals, parsed_args.sort_by,
        @as(u64, @intCast(t1 - t0)), @as(u64, @intCast(t2 - t1)), show_fields, gpa);
}

test "isArchive detects archive extensions" {
    try std.testing.expect(isArchive("foo.zip"));
    try std.testing.expect(isArchive("foo.tar"));
    try std.testing.expect(isArchive("foo.tar.gz"));
    try std.testing.expect(isArchive("foo.tar.bz2"));
    try std.testing.expect(isArchive("foo.tar.xz"));
    try std.testing.expect(isArchive("foo.tgz"));
    try std.testing.expect(isArchive("foo.tbz2"));
    try std.testing.expect(isArchive("foo.txz"));
    try std.testing.expect(isArchive("foo.whl"));
    try std.testing.expect(isArchive("foo.deb"));
}

test "isArchive rejects non-archive" {
    try std.testing.expect(!isArchive("foo.zig"));
    try std.testing.expect(!isArchive("foo.tar.gz2"));
    try std.testing.expect(!isArchive("foo.txt"));
    try std.testing.expect(!isArchive("src/"));
    try std.testing.expect(!isArchive(""));
}
