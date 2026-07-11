const std = @import("std");

pub const Language = struct {
    name: []const u8,
    extensions: []const []const u8,
    line_comment: ?[]const u8 = null,
    block_comment_open: ?[]const u8 = null,
    block_comment_close: ?[]const u8 = null,
};

const cStyle = Language{
    .name = "", .extensions = &.{},
    .line_comment = "//",
    .block_comment_open = "/*", .block_comment_close = "*/",
};
const hashStyle = Language{
    .name = "", .extensions = &.{},
    .line_comment = "#",
};
const hashCBlock = Language{
    .name = "", .extensions = &.{},
    .line_comment = "#",
    .block_comment_open = "/*", .block_comment_close = "*/",
};
const doubleDashStyle = Language{
    .name = "", .extensions = &.{},
    .line_comment = "--",
};
const doubleDashCBlock = Language{
    .name = "", .extensions = &.{},
    .line_comment = "--",
    .block_comment_open = "/*", .block_comment_close = "*/",
};
const semicolonStyle = Language{
    .name = "", .extensions = &.{},
    .line_comment = ";",
};
const percentStyle = Language{
    .name = "", .extensions = &.{},
    .line_comment = "%",
};
const htmlStyle = Language{
    .name = "", .extensions = &.{},
    .line_comment = null,
    .block_comment_open = "<!--", .block_comment_close = "-->",
};
const cssStyle = Language{
    .name = "", .extensions = &.{},
    .line_comment = null,
    .block_comment_open = "/*", .block_comment_close = "*/",
};
const haskellStyle = Language{
    .name = "", .extensions = &.{},
    .line_comment = "--",
    .block_comment_open = "{-", .block_comment_close = "-}",
};
const pascalStyle = Language{
    .name = "", .extensions = &.{},
    .line_comment = "//",
    .block_comment_open = "(*", .block_comment_close = "*)",
};
const ocamlStyle = Language{
    .name = "", .extensions = &.{},
    .line_comment = null,
    .block_comment_open = "(*", .block_comment_close = "*)",
};
const noComment = Language{
    .name = "", .extensions = &.{},
    .line_comment = null,
};

fn L(comptime base: Language, comptime name: []const u8, comptime exts: []const []const u8) Language {
    return .{
        .name = name,
        .extensions = exts,
        .line_comment = base.line_comment,
        .block_comment_open = base.block_comment_open,
        .block_comment_close = base.block_comment_close,
    };
}

