const std = @import("std");
const Io = std.Io;

/// Output format for the results table.
pub const OutputFormat = enum {
    table,
    json,
    csv,
};

/// Parsed command-line arguments with sensible defaults.
pub const Args = struct {
    /// Directory path to scan. Defaults to current directory.
    path: []const u8 = ".",
    help: bool = false,
    version: bool = false,
    /// Sort output column. Defaults to alphabetical by language name.
    sort_by: SortBy = .name,
    /// Number of parallel worker threads. null means use CPU count.
    jobs: ?usize = null,
    /// Which columns to display. Empty means all columns.
    fields: []const Field = &.{},
    /// Whether to include hidden files and directories.
    hidden: bool = false,
    output_format: OutputFormat = .table,
    /// Comma-separated language names to filter by, case-insensitive.
    languages: []const u8 = "",
};

/// Sort key for the output table.
pub const SortBy = enum {
    name,
    files,
    lines,
    code,
    comments,
    blanks,
};

/// A displayable column in the output table.
pub const Field = enum {
    language,
    files,
    lines,
    code,
    comments,
    blanks,
};

/// All displayable fields in their default order.
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
    var fields: [6]Field = undefined;
    var count: usize = 0;
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
        for (fields[0..count]) |existing| {
            if (existing == field) dup = true;
        }
        if (!dup) {
            if (count >= fields.len) return error.TooManyFields;
            fields[count] = field;
            count += 1;
        }
    }
    const result = try allocator.alloc(Field, count);
    @memcpy(result, fields[0..count]);
    return result;
}

fn parseOutputFormat(s: []const u8) !OutputFormat {
    if (std.mem.eql(u8, s, "table")) return .table;
    if (std.mem.eql(u8, s, "json")) return .json;
    if (std.mem.eql(u8, s, "csv")) return .csv;
    return error.InvalidOutputFormat;
}

/// Parses CLI arguments. The arena is used for any heap allocations
/// (such as the --fields list) and owns the memory until freed.
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
        } else if (std.mem.eql(u8, arg, "--output") or std.mem.eql(u8, arg, "-o")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            result.output_format = try parseOutputFormat(args[i]);
        } else if (std.mem.eql(u8, arg, "--languages") or std.mem.eql(u8, arg, "-l")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            result.languages = args[i];
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
        \\  PATH                     Directory to scan (default: current directory)
        \\
        \\Options:
        \\  -h, --help               Show this help message
        \\  -v, --version            Show version information
        \\  -j, --jobs N             Number of parallel jobs (default: CPU count)
        \\  --sort FIELD             Sort output by: name, files, lines, code, comments, blanks (default: name)
        \\  --fields FIELDS          Comma-separated columns to show: language, files, lines, code, comments, blanks
        \\  --hidden                 Include hidden files and directories
        \\  -o, --output FORMAT      Output format: table, json, csv (default: table)
        \\  -l, --languages LANGS    Comma-separated language names to filter by (e.g. "Zig,Rust,Go")
    , .{}) catch {};
    w.print("\n", .{}) catch {};
    w.flush() catch {};
}

pub const version = "0.4.0";

pub fn printVersion(io: Io) void {
    var buf: [64]u8 = undefined;
    var writer = Io.File.writer(Io.File.stdout(), io, &buf);
    const w = &writer.interface;
    w.print("zline {s}\n", .{version}) catch {};
    w.flush() catch {};
}

test "parseArgs default path" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const args = &[_][]const u8{"zline"};
    const parsed = try parseArgs(arena.allocator(), args);
    try std.testing.expectEqualStrings(".", parsed.path);
    try std.testing.expect(!parsed.help);
    try std.testing.expect(!parsed.version);
    try std.testing.expectEqual(OutputFormat.table, parsed.output_format);
    try std.testing.expectEqualStrings("", parsed.languages);
}

test "parseArgs custom path" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const args = &[_][]const u8{"zline", "src"};
    const parsed = try parseArgs(arena.allocator(), args);
    try std.testing.expectEqualStrings("src", parsed.path);
}

