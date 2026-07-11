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
    const trimmed = if (contents[contents.len - 1] == '\n')
        contents[0 .. contents.len - 1]
    else
        contents;
    var lines = std.mem.splitScalar(u8, trimmed, '\n');
    while (lines.next()) |raw_line| {
        result.lines += 1;

        const first_nw = std.mem.indexOfNone(u8, raw_line, " \t\r") orelse raw_line.len;
        if (first_nw == raw_line.len) {
            result.blanks += 1;
            continue;
        }
        const line = raw_line[first_nw..];

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
                    if (idx == 0) {
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
            if (std.mem.indexOf(u8, line, lc)) |idx| {
                if (idx == 0) {
                    result.comments += 1;
                    continue;
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
    var stack_buf: [16384]u8 = undefined;
    const on_heap = size > stack_buf.len;
    const contents: []u8 = if (on_heap)
        try allocator.alloc(u8, size)
    else
        stack_buf[0..size];
    defer if (on_heap) allocator.free(contents);

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

test "countLines matlab percent comment" {
    const lang = langs.Language{ .name = "MATLAB", .extensions = &.{}, .line_comment = "%" };
    const source =
        \\x = 1
        \\% comment
        \\y = 2
    ;
    const result = countLines(source, &lang);
    try std.testing.expectEqual(@as(u64, 3), result.lines);
    try std.testing.expectEqual(@as(u64, 2), result.code);
    try std.testing.expectEqual(@as(u64, 1), result.comments);
}

test "countLines lua dash dash comment" {
    const lang = langs.Language{ .name = "Lua", .extensions = &.{}, .line_comment = "--" };
    const source =
        \\local x = 1
        \\-- comment
        \\print(x)
    ;
    const result = countLines(source, &lang);
    try std.testing.expectEqual(@as(u64, 3), result.lines);
    try std.testing.expectEqual(@as(u64, 2), result.code);
    try std.testing.expectEqual(@as(u64, 1), result.comments);
}

test "countLines fortran bang comment" {
    const lang = langs.Language{ .name = "Fortran", .extensions = &.{}, .line_comment = "!" };
    const source =
        \\program test
        \\! comment
        \\end program
    ;
    const result = countLines(source, &lang);
    try std.testing.expectEqual(@as(u64, 3), result.lines);
    try std.testing.expectEqual(@as(u64, 2), result.code);
    try std.testing.expectEqual(@as(u64, 1), result.comments);
}

test "countLines cobol asterisk comment" {
    const lang = langs.Language{ .name = "COBOL", .extensions = &.{}, .line_comment = "*" };
    const source =
        \\DISPLAY "hello"
        \\* comment
        \\STOP RUN
    ;
    const result = countLines(source, &lang);
    try std.testing.expectEqual(@as(u64, 3), result.lines);
    try std.testing.expectEqual(@as(u64, 2), result.code);
    try std.testing.expectEqual(@as(u64, 1), result.comments);
}

test "countLines vb tick comment" {
    const lang = langs.Language{ .name = "Visual Basic", .extensions = &.{}, .line_comment = "'" };
    const source =
        \\Dim x As Integer
        \\' comment
        \\x = 1
    ;
    const result = countLines(source, &lang);
    try std.testing.expectEqual(@as(u64, 3), result.lines);
    try std.testing.expectEqual(@as(u64, 2), result.code);
    try std.testing.expectEqual(@as(u64, 1), result.comments);
}

test "countLines batch colon comment" {
    const lang = langs.Language{ .name = "Batch", .extensions = &.{}, .line_comment = "::" };
    const source =
        \\echo hello
        \\:: comment
        \\echo world
    ;
    const result = countLines(source, &lang);
    try std.testing.expectEqual(@as(u64, 3), result.lines);
    try std.testing.expectEqual(@as(u64, 2), result.code);
    try std.testing.expectEqual(@as(u64, 1), result.comments);
}

test "countLines semicolon comment" {
    const lang = langs.Language{ .name = "Assembly", .extensions = &.{}, .line_comment = ";" };
    const source =
        \\mov eax, 1
        \\; comment
        \\ret
    ;
    const result = countLines(source, &lang);
    try std.testing.expectEqual(@as(u64, 3), result.lines);
    try std.testing.expectEqual(@as(u64, 2), result.code);
    try std.testing.expectEqual(@as(u64, 1), result.comments);
}

test "countLines lua block comment" {
    const lang = langs.Language{
        .name = "Lua",
        .extensions = &.{},
        .line_comment = "--",
        .block_comment_open = "--[[",
        .block_comment_close = "]]",
    };
    const source =
        \\--[[
        \\block comment
        \\]]
        \\print("hello")
    ;
    const result = countLines(source, &lang);
    try std.testing.expectEqual(@as(u64, 4), result.lines);
    try std.testing.expectEqual(@as(u64, 1), result.code);
    try std.testing.expectEqual(@as(u64, 3), result.comments);
}

test "countLines pascal block comment" {
    const lang = langs.Language{
        .name = "Pascal",
        .extensions = &.{},
        .block_comment_open = "(*",
        .block_comment_close = "*)",
    };
    const source =
        \\procedure Foo;
        \\(* block comment *)
        \\begin
        \\end
    ;
    const result = countLines(source, &lang);
    try std.testing.expectEqual(@as(u64, 4), result.lines);
    try std.testing.expectEqual(@as(u64, 3), result.code);
    try std.testing.expectEqual(@as(u64, 1), result.comments);
}

test "countLines ada dash dash comment" {
    const lang = langs.Language{ .name = "Ada", .extensions = &.{}, .line_comment = "--" };
    const source =
        \\procedure Foo is
        \\-- comment
        \\begin null; end
    ;
    const result = countLines(source, &lang);
    try std.testing.expectEqual(@as(u64, 3), result.lines);
    try std.testing.expectEqual(@as(u64, 2), result.code);
    try std.testing.expectEqual(@as(u64, 1), result.comments);
}

test "countLines terraform hash and block" {
    const lang = langs.Language{
        .name = "Terraform",
        .extensions = &.{},
        .line_comment = "#",
        .block_comment_open = "/*",
        .block_comment_close = "*/",
    };
    const source =
        \\resource "x" "y" {
        \\  # line comment
        \\  /* block comment */
        \\  name = "test"
        \\}
    ;
    const result = countLines(source, &lang);
    try std.testing.expectEqual(@as(u64, 5), result.lines);
    try std.testing.expectEqual(@as(u64, 3), result.code);
    try std.testing.expectEqual(@as(u64, 2), result.comments);
}