pub const languages = [_]Language{
    L(cStyle, "Zig", &.{ ".zig", ".zon" }),
    L(cStyle, "C", &.{ ".c", ".h" }),
    L(cStyle, "C++", &.{ ".cpp", ".hpp", ".cc", ".cxx", ".hh", ".hxx" }),
    L(cStyle, "C#", &.{ ".cs" }),
    L(cStyle, "Java", &.{ ".java" }),
    L(cStyle, "JavaScript", &.{ ".js", ".jsx", ".mjs", ".cjs" }),
    L(cStyle, "TypeScript", &.{ ".ts", ".tsx" }),
    L(cStyle, "Go", &.{ ".go" }),
    L(cStyle, "Rust", &.{ ".rs" }),
    L(cStyle, "Swift", &.{ ".swift" }),
    L(cStyle, "Kotlin", &.{ ".kt", ".kts" }),
    L(cStyle, "Dart", &.{ ".dart" }),
    L(cStyle, "Scala", &.{ ".scala", ".sc" }),
    L(cStyle, "PHP", &.{ ".php", ".phtml" }),
    L(cStyle, "SCSS", &.{ ".scss" }),
    L(cStyle, "Less", &.{ ".less" }),
    L(cStyle, "Verilog", &.{ ".v", ".sv" }),
    L(cStyle, "Protocol Buffers", &.{".proto"}),
    L(cStyle, "Thrift", &.{".thrift"}),
    L(cStyle, "Solidity", &.{ ".sol" }),
    L(cStyle, "CUE", &.{ ".cue" }),
    L(cStyle, "Objective-C", &.{ ".m", ".mm" }),
    L(cStyle, "Vala", &.{ ".vala", ".vapi" }),
    L(cStyle, "Groovy", &.{ ".groovy", ".gvy" }),
    L(cStyle, "Reason", &.{ ".re", ".rei" }),
    L(cStyle, "D", &.{ ".d" }),
    L(cStyle, "CUDA", &.{ ".cu", ".cuh" }),
    L(cStyle, "GLSL", &.{ ".glsl", ".vert", ".frag", ".geom", ".comp" }),
    L(cStyle, "HLSL", &.{ ".hlsl", ".fx", ".fxh" }),
    L(cStyle, "Haxe", &.{ ".hx" }),
    L(cStyle, "ActionScript", &.{ ".as" }),
    L(cStyle, "Gradle", &.{ ".gradle" }),
    L(cStyle, "OpenCL", &.{ ".cl" }),
    L(cStyle, "Pony", &.{ ".pony" }),
    L(cStyle, "TTCN-3", &.{ ".ttcn", ".ttcn3" }),
    L(cStyle, "QML", &.{ ".qml" }),
    L(cStyle, "Sass", &.{ ".sass" }),
    L(cStyle, "Metal", &.{ ".metal" }),
    L(cStyle, "Processing", &.{ ".pde" }),

    L(hashStyle, "Python", &.{ ".py", ".pyw", ".pyi" }),
    L(hashStyle, "Ruby", &.{ ".rb", ".rake", ".gemspec" }),
    L(hashStyle, "Perl", &.{ ".pl", ".pm", ".pod" }),
    L(hashStyle, "R", &.{ ".r", ".R" }),
    L(hashStyle, "Elixir", &.{ ".ex", ".exs" }),
    L(hashStyle, "Shell", &.{ ".sh", ".bash", ".zsh", ".fish" }),
    L(hashStyle, "Makefile", &.{ ".make", "Makefile", "makefile", "GNUmakefile" }),
    L(hashStyle, "CMake", &.{ ".cmake", "CMakeLists.txt" }),
    L(hashStyle, "Dockerfile", &.{ "Dockerfile" }),
    L(hashStyle, "YAML", &.{ ".yaml", ".yml" }),
    L(hashStyle, "TOML", &.{ ".toml" }),
    L(hashStyle, "GraphQL", &.{ ".graphql", ".gql" }),
    L(hashStyle, "Vyper", &.{ ".vy" }),
    L(hashStyle, "Nix", &.{ ".nix" }),
    L(hashStyle, "Starlark", &.{ ".bzl", "BUILD", "BUILD.bazel" }),
    L(hashStyle, "RON", &.{ ".ron" }),
    L(hashStyle, "Crystal", &.{ ".cr" }),
    L(hashStyle, "Nim", &.{ ".nim", ".nims" }),
    L(hashStyle, "Tcl", &.{ ".tcl" }),
    L(hashStyle, "Awk", &.{ ".awk" }),
    L(hashStyle, "Raku", &.{ ".raku", ".rakumod" }),
    L(hashStyle, "CoffeeScript", &.{".coffee"}),
    L(hashStyle, "Sage", &.{ ".sage" }),
    L(hashStyle, "Gnuplot", &.{ ".gp", ".gnuplot" }),
    L(hashStyle, "GDScript", &.{ ".gd" }),
    L(hashStyle, "Racket", &.{ ".rkt", ".rktl" }),

    L(hashCBlock, "Terraform", &.{ ".tf", ".tfvars" }),

    L(doubleDashStyle, "Ada", &.{ ".adb", ".ads" }),
    L(doubleDashStyle, "VHDL", &.{ ".vhd", ".vhdl" }),
    L(doubleDashStyle, "Dhall", &.{ ".dhall" }),

    L(doubleDashCBlock, "SQL", &.{ ".sql" }),
    L(doubleDashCBlock, "PL/SQL", &.{ ".pks", ".pkb" }),

    L(semicolonStyle, "Clojure", &.{ ".clj", ".cljs", ".cljc", ".edn" }),
    L(semicolonStyle, "Lisp", &.{ ".lisp", ".lsp" }),
    L(semicolonStyle, "Scheme", &.{ ".scm", ".ss" }),
    L(semicolonStyle, "Assembly", &.{ ".asm", ".s", ".S" }),
    L(semicolonStyle, "INI", &.{ ".ini" }),
    L(semicolonStyle, "Emacs Lisp", &.{ ".el" }),

    L(percentStyle, "Erlang", &.{ ".erl", ".hrl" }),
    L(percentStyle, "Prolog", &.{ ".pro" }),
    L(percentStyle, "LaTeX", &.{ ".tex", ".latex", ".sty", ".cls" }),

    L(htmlStyle, "HTML", &.{ ".html", ".htm", ".xhtml" }),
    L(htmlStyle, "XML", &.{ ".xml", ".xsd", ".xsl" }),
    L(htmlStyle, "SVG", &.{ ".svg" }),
    L(htmlStyle, "Svelte", &.{ ".svelte" }),
    L(htmlStyle, "Vue", &.{ ".vue" }),

    L(cssStyle, "CSS", &.{ ".css" }),

    L(haskellStyle, "Haskell", &.{ ".hs", ".lhs" }),
    L(haskellStyle, "Elm", &.{ ".elm" }),
    L(haskellStyle, "PureScript", &.{".purs"}),
    L(haskellStyle, "Idris", &.{ ".idr" }),

    L(pascalStyle, "F#", &.{ ".fs", ".fsx", ".fsi" }),
    L(pascalStyle, "Pascal", &.{ ".pas", ".pp", ".inc" }),
    L(pascalStyle, "Delphi", &.{ ".dpr" }),

    L(ocamlStyle, "OCaml", &.{ ".ml", ".mli" }),

    L(noComment, "JSON", &.{ ".json" }),
    L(noComment, "Markdown", &.{ ".md", ".markdown" }),
    L(noComment, "reStructuredText", &.{".rst"}),

    // Unique comment syntax
    .{
        .name = "Lua",
        .extensions = &.{ ".lua" },
        .line_comment = "--",
        .block_comment_open = "--[[",
        .block_comment_close = "]]",
    },
    .{
        .name = "Julia",
        .extensions = &.{ ".jl" },
        .line_comment = "#",
        .block_comment_open = "#=",
        .block_comment_close = "=#",
    },
    .{
        .name = "PowerShell",
        .extensions = &.{ ".ps1", ".psm1" },
        .line_comment = "#",
        .block_comment_open = "<#",
        .block_comment_close = "#>",
    },
    .{
        .name = "Batch",
        .extensions = &.{ ".bat", ".cmd" },
        .line_comment = "::",
    },
    .{
        .name = "Fortran",
        .extensions = &.{ ".f", ".for", ".f90", ".f95" },
        .line_comment = "!",
    },
    .{
        .name = "COBOL",
        .extensions = &.{ ".cob", ".cbl" },
        .line_comment = "*",
    },
    .{
        .name = "Vim Script",
        .extensions = &.{ ".vim" },
        .line_comment = "\"",
    },
    .{
        .name = "BASIC",
        .extensions = &.{ ".bas", ".bi", ".bb" },
        .line_comment = "'",
    },
    .{
        .name = "Visual Basic",
        .extensions = &.{ ".vb", ".vbs" },
        .line_comment = "'",
    },
    .{
        .name = "WebAssembly Text",
        .extensions = &.{ ".wat", ".wast" },
        .line_comment = ";;",
        .block_comment_open = "(;",
        .block_comment_close = ";)",
    },

};

