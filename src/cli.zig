const std = @import("std");
const Io = std.Io;

pub const Args = struct {
    path: []const u8 = ".",
    help: bool = false,
    version: bool = false,
    sort_by: SortBy = .name,
    jobs: ?usize = null,
    fields: []const Field = &.{},
    hidden: bool = false,
};

pub const SortBy = enum {
    name,
    files,
    lines,
    code,
    comments,
    blanks,
};

pub const Field = enum {
    language,
    files,
    lines,
    code,
    comments,
    blanks,
};

pub const all_fields = [_]Field{ .language, .files, .lines, .code, .comments, .blanks };

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
        const field = if (std.mem.eql(u8, trimmed, "language"))
            Field.language
        else if (std.mem.eql(u8, trimmed, "files"))
            Field.files
        else if (std.mem.eql(u8, trimmed, "lines"))
            Field.lines
        else if (std.mem.eql(u8, trimmed, "code"))
            Field.code
        else if (std.mem.eql(u8, trimmed, "comments"))
            Field.comments
        else if (std.mem.eql(u8, trimmed, "blanks"))
            Field.blanks
        else
            return error.InvalidField;

        var dup = false;
        for (list.items) |existing| {
            if (existing == field) dup = true;
        }
        if (!dup) try list.append(allocator, field);
    }
    return list.toOwnedSlice(allocator);
}

pub fn parseArgs(arena: std.mem.Allocator, args: []const []const u8) !Args {
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
        } else if (std.mem.eql(u8, arg, "--hidden")) {
            result.hidden = true;
        } else if (std.mem.startsWith(u8, arg, "-")) {
            return error.UnknownFlag;
        } else {
            result.path = arg;
        }
    }
    return result;
}

pub fn printHelp(io: Io) void {
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
        \\  --hidden             Include hidden files and directories
    , .{}) catch {};
    w.print("\n", .{}) catch {};
    w.flush() catch {};
}

pub const version = "0.1.0";

pub fn printVersion(io: Io) void {
    var buf: [64]u8 = undefined;
    var writer = Io.File.writer(Io.File.stdout(), io, &buf);
    const w = &writer.interface;
    w.print("zline {s}\n", .{version}) catch {};
    w.flush() catch {};
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
