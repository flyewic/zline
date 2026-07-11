const std = @import("std");
const Io = std.Io;
const cli = @import("cli.zig");
const walker = @import("walker.zig");

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

pub fn digitCount(n: u64) usize {
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

pub fn printResults(io: Io, totals: walker.CountsByLang, sort_by: cli.SortBy, scan_ns: u64, count_ns: u64, fields: []const cli.Field, output_format: cli.OutputFormat, gpa: std.mem.Allocator) !void {
    const entry_count = totals.count();
    if (entry_count == 0) return;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const allocator = arena.allocator();

    var sorted = try std.ArrayList(walker.CountsByLang.Entry).initCapacity(allocator, entry_count);

    var it = totals.iterator();
    while (it.next()) |entry| {
        try sorted.append(allocator, entry);
    }

    const SortContext = struct {
        sort_by: cli.SortBy,
        fn lessThan(self: @This(), a: walker.CountsByLang.Entry, b: walker.CountsByLang.Entry) bool {
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
    std.mem.sort(walker.CountsByLang.Entry, sorted.items, ctx, SortContext.lessThan);

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

    switch (output_format) {
        .table => try printTable(io, sorted.items, total_files, total_lines, total_code, total_comments, total_blanks, fields, entry_count, scan_ns, count_ns),
        .json => try printJson(io, sorted.items, total_files, total_lines, total_code, total_comments, total_blanks, fields),
        .csv => try printCsv(io, sorted.items, total_files, total_lines, total_code, total_comments, total_blanks, fields),
    }
}

fn printTable(io: Io, sorted: []walker.CountsByLang.Entry, total_files: u64, total_lines: u64, total_code: u64, total_comments: u64, total_blanks: u64, fields: []const cli.Field, entry_count: usize, scan_ns: u64, count_ns: u64) !void {
    var lang_width: usize = @max(@as(usize, "Language".len), "TOTAL".len);
    var files_width: usize = "Files".len;
    var lines_width: usize = "Lines".len;
    var code_width: usize = "Code".len;
    var comments_width: usize = "Comments".len;
    var blanks_width: usize = "Blanks".len;

    for (sorted) |entry| {
        const c = entry.value_ptr;
        if (c.language.name.len > lang_width) lang_width = c.language.name.len;
        if (digitCount(c.files) > files_width) files_width = digitCount(c.files);
        if (digitCount(c.lines) > lines_width) lines_width = digitCount(c.lines);
        if (digitCount(c.code) > code_width) code_width = digitCount(c.code);
        if (digitCount(c.comments) > comments_width) comments_width = digitCount(c.comments);
        if (digitCount(c.blanks) > blanks_width) blanks_width = digitCount(c.blanks);
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

    for (sorted) |entry| {
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

fn jsonEscape(w: anytype, s: []const u8) !void {
    for (s) |c| {
        switch (c) {
            '"' => try w.writeAll("\\\""),
            '\\' => try w.writeAll("\\\\"),
            '\n' => try w.writeAll("\\n"),
            '\r' => try w.writeAll("\\r"),
            '\t' => try w.writeAll("\\t"),
            else => if (c >= 0x20)
                try w.writeByte(c)
            else
                try w.print("\\u{x:0>4}", .{@as(u32, c)}),
        }
    }
}

fn writeJsonFields(w: anytype, files: u64, lines: u64, code: u64, comments: u64, blanks: u64, fields: []const cli.Field, first: *bool) !void {
    for (fields) |field| {
        switch (field) {
            .language => continue,
            .files => {
                if (!first.*) try w.writeAll(", ");
                try w.print("\"files\": {d}", .{files});
                first.* = false;
            },
            .lines => {
                if (!first.*) try w.writeAll(", ");
                try w.print("\"lines\": {d}", .{lines});
                first.* = false;
            },
            .code => {
                if (!first.*) try w.writeAll(", ");
                try w.print("\"code\": {d}", .{code});
                first.* = false;
            },
            .comments => {
                if (!first.*) try w.writeAll(", ");
                try w.print("\"comments\": {d}", .{comments});
                first.* = false;
            },
            .blanks => {
                if (!first.*) try w.writeAll(", ");
                try w.print("\"blanks\": {d}", .{blanks});
                first.* = false;
            },
        }
    }
}

fn printJsonObject(w: anytype, name: []const u8, files: u64, lines: u64, code: u64, comments: u64, blanks: u64, fields: []const cli.Field) !void {
    try w.print("\"language\": \"", .{});
    try jsonEscape(w, name);
    try w.writeByte('"');
    var first = false;
    try writeJsonFields(w, files, lines, code, comments, blanks, fields, &first);
    try w.writeByte('}');
}

fn printJsonTotal(w: anytype, files: u64, lines: u64, code: u64, comments: u64, blanks: u64, fields: []const cli.Field) !void {
    var first = true;
    try writeJsonFields(w, files, lines, code, comments, blanks, fields, &first);
    try w.writeByte('}');
}

fn printJson(io: Io, sorted: []walker.CountsByLang.Entry, total_files: u64, total_lines: u64, total_code: u64, total_comments: u64, total_blanks: u64, fields: []const cli.Field) !void {
    var buf: [4096]u8 = undefined;
    var writer = Io.File.writer(Io.File.stdout(), io, &buf);
    const w = &writer.interface;

    try w.writeAll("{\n  \"languages\": [\n");

    for (sorted[0 .. sorted.len -| 1]) |entry| {
        const c = entry.value_ptr;
        try w.writeAll("    {");
        try printJsonObject(w, c.language.name, c.files, c.lines, c.code, c.comments, c.blanks, fields);
        try w.writeAll(",\n");
    }
    if (sorted.len > 0) {
        const last = sorted[sorted.len - 1].value_ptr;
        try w.writeAll("    {");
        try printJsonObject(w, last.language.name, last.files, last.lines, last.code, last.comments, last.blanks, fields);
        try w.writeAll("\n");
    }

    try w.writeAll("  ],\n  \"total\": {");
    try printJsonTotal(w, total_files, total_lines, total_code, total_comments, total_blanks, fields);
    try w.writeAll("\n}\n");
    try w.flush();
}

fn printCsv(io: Io, sorted: []walker.CountsByLang.Entry, total_files: u64, total_lines: u64, total_code: u64, total_comments: u64, total_blanks: u64, fields: []const cli.Field) !void {
    var buf: [4096]u8 = undefined;
    var writer = Io.File.writer(Io.File.stdout(), io, &buf);
    const w = &writer.interface;

    var f_j: usize = 0;
    while (f_j < fields.len) : (f_j += 1) {
        if (f_j > 0) try w.writeByte(',');
        switch (fields[f_j]) {
            .language => try w.writeAll("Language"),
            .files => try w.writeAll("Files"),
            .lines => try w.writeAll("Lines"),
            .code => try w.writeAll("Code"),
            .comments => try w.writeAll("Comments"),
            .blanks => try w.writeAll("Blanks"),
        }
    }
    try w.writeByte('\n');

    for (sorted) |entry| {
        const c = entry.value_ptr;
        f_j = 0;
        while (f_j < fields.len) : (f_j += 1) {
            if (f_j > 0) try w.writeByte(',');
            switch (fields[f_j]) {
                .language => try w.writeAll(c.language.name),
                .files => try w.print("{d}", .{c.files}),
                .lines => try w.print("{d}", .{c.lines}),
                .code => try w.print("{d}", .{c.code}),
                .comments => try w.print("{d}", .{c.comments}),
                .blanks => try w.print("{d}", .{c.blanks}),
            }
        }
        try w.writeByte('\n');
    }

    f_j = 0;
    while (f_j < fields.len) : (f_j += 1) {
        if (f_j > 0) try w.writeByte(',');
        switch (fields[f_j]) {
            .language => try w.writeAll("Total"),
            .files => try w.print("{d}", .{total_files}),
            .lines => try w.print("{d}", .{total_lines}),
            .code => try w.print("{d}", .{total_code}),
            .comments => try w.print("{d}", .{total_comments}),
            .blanks => try w.print("{d}", .{total_blanks}),
        }
    }
    try w.writeByte('\n');

    try w.flush();
}

test "digitCount" {
    try std.testing.expectEqual(@as(usize, 1), digitCount(0));
    try std.testing.expectEqual(@as(usize, 1), digitCount(5));
    try std.testing.expectEqual(@as(usize, 2), digitCount(42));
    try std.testing.expectEqual(@as(usize, 3), digitCount(999));
    try std.testing.expectEqual(@as(usize, 10), digitCount(1234567890));
}

test "jsonEscape plain ASCII" {
    var buf: [128]u8 = undefined;
    var w = Io.Writer.fixed(&buf);
    try jsonEscape(&w, "hello");
    try std.testing.expectEqualStrings("hello", w.buffered());
}

test "jsonEscape with quotes" {
    var buf: [128]u8 = undefined;
    var w = Io.Writer.fixed(&buf);
    try jsonEscape(&w, "a\"b");
    try std.testing.expectEqualStrings("a\\\"b", w.buffered());
}

test "jsonEscape with backslash" {
    var buf: [128]u8 = undefined;
    var w = Io.Writer.fixed(&buf);
    try jsonEscape(&w, "a\\b");
    try std.testing.expectEqualStrings("a\\\\b", w.buffered());
}

test "jsonEscape with special chars" {
    var buf: [128]u8 = undefined;
    var w = Io.Writer.fixed(&buf);
    try jsonEscape(&w, "\n\r\t");
    try std.testing.expectEqualStrings("\\n\\r\\t", w.buffered());
}

test "jsonEscape with control char" {
    var buf: [128]u8 = undefined;
    var w = Io.Writer.fixed(&buf);
    try jsonEscape(&w, "\x01");
    try std.testing.expectEqualStrings("\\u0001", w.buffered());
}

test "jsonEscape empty" {
    var buf: [128]u8 = undefined;
    var w = Io.Writer.fixed(&buf);
    try jsonEscape(&w, "");
    try std.testing.expectEqualStrings("", w.buffered());
}

test "printJsonTotal omits language" {
    var buf: [128]u8 = undefined;
    var w = Io.Writer.fixed(&buf);
    try printJsonTotal(&w, 7, 2020, 1787, 0, 234, &cli.all_fields);
    try std.testing.expectEqualStrings("\"files\": 7, \"lines\": 2020, \"code\": 1787, \"comments\": 0, \"blanks\": 234}", w.buffered());
}

test "printJsonTotal language only fields" {
    var buf: [128]u8 = undefined;
    var w = Io.Writer.fixed(&buf);
    const fields = &[_]cli.Field{.language};
    try printJsonTotal(&w, 7, 2020, 1787, 0, 234, fields);
    try std.testing.expectEqualStrings("}", w.buffered());
}

test "printJsonTotal fields code,blanks" {
    var buf: [128]u8 = undefined;
    var w = Io.Writer.fixed(&buf);
    const fields = &[_]cli.Field{ .code, .blanks };
    try printJsonTotal(&w, 7, 2020, 1787, 0, 234, fields);
    try std.testing.expectEqualStrings("\"code\": 1787, \"blanks\": 234}", w.buffered());
}