const ExtensionMap = std.StringHashMap(*const Language);

pub fn buildExtensionMap(allocator: std.mem.Allocator) !ExtensionMap {
    var map = ExtensionMap.init(allocator);
    for (&languages) |*l| {
        for (l.extensions) |ext| {
            try map.put(ext, l);
        }
    }
    return map;
}

pub fn detectByExtension(ext: []const u8, map: *const ExtensionMap) ?*const Language {
    return map.get(ext);
}

test "detectByExtension finds zig" {
    var map = try buildExtensionMap(std.testing.allocator);
    defer map.deinit();

    const lang = detectByExtension(".zig", &map).?;
    try std.testing.expectEqualStrings("Zig", lang.name);
}

test "detectByExtension returns null for unknown" {
    var map = try buildExtensionMap(std.testing.allocator);
    defer map.deinit();

    try std.testing.expectEqual(null, detectByExtension(".unknown", &map));
}

test "detectByExtension handles c extensions" {
    var map = try buildExtensionMap(std.testing.allocator);
    defer map.deinit();

    const c = detectByExtension(".c", &map).?;
    try std.testing.expectEqualStrings("C", c.name);

    const h = detectByExtension(".h", &map).?;
    try std.testing.expectEqualStrings("C", h.name);
}

test "new languages detected" {
    var map = try buildExtensionMap(std.testing.allocator);
    defer map.deinit();

    try std.testing.expect(detectByExtension(".cu", &map) != null);
    try std.testing.expect(detectByExtension(".coffee", &map) != null);
    try std.testing.expect(detectByExtension(".vue", &map) != null);
    try std.testing.expect(detectByExtension(".cr", &map) != null);
}

test "filename-based detection" {
    var map = try buildExtensionMap(std.testing.allocator);
    defer map.deinit();

    try std.testing.expect(detectByExtension("Makefile", &map) != null);
    try std.testing.expect(detectByExtension("Dockerfile", &map) != null);
    try std.testing.expect(detectByExtension("BUILD", &map) != null);
}
