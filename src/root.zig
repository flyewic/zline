pub const langs = @import("langs.zig");
pub const counter = @import("counter.zig");
pub const walker = @import("walker.zig");

test "root re-exports compile" {
    _ = langs.languages;
    _ = counter.countLines;
    _ = walker.collectFiles;
}
