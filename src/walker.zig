const std = @import("std");
const Io = std.Io;
const langs = @import("langs.zig");
const counter = @import("counter.zig");

pub const CountsByLang = std.AutoHashMap(*const langs.Language, counter.FileCount);

pub const FileEntry = struct {
    path: []const u8,
    lang: *const langs.Language,
};

fn isHidden(name: []const u8) bool {
    return std.mem.startsWith(u8, name, ".") and !std.mem.eql(u8, name, "..") and !std.mem.eql(u8, name, ".");
}

fn readFileHeader(io: Io, dir_path: []const u8, rel_path: []const u8, buf: []u8) ![]u8 {
    var path_buf: [4096]u8 = undefined;
    const full_path = if (dir_path.len > 0 and dir_path[dir_path.len - 1] == '/')
        try std.fmt.bufPrint(&path_buf, "{s}{s}", .{ dir_path, rel_path })
    else
        try std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ dir_path, rel_path });
    const file = try Io.Dir.openFile(Io.Dir.cwd(), io, full_path, .{ .mode = .read_only });
    defer Io.File.close(file, io);
    const n = try Io.File.readPositionalAll(file, io, buf, 0);
    return buf[0..n];
}

pub fn collectFiles(allocator: std.mem.Allocator, io: Io, dir_path: []const u8, include_hidden: bool) ![]FileEntry {
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
            if (!include_hidden and isHidden(std.fs.path.basename(entry.path))) {
                walker.leave(io);
                continue;
            }
        } else if (entry.kind == .file) {
            if (!include_hidden and isHidden(std.fs.path.basename(entry.path))) {
                continue;
            }
            const ext = std.fs.path.extension(entry.path);
            const basename = std.fs.path.basename(entry.path);

            const lang = blk: {
                if (langs.detect(ext, basename, &ext_map)) |info| {
                    switch (info) {
                        .unique => |l| break :blk l,
                        .ambiguous => |amb| {
                            var hdr: [1024]u8 = undefined;
                            const hdr_cont = readFileHeader(io, dir_path, entry.path, &hdr) catch break :blk amb.fallback;
                            break :blk langs.resolve(info, hdr_cont);
                        },
                    }
                }

                var hdr: [1024]u8 = undefined;
                const hdr_cont = readFileHeader(io, dir_path, entry.path, &hdr) catch break :blk null;
                break :blk langs.shebangDetect(hdr_cont);
            };

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
