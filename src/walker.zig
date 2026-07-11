const std = @import("std");
const Io = std.Io;
const langs = @import("langs.zig");
const counter = @import("counter.zig");

pub const CountsByLang = std.StringHashMap(counter.FileCount);

pub const FileEntry = struct {
    path: []const u8,
    lang: *const langs.Language,
};

fn isHidden(name: []const u8) bool {
    return std.mem.startsWith(u8, name, ".") and !std.mem.eql(u8, name, "..") and !std.mem.eql(u8, name, ".");
}

pub fn collectFiles(allocator: std.mem.Allocator, io: Io, dir_path: []const u8) ![]FileEntry {
    var entries: std.ArrayList(FileEntry) = .empty;

    var ext_map = try langs.buildExtensionMap(allocator);
    defer ext_map.deinit();

    const cwd = Io.Dir.cwd();
    const dir = try Io.Dir.openDir(cwd, io, dir_path, .{ .iterate = true });
    defer Io.Dir.close(dir, io);

    var walker = try Io.Dir.walk(dir, allocator);
    defer walker.deinit();

    while (true) {
        const maybe_entry = walker.next(io) catch {
            walker.leave(io);
            continue;
        };
        const entry = maybe_entry orelse break;

        if (entry.kind == .directory) {
            if (isHidden(entry.path)) {
                walker.leave(io);
                continue;
            }
        } else if (entry.kind == .file) {
            const ext = std.fs.path.extension(entry.path);
            const basename = std.fs.path.basename(entry.path);

            const lang = langs.detectByExtension(ext, &ext_map) orelse
                langs.detectByExtension(basename, &ext_map);

            if (lang) |l| {
                const full_path = try std.fs.path.join(allocator, &.{ dir_path, entry.path });
                try entries.append(allocator, .{ .path = full_path, .lang = l });
            }
        }
    }

    return try entries.toOwnedSlice(allocator);
}

test "isHidden detects hidden directories" {
    try std.testing.expect(isHidden(".git"));
    try std.testing.expect(isHidden(".vscode"));
    try std.testing.expect(!isHidden("src"));
    try std.testing.expect(!isHidden("."));
    try std.testing.expect(!isHidden(".."));
}