test "parseArgs help flag" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const args = &[_][]const u8{"zline", "--help"};
    const parsed = try parseArgs(arena.allocator(), args);
    try std.testing.expect(parsed.help);
}

test "parseArgs jobs and sort" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const args = &[_][]const u8{"zline", "-j", "4", "--sort", "code", "/tmp"};
    const parsed = try parseArgs(arena.allocator(), args);
    try std.testing.expectEqual(@as(?usize, 4), parsed.jobs);
    try std.testing.expectEqual(SortBy.code, parsed.sort_by);
    try std.testing.expectEqualStrings("/tmp", parsed.path);
}

test "parseArgs unknown flag" {
    const args = &[_][]const u8{"zline", "--bad-flag"};
    try std.testing.expectError(error.UnknownFlag, parseArgs(std.testing.allocator, args));
}

test "parseArgs hidden flag" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const args = &[_][]const u8{"zline", "--hidden"};
    const parsed = try parseArgs(arena.allocator(), args);
    try std.testing.expect(parsed.hidden);
}

test "parseArgs version flag" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const args = &[_][]const u8{"zline", "--version"};
    const parsed = try parseArgs(arena.allocator(), args);
    try std.testing.expect(parsed.version);
}

test "parseArgs v shortcut" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const args = &[_][]const u8{"zline", "-v"};
    const parsed = try parseArgs(arena.allocator(), args);
    try std.testing.expect(parsed.version);
}

test "parseArgs fields" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const args = &[_][]const u8{"zline", "--fields", "language,lines,code"};
    const parsed = try parseArgs(arena.allocator(), args);
    try std.testing.expectEqual(@as(usize, 3), parsed.fields.len);
    try std.testing.expectEqual(Field.language, parsed.fields[0]);
    try std.testing.expectEqual(Field.lines, parsed.fields[1]);
    try std.testing.expectEqual(Field.code, parsed.fields[2]);
}

test "parseArgs fields dedup" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const args = &[_][]const u8{"zline", "--fields", "lines,lines,code"};
    const parsed = try parseArgs(arena.allocator(), args);
    try std.testing.expectEqual(@as(usize, 2), parsed.fields.len);
    try std.testing.expectEqual(Field.lines, parsed.fields[0]);
    try std.testing.expectEqual(Field.code, parsed.fields[1]);
}

test "parseArgs output flag table" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const args = &[_][]const u8{"zline", "--output", "table"};
    const parsed = try parseArgs(arena.allocator(), args);
    try std.testing.expectEqual(OutputFormat.table, parsed.output_format);
}

test "parseArgs output flag json" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const args = &[_][]const u8{"zline", "-o", "json"};
    const parsed = try parseArgs(arena.allocator(), args);
    try std.testing.expectEqual(OutputFormat.json, parsed.output_format);
}

test "parseArgs output flag csv" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const args = &[_][]const u8{"zline", "-o", "csv"};
    const parsed = try parseArgs(arena.allocator(), args);
    try std.testing.expectEqual(OutputFormat.csv, parsed.output_format);
}

test "parseArgs output flag invalid" {
    const args = &[_][]const u8{"zline", "-o", "yaml"};
    try std.testing.expectError(error.InvalidOutputFormat, parseArgs(std.testing.allocator, args));
}

test "parseArgs output flag missing value" {
    const args = &[_][]const u8{"zline", "-o"};
    try std.testing.expectError(error.MissingArgument, parseArgs(std.testing.allocator, args));
}

test "parseArgs languages flag" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const args = &[_][]const u8{"zline", "-l", "Zig,Rust,Go"};
    const parsed = try parseArgs(arena.allocator(), args);
    try std.testing.expectEqualStrings("Zig,Rust,Go", parsed.languages);
}

test "parseArgs languages flag long" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const args = &[_][]const u8{"zline", "--languages", "Python"};
    const parsed = try parseArgs(arena.allocator(), args);
    try std.testing.expectEqualStrings("Python", parsed.languages);
}

test "parseArgs languages flag missing value" {
    const args = &[_][]const u8{"zline", "-l"};
    try std.testing.expectError(error.MissingArgument, parseArgs(std.testing.allocator, args));
}
