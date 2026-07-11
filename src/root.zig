pub const langs = @import("langs.zig");
pub const counter = @import("counter.zig");
pub const walker = @import("walker.zig");
pub const table = @import("table.zig");
pub const cli = @import("cli.zig");

test "root re-exports compile" {
    _ = langs.languages;
    _ = counter.countLines;
    _ = walker.collectFiles;
    _ = table.digitCount;
    _ = cli.parseArgs;
}
