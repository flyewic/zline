const std = @import("std");
const Io = std.Io;
const langs = @import("langs.zig");

pub const FileCount = struct {
    language: *const langs.Language,
    files: u64 = 0,
    lines: u64 = 0,
    code: u64 = 0,
    comments: u64 = 0,
    blanks: u64 = 0,
};

pub fn countLines(contents: []const u8, lang: *const langs.Language) FileCount {
    var result = FileCount{
        .language = lang,
        .files = 1,
    };

    if (contents.len == 0) {
        return result;
    }

    var in_block_comment = false;
    const trimmed = if (contents.len > 0 and contents[contents.len - 1] == '\n')
        contents[0 .. contents.len - 1]
    else
        contents;
    var lines = std.mem.splitScalar(u8, trimmed, '\n');
    while (lines.next()) |raw_line| {
        result.lines += 1;
        const line = std.mem.trim(u8, raw_line, " \t\r");

        if (line.len == 0) {
            result.blanks += 1;
            continue;
        }

        if (in_block_comment) {
            result.comments += 1;
            if (lang.block_comment_close) |close| {
                if (std.mem.indexOf(u8, line, close)) |_| {
                    in_block_comment = false;
                }
            }
            continue;
        }

        if (lang.block_comment_open) |open| {
            if (lang.block_comment_close) |close| {
                if (std.mem.indexOf(u8, line, open)) |idx| {
                    const before = std.mem.trim(u8, line[0..idx], " \t");
                    if (before.len == 0) {
                        result.comments += 1;
                        if (std.mem.indexOf(u8, line, close) == null) {
                            in_block_comment = true;
                        }
                        continue;
                    }
                }
            }
        }

        if (lang.line_comment) |lc| {
            if (lc.len > 0) {
                if (std.mem.indexOf(u8, line, lc)) |idx| {
                    const before = std.mem.trim(u8, line[0..idx], " \t");
                    if (before.len == 0) {
                        result.comments += 1;
                        continue;
                    }
                }
            }
        }

        result.code += 1;
    }

    return result;
}

pub fn countFile(allocator: std.mem.Allocator, io: Io, path: []const u8, lang: *const langs.Language) !FileCount {
    const file = try Io.Dir.openFile(Io.Dir.cwd(), io, path, .{ .mode = .read_only });
    defer Io.File.close(file, io);

    const stat = try Io.File.stat(file, io);
    if (stat.size == 0) {
        return .{ .language = lang, .files = 1 };
    }

    const size = std.math.cast(usize, stat.size) orelse return error.FileTooLarge;
    const contents = try allocator.alloc(u8, size);
    defer allocator.free(contents);

    const bytes_read = try Io.File.readPositionalAll(file, io, contents, 0);
    return countLines(contents[0..bytes_read], lang);
}

test "countLines empty file" {
    const lang = &langs.languages[0]; // Zig
    const result = countLines("", lang);
    try std.testing.expectEqual(@as(u64, 1), result.files);
    try std.testing.expectEqual(@as(u64, 0), result.lines);
    try std.testing.expectEqual(@as(u64, 0), result.code);
    try std.testing.expectEqual(@as(u64, 0), result.comments);
    try std.testing.expectEqual(@as(u64, 0), result.blanks);
}

test "countLines zig basic" {
    const lang = &langs.languages[0]; // Zig
    const source =
        \\const std = @import("std");
        \\
        \\// This is a comment
        \\pub fn main() void {
        \\    std.debug.print("hello");
        \\}
        \\
    ;
    const result = countLines(source, lang);
    try std.testing.expectEqual(@as(u64, 6), result.lines);
    try std.testing.expectEqual(@as(u64, 4), result.code);
    try std.testing.expectEqual(@as(u64, 1), result.comments);
    try std.testing.expectEqual(@as(u64, 1), result.blanks);
}

test "countLines zig code with inline comment" {
    const lang = &langs.languages[0]; // Zig
    const source = "const x = 5; // inline comment\n";
    const result = countLines(source, lang);
    try std.testing.expectEqual(@as(u64, 1), result.lines);
    try std.testing.expectEqual(@as(u64, 1), result.code);
    try std.testing.expectEqual(@as(u64, 0), result.comments);
    try std.testing.expectEqual(@as(u64, 0), result.blanks);
}

test "countLines block comments" {
    const lang = &langs.languages[1]; // C
    const source =
        \\int x = 0;
        \\/* block comment
        \\   continues here */
        \\int y = 1;
        \\int z = 2; /* inline block */
    ;
    const result = countLines(source, lang);
    try std.testing.expectEqual(@as(u64, 5), result.lines);
    try std.testing.expectEqual(@as(u64, 3), result.code);
    try std.testing.expectEqual(@as(u64, 2), result.comments);
    try std.testing.expectEqual(@as(u64, 0), result.blanks);
}

test "countLines code before block comment" {
    const lang = &langs.languages[1]; // C
    const source = "int x = 0; /* comment */\n";
    const result = countLines(source, lang);
    try std.testing.expectEqual(@as(u64, 1), result.lines);
    try std.testing.expectEqual(@as(u64, 1), result.code);
    try std.testing.expectEqual(@as(u64, 0), result.comments);
}

test "countLines string containing comment marker" {
    const lang = langs.Language{ .name = "Zig", .extensions = &.{}, .line_comment = "//" };
    const source = "const s = \"// not a comment\";\n";
    const result = countLines(source, &lang);
    try std.testing.expectEqual(@as(u64, 1), result.code);
    try std.testing.expectEqual(@as(u64, 0), result.comments);
}

test "countLines python comment" {
    const lang = langs.Language{ .name = "Python", .extensions = &.{}, .line_comment = "#" };
    const source =
        \\def hello():
        \\    # comment
        \\    pass
    ;
    const result = countLines(source, &lang);
    try std.testing.expectEqual(@as(u64, 3), result.lines);
    try std.testing.expectEqual(@as(u64, 2), result.code);
    try std.testing.expectEqual(@as(u64, 1), result.comments);
}

test "countLines html comments" {
    const lang = langs.Language{
        .name = "HTML",
        .extensions = &.{},
        .line_comment = null,
        .block_comment_open = "<!--",
        .block_comment_close = "-->",
    };
    const source =
        \\<div>
        \\<!-- comment -->
        \\</div>
    ;
    const result = countLines(source, &lang);
    try std.testing.expectEqual(@as(u64, 3), result.lines);
    try std.testing.expectEqual(@as(u64, 2), result.code);
    try std.testing.expectEqual(@as(u64, 1), result.comments);
}