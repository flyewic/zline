const std = @import("std");
const Io = std.Io;
const zline = @import("zline");
const cli = @import("cli.zig");

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
    return std.math.log10_int(n) + 1;
}

fn formatDuration(w: anytype, ns: u64) !void {
    if (ns >= 1_000_000_000) {
        const s = ns / 1_000_000_000;
        const cs = (ns % 1_000_000_000) / 10_000_000;
        try w.print("{d}.{d:0>2}s", .{ s, cs });
    } else if (ns >= 1_000_000) {
        const ms = ns / 1_000_000;
        try w.print("{d}ms", .{ms});
    } else {
        const us = ns / 1_000;
        try w.print("{d}µs", .{us});
    }
}

const RowValues = struct {
    label: []const u8,
    files: u64,
    lines: u64,
    code: u64,
    comments: u64,
    blanks: u64,
};

fn writeHeaderRow(w: anytype, fields: []const cli.Field, widths: []const usize, headers: []const []const u8, gap: usize) !void {
    try w.writeByte(' ');
    for (fields, 0..) |f, fi| {
        if (fi > 0) try writeSpaces(w, gap);
        try writeCellRJust(w, headers[@intFromEnum(f)], widths[@intFromEnum(f)]);
    }
    try w.writeByte('\n');
}

fn writeResultRow(w: anytype, fields: []const cli.Field, widths: []const usize, gap: usize, row: RowValues) !void {
    try w.writeByte(' ');
    for (fields, 0..) |f, fi| {
        if (fi > 0) try writeSpaces(w, gap);
        switch (f) {
            .language => try writeCellRJust(w, row.label, widths[@intFromEnum(f)]),
            .files => try writeCellRJustNum(w, row.files, widths[@intFromEnum(f)]),
            .lines => try writeCellRJustNum(w, row.lines, widths[@intFromEnum(f)]),
            .code => try writeCellRJustNum(w, row.code, widths[@intFromEnum(f)]),
            .comments => try writeCellRJustNum(w, row.comments, widths[@intFromEnum(f)]),
            .blanks => try writeCellRJustNum(w, row.blanks, widths[@intFromEnum(f)]),
        }
    }
    try w.writeByte('\n');
}

pub fn printResults(io: Io, totals: zline.walker.CountsByLang, sort_by: cli.SortBy, scan_ns: u64, count_ns: u64, fields: []const cli.Field, gpa: std.mem.Allocator) !void {
    const entry_count = totals.count();
    if (entry_count == 0) return;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const allocator = arena.allocator();

    var sorted = try std.ArrayList(zline.walker.CountsByLang.Entry).initCapacity(allocator, entry_count);

    var it = totals.iterator();
    while (it.next()) |entry| {
        try sorted.append(allocator, entry);
    }

    const SortContext = struct {
        sort_by: cli.SortBy,
        fn lessThan(self: @This(), a: zline.walker.CountsByLang.Entry, b: zline.walker.CountsByLang.Entry) bool {
            switch (self.sort_by) {
                .name => return std.mem.order(u8, a.value_ptr.language.name, b.value_ptr.language.name) == .lt,
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

    var total_files: u64 = 0;
    var total_lines: u64 = 0;
    var total_code: u64 = 0;
    var total_comments: u64 = 0;
    var total_blanks: u64 = 0;

    for (sorted.items) |entry| {
        const c = entry.value_ptr;
        if (c.language.name.len > lang_width) lang_width = c.language.name.len;
        if (digitCount(c.files) > files_width) files_width = digitCount(c.files);
        if (digitCount(c.lines) > lines_width) lines_width = digitCount(c.lines);
        if (digitCount(c.code) > code_width) code_width = digitCount(c.code);
        if (digitCount(c.comments) > comments_width) comments_width = digitCount(c.comments);
        if (digitCount(c.blanks) > blanks_width) blanks_width = digitCount(c.blanks);

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

    try writeHeaderRow(w, fields, &widths, &headers, gap);

    var sep_chars: usize = 1;
    for (fields, 0..) |f, fi| {
        if (fi > 0) sep_chars += gap;
        sep_chars += widths[@intFromEnum(f)];
    }
    const sep_str = "─";
    const sep_bytes = sep_chars * sep_str.len;
    var sep_buf: [4096]u8 = undefined;
    const draw_bytes = @min(sep_bytes, sep_buf.len);
    var pos: usize = 0;
    while (pos < draw_bytes) : (pos += sep_str.len)
        @memcpy(sep_buf[pos..][0..sep_str.len], sep_str);

    try w.writeAll(sep_buf[0..draw_bytes]);
    try w.writeByte('\n');

    for (sorted.items) |entry| {
        const c = entry.value_ptr;
        try writeResultRow(w, fields, &widths, gap, .{
            .label = c.language.name,
            .files = c.files, .lines = c.lines, .code = c.code,
            .comments = c.comments, .blanks = c.blanks,
        });
    }

    try w.writeAll(sep_buf[0..sep_bytes]);
    try w.writeByte('\n');

    try writeResultRow(w, fields, &widths, gap, .{
        .label = "TOTAL",
        .files = total_files, .lines = total_lines, .code = total_code,
        .comments = total_comments, .blanks = total_blanks,
    });

    try w.print("\n", .{});

    const lang_label = if (entry_count == 1) "language" else "languages";
    const file_label = if (total_files == 1) "file" else "files";
    const line_label = if (total_lines == 1) "line" else "lines";

    try w.print("\nScan: ", .{});
    try formatDuration(w, scan_ns);
    try w.print(" | Count: ", .{});
    try formatDuration(w, count_ns);
    try w.print(" | {d} {s} ({d} {s}, {d} {s})\n", .{
        entry_count, lang_label, total_files, file_label, total_lines, line_label,
    });

    try w.flush();
}
