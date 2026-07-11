const std = @import("std");
const Io = std.Io;
const zline = @import("zline");
const cli = @import("cli.zig");
const table = @import("table.zig");

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
        const fc = zline.counter.countFile(allocator, io, fe.path, fe.lang) catch |err| {
            var buf2: [256]u8 = undefined;
            var ew = Io.File.writer(Io.File.stderr(), io, &buf2);
            ew.interface.print("warning: {s}: {s}\n", .{ fe.path, @errorName(err) }) catch {};
            ew.flush() catch {};
            progress.inc();
            continue;
        };
        const gop = counts.getOrPut(fe.lang.name) catch {
            var buf2: [256]u8 = undefined;
            var ew = Io.File.writer(Io.File.stderr(), io, &buf2);
            ew.interface.print("warning: out of memory for {s}\n", .{fe.lang.name}) catch {};
            ew.flush() catch {};
            progress.inc();
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

fn reportProgress(io: Io, progress: *Progress) void {
    var buf: [256]u8 = undefined;
    var writer = Io.File.writer(Io.File.stderr(), io, &buf);
    const w = &writer.interface;

    while (!progress.finished.load(.acquire)) {
        const done = progress.done.load(.acquire);
        const pct = if (progress.total > 0) done * 100 / progress.total else 0;
        w.print("\rCounting files... [{d}/{d}] {d}%", .{ done, progress.total, pct }) catch {};
        w.flush() catch {};
        Io.sleep(io, Io.Duration.fromMilliseconds(50), .awake) catch break;
    }

    const done = progress.done.load(.acquire);
    w.print("\rCounting files... [{d}/{d}] 100%\n", .{ done, progress.total }) catch {};
    w.flush() catch {};
}

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    const io = init.io;

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

    const entries = zline.walker.collectFiles(arena, io, parsed_args.path) catch |err| {
        var ebuf: [256]u8 = undefined;
        var ew = Io.File.writer(Io.File.stderr(), io, &ebuf);
        ew.interface.print("error: {s}: {s}\n", .{ parsed_args.path, @errorName(err) }) catch {};
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
            threads[threads_spawned] = try std.Thread.spawn(.{}, struct {
                fn run(arg: *ThreadArg) void { arg.out.* = countChunk(arg.entries, arg.io, arg.progress); }
            }.run, .{ta});
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

    for (results[0..chunk_i]) |*cr| {
        cr.arena.deinit();
    }

    const show_fields = fields: {
        if (parsed_args.fields.len == 0) break :fields &cli.all_fields;

        const has_language = for (parsed_args.fields) |f| {
            if (f == .language) break true;
        } else false;
        if (has_language) break :fields parsed_args.fields;

        var list = try std.ArrayList(cli.Field).initCapacity(arena, parsed_args.fields.len + 1);
        list.appendAssumeCapacity(.language);
        for (parsed_args.fields) |f| list.appendAssumeCapacity(f);
        break :fields try list.toOwnedSlice(arena);
    };
    try table.printResults(io, totals, parsed_args.sort_by,
        @as(u64, @intCast(t1 - t0)), @as(u64, @intCast(t2 - t1)), show_fields);
}
