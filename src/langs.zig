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
    L(cStyle, "C", &.{ ".c", ".h", ".ec" }),
    L(cStyle, "C++", &.{ ".cpp", ".hpp", ".cc", ".cxx", ".hh", ".hxx" }),
    L(cStyle, "C#", &.{ ".cs" }),
    L(cStyle, "Java", &.{ ".java", ".jsp", ".jspf" }),
    L(cStyle, "JavaScript", &.{ ".js", ".jsx", ".mjs", ".cjs" }),
    L(cStyle, "TypeScript", &.{ ".ts", ".tsx", ".cts", ".mts" }),
    L(cStyle, "Go", &.{ ".go" }),
    L(cStyle, "Rust", &.{ ".rs" }),
    L(cStyle, "Swift", &.{ ".swift" }),
    L(cStyle, "Kotlin", &.{ ".kt", ".kts" }),
    L(cStyle, "Dart", &.{ ".dart" }),
    L(cStyle, "Scala", &.{ ".scala", ".sc" }),
    L(cStyle, "PHP", &.{ ".php", ".phtml", ".phps", ".phpt" }),
    L(cStyle, "SCSS", &.{ ".scss" }),
    L(cStyle, "Less", &.{ ".less" }),
    L(cStyle, "Verilog", &.{ ".v", ".sv", ".vh", ".svh" }),
    L(cStyle, "Protocol Buffers", &.{".proto"}),
    L(cStyle, "Thrift", &.{".thrift"}),
    L(cStyle, "Solidity", &.{ ".sol" }),
    L(cStyle, "CUE", &.{ ".cue" }),
    L(cStyle, "Objective-C", &.{ ".m", ".mm" }),
    L(cStyle, "Vala", &.{ ".vala", ".vapi" }),
    L(cStyle, "Groovy", &.{ ".groovy", ".gvy", "Jenkinsfile", ".jenkinsfile" }),
    L(cStyle, "Reason", &.{ ".re", ".rei" }),
    L(cStyle, "D", &.{ ".d" }),
    L(cStyle, "CUDA", &.{ ".cu", ".cuh" }),
    L(cStyle, "GLSL", &.{ ".glsl", ".vert", ".frag", ".geom", ".comp", ".fsh", ".vsh" }),
    L(cStyle, "HLSL", &.{ ".hlsl", ".fx", ".fxh", ".hlsli" }),
    L(cStyle, "Haxe", &.{ ".hx", ".hxml" }),
    L(cStyle, "ActionScript", &.{ ".as" }),
    L(cStyle, "Gradle", &.{ ".gradle" }),
    L(cStyle, "OpenCL", &.{ ".cl" }),
    L(cStyle, "Pony", &.{ ".pony" }),
    L(cStyle, "TTCN-3", &.{ ".ttcn", ".ttcn3" }),
    L(cStyle, "QML", &.{ ".qml" }),
    L(cStyle, "Sass", &.{ ".sass" }),
    L(cStyle, "Metal", &.{ ".metal" }),
    L(cStyle, "Processing", &.{ ".pde" }),
    L(cStyle, "Hare", &.{ ".ha" }),
    L(cStyle, "Slang", &.{ ".slang", ".slangh" }),
    L(cStyle, "V", &.{ ".v", ".vh" }),
    L(cStyle, "Jai", &.{ ".jai" }),
    L(cStyle, "Odin", &.{ ".odin" }),
    L(cStyle, "Wren", &.{ ".wren" }),
    L(cStyle, "Umka", &.{ ".um" }),
    L(cStyle, "C3", &.{ ".c3", ".c3i" }),
    L(cStyle, "Apex", &.{ ".cls", ".trigger" }),
    L(cStyle, "OpenSCAD", &.{ ".scad" }),
    L(cStyle, "Pkl", &.{ ".pkl" }),
    L(cStyle, "Prisma", &.{ ".prisma" }),
    L(cStyle, "Slint", &.{ ".slint" }),

    L(hashStyle, "Python", &.{ ".py", ".pyw", ".pyi" }),
    L(hashStyle, "Ruby", &.{ ".rb", ".rake", ".gemspec", "Vagrantfile", "Gemfile" }),
    L(hashStyle, "Perl", &.{ ".pl", ".pm", ".plx", ".ph" }),
    L(hashStyle, "R", &.{ ".r", ".R", ".Rmd" }),
    L(hashStyle, "Elixir", &.{ ".ex", ".exs" }),
    L(hashStyle, "Shell", &.{ ".sh", ".bash", ".zsh", ".fish", ".ksh", ".csh" }),
    L(hashStyle, "Makefile", &.{ ".make", ".mk", "Makefile", "makefile", "GNUmakefile" }),
    L(hashStyle, "CMake", &.{ ".cmake", "CMakeLists.txt" }),
    L(hashStyle, "Dockerfile", &.{ "Dockerfile", "Containerfile", ".dockerfile" }),
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
    L(hashStyle, "Haml", &.{ ".haml" }),
    L(hashStyle, "Jinja", &.{ ".jinja", ".jinja2", ".j2" }),
    L(hashStyle, "Just", &.{ ".just", "Justfile" }),
    L(hashStyle, "Properties", &.{ ".properties" }),
    L(hashStyle, "Racket", &.{ ".rkt", ".rktl" }),
    L(hashStyle, "Rego", &.{ ".rego" }),
    L(hashStyle, "Robot Framework", &.{ ".robot" }),
    L(hashStyle, "Slim", &.{ ".slim" }),
    L(hashStyle, "Twig", &.{ ".twig" }),

    L(hashCBlock, "Terraform", &.{ ".tf", ".tfvars" }),

    L(doubleDashStyle, "Ada", &.{ ".adb", ".ads", ".ada" }),
    L(doubleDashStyle, "VHDL", &.{ ".vhd", ".vhdl" }),
    L(doubleDashStyle, "Dhall", &.{ ".dhall" }),

    L(doubleDashCBlock, "SQL", &.{ ".sql", ".psql", ".cql" }),
    L(doubleDashCBlock, "PL/SQL", &.{ ".pks", ".pkb" }),

    L(semicolonStyle, "Clojure", &.{ ".clj", ".cljs", ".cljc", ".edn" }),
    L(semicolonStyle, "Lisp", &.{ ".lisp", ".lsp", ".cl" }),
    L(semicolonStyle, "Scheme", &.{ ".scm", ".ss" }),
    L(semicolonStyle, "Assembly", &.{ ".asm", ".s", ".S" }),
    L(semicolonStyle, "INI", &.{ ".ini", ".cfg", ".editorconfig" }),
    L(semicolonStyle, "Emacs Lisp", &.{ ".el" }),
    L(semicolonStyle, "Papyrus", &.{ ".psc" }),

    L(percentStyle, "Erlang", &.{ ".erl", ".hrl" }),
    L(percentStyle, "Prolog", &.{ ".pro" }),
    L(percentStyle, "LaTeX", &.{ ".tex", ".latex", ".sty" }),

    L(htmlStyle, "HTML", &.{ ".html", ".htm", ".xhtml", ".shtml" }),
    L(htmlStyle, "XML", &.{ ".xml", ".xsd", ".xsl", ".wsdl", ".xaml", ".csproj", ".vbproj", ".props", ".targets", ".ui", ".resx", ".plist", ".xib", "pom.xml" }),
    L(htmlStyle, "SVG", &.{ ".svg" }),
    L(htmlStyle, "Svelte", &.{ ".svelte" }),
    L(htmlStyle, "Vue", &.{ ".vue" }),
    L(htmlStyle, "Razor", &.{ ".cshtml", ".razor" }),

    L(cssStyle, "CSS", &.{ ".css", ".wxss" }),

    L(haskellStyle, "Haskell", &.{ ".hs", ".lhs" }),
    L(haskellStyle, "Elm", &.{ ".elm" }),
    L(haskellStyle, "PureScript", &.{".purs"}),
    L(haskellStyle, "Idris", &.{ ".idr" }),

    L(pascalStyle, "F#", &.{ ".fs", ".fsx", ".fsi" }),
    L(pascalStyle, "Pascal", &.{ ".pas", ".pp", ".inc" }),
    L(pascalStyle, "Delphi", &.{ ".dpr" }),

    L(ocamlStyle, "OCaml", &.{ ".ml", ".mli" }),

    L(noComment, "JSON", &.{ ".json", ".jsonl", ".geojson", ".har" }),
    L(noComment, "Markdown", &.{ ".md", ".markdown", ".mdx" }),
    L(noComment, "reStructuredText", &.{".rst"}),
    L(noComment, "Brainfuck", &.{ ".b", ".bf" }),
    L(noComment, "Text", &.{ ".txt", ".text" }),
    L(noComment, "AsciiDoc", &.{ ".adoc", ".asciidoc" }),
    L(noComment, "Handlebars", &.{ ".hbs", ".handlebars" }),
    L(noComment, "Pug", &.{ ".jade", ".pug" }),
    L(noComment, "Smarty", &.{ ".smarty", ".tpl" }),

    .{
        .name = "Lua",
        .extensions = &.{ ".lua", ".nse" },
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
        .extensions = &.{ ".ps1", ".psm1", ".psd1" },
        .line_comment = "#",
        .block_comment_open = "<#",
        .block_comment_close = "#>",
    },
    .{
        .name = "MATLAB",
        .extensions = &.{ ".m" },
        .line_comment = "%",
        .block_comment_open = "%{",
        .block_comment_close = "%}",
    },
    .{
        .name = "Batch",
        .extensions = &.{ ".bat", ".cmd", ".btm" },
        .line_comment = "::",
    },
    .{
        .name = "Fortran",
        .extensions = &.{ ".f", ".for", ".f90", ".f95", ".F", ".F90", ".F95", ".f03" },
        .line_comment = "!",
    },
    .{
        .name = "COBOL",
        .extensions = &.{ ".cob", ".cbl", ".cobol", ".cpy" },
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
        .name = "VBA",
        .extensions = &.{ ".vba" },
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

pub const HeuristicRule = struct {
    patterns: []const []const u8,
    lang: *const Language,
};

pub const AmbiguousInfo = struct {
    rules: []const HeuristicRule,
    fallback: *const Language,
};

pub const ExtInfo = union(enum) {
    unique: *const Language,
    ambiguous: AmbiguousInfo,
};

const RuleDef = struct {
    patterns: []const []const u8,
    lang_name: []const u8,
};

const AmbiguousDef = struct {
    ext: []const u8,
    rules: []const RuleDef,
    fallback_lang: []const u8,
};

const ambiguous_defs = [_]AmbiguousDef{
    .{
        .ext = ".cls",
        .rules = &.{
            .{ .patterns = &.{ "@isTest", "public class ", "private class ", "trigger ", "Schema." }, .lang_name = "Apex" },
            .{ .patterns = &.{ "\\documentclass", "\\usepackage", "\\begin{document}", "\\newcommand" }, .lang_name = "LaTeX" },
        },
        .fallback_lang = "LaTeX",
    },
    .{
        .ext = ".cl",
        .rules = &.{
            .{ .patterns = &.{ "#include", "__kernel", "get_global_id" }, .lang_name = "OpenCL" },
            .{ .patterns = &.{ "defpackage", "(defun ", "(defvar " }, .lang_name = "Lisp" },
        },
        .fallback_lang = "OpenCL",
    },
    .{
        .ext = ".m",
        .rules = &.{
            .{ .patterns = &.{ "@interface", "@implementation", "#import" }, .lang_name = "Objective-C" },
            .{ .patterns = &.{ "function ", "endfunction" }, .lang_name = "MATLAB" },
        },
        .fallback_lang = "Objective-C",
    },
    .{
        .ext = ".v",
        .rules = &.{
            .{ .patterns = &.{ "module ", "endmodule", "wire ", "reg ", "always" }, .lang_name = "Verilog" },
            .{ .patterns = &.{ "fn ", "mut ", "pub fn" }, .lang_name = "V" },
        },
        .fallback_lang = "Verilog",
    },
    .{
        .ext = ".vh",
        .rules = &.{
            .{ .patterns = &.{ "`ifndef", "`define", "`endif", "`include", "parameter " }, .lang_name = "Verilog" },
            .{ .patterns = &.{ "fn ", "mut ", "pub fn" }, .lang_name = "V" },
        },
        .fallback_lang = "Verilog",
    },
};

const shebang_map = [_]struct { name: []const u8, lang_name: []const u8 }{
    .{ .name = "python", .lang_name = "Python" },
    .{ .name = "perl", .lang_name = "Perl" },
    .{ .name = "ruby", .lang_name = "Ruby" },
    .{ .name = "node", .lang_name = "JavaScript" },
    .{ .name = "bash", .lang_name = "Shell" },
    .{ .name = "sh", .lang_name = "Shell" },
    .{ .name = "zsh", .lang_name = "Shell" },
    .{ .name = "fish", .lang_name = "Shell" },
    .{ .name = "php", .lang_name = "PHP" },
    .{ .name = "lua", .lang_name = "Lua" },
    .{ .name = "julia", .lang_name = "Julia" },
    .{ .name = "raku", .lang_name = "Raku" },
    .{ .name = "crystal", .lang_name = "Crystal" },
    .{ .name = "elixir", .lang_name = "Elixir" },
    .{ .name = "nix", .lang_name = "Nix" },
    .{ .name = "awk", .lang_name = "Awk" },
    .{ .name = "tclsh", .lang_name = "Tcl" },
    .{ .name = "wish", .lang_name = "Tcl" },
    .{ .name = "guile", .lang_name = "Scheme" },
    .{ .name = "sbcl", .lang_name = "Lisp" },
    .{ .name = "clisp", .lang_name = "Lisp" },
    .{ .name = "coffee", .lang_name = "CoffeeScript" },
    .{ .name = "haskell", .lang_name = "Haskell" },
    .{ .name = "ghc", .lang_name = "Haskell" },
    .{ .name = "runghc", .lang_name = "Haskell" },
    .{ .name = "groovy", .lang_name = "Groovy" },
    .{ .name = "scala", .lang_name = "Scala" },
    .{ .name = "dart", .lang_name = "Dart" },
    .{ .name = "deno", .lang_name = "JavaScript" },
    .{ .name = "bun", .lang_name = "JavaScript" },
    .{ .name = "pypy", .lang_name = "Python" },
    .{ .name = "make", .lang_name = "Makefile" },
    .{ .name = "pwsh", .lang_name = "PowerShell" },
};

fn findLangByName(name: []const u8) ?*const Language {
    for (&languages) |*l| {
        if (std.mem.eql(u8, l.name, name)) return l;
    }
    return null;
}

pub const ExtensionMap = struct {
    map: std.StringHashMap(ExtInfo),
    rule_mem: []HeuristicRule,

    pub fn deinit(self: *@This()) void {
        if (self.rule_mem.len > 0) {
            self.map.allocator.free(self.rule_mem);
        }
        self.map.deinit();
    }

    fn put(self: *@This(), key: []const u8, value: ExtInfo) !void {
        return self.map.put(key, value);
    }

    pub fn get(self: *const @This(), key: []const u8) ?ExtInfo {
        return self.map.get(key);
    }
};

pub fn buildExtensionMap(allocator: std.mem.Allocator) !ExtensionMap {
    var em = ExtensionMap{
        .map = std.StringHashMap(ExtInfo).init(allocator),
        .rule_mem = &.{},
    };

    for (&languages) |*l| {
        for (l.extensions) |ext| {
            try em.put(ext, .{ .unique = l });
        }
    }

    var total_rules: usize = 0;
    for (ambiguous_defs) |def| total_rules += def.rules.len;

    if (total_rules > 0) {
        var rules_mem = try allocator.alloc(HeuristicRule, total_rules);
        var rule_idx: usize = 0;

        for (ambiguous_defs) |def| {
            const rules = rules_mem[rule_idx..][0..def.rules.len];
            rule_idx += def.rules.len;
            for (def.rules, 0..) |def_rule, i| {
                rules[i] = .{ .patterns = def_rule.patterns, .lang = findLangByName(def_rule.lang_name).? };
            }
            try em.put(def.ext, .{ .ambiguous = .{
                .rules = rules,
                .fallback = findLangByName(def.fallback_lang).?,
            }});
        }
        em.rule_mem = rules_mem;
    }

    return em;
}

pub fn detect(ext: []const u8, basename: []const u8, map: *const ExtensionMap) ?ExtInfo {
    if (map.get(ext)) |info| return info;
    return map.get(basename);
}

pub fn needsContent(info: ExtInfo) bool {
    return info == .ambiguous;
}

pub fn resolve(info: ExtInfo, contents: []const u8) *const Language {
    return switch (info) {
        .unique => |l| l,
        .ambiguous => |amb| {
            var best: ?*const Language = null;
            var best_count: usize = 0;
            var tied = false;
            for (amb.rules) |rule| {
                var count: usize = 0;
                for (rule.patterns) |pattern| {
                    if (std.mem.indexOf(u8, contents, pattern) != null) count += 1;
                }
                if (count > best_count) {
                    best = rule.lang;
                    best_count = count;
                    tied = false;
                } else if (count == best_count and count > 0) {
                    tied = true;
                }
            }
            return if (tied) amb.fallback else best orelse amb.fallback;
        },
    };
}

pub fn shebangDetect(contents: []const u8) ?*const Language {
    if (contents.len < 3 or !std.mem.startsWith(u8, contents, "#!")) return null;

    const newline = std.mem.indexOfScalar(u8, contents, '\n') orelse contents.len;
    const line = std.mem.trim(u8, contents[2..newline], " \t\r");
    if (line.len == 0) return null;

    var interpreter = line;
    if (std.mem.indexOf(u8, line, "/env ")) |idx| {
        interpreter = std.mem.trim(u8, line[idx + 5 ..], " \t\r");
    } else if (std.mem.lastIndexOfScalar(u8, line, '/')) |idx| {
        interpreter = line[idx + 1 ..];
    }
    if (interpreter.len == 0) return null;

    if (std.mem.indexOfScalar(u8, interpreter, ' ')) |space_idx| {
        interpreter = interpreter[0..space_idx];
    }

    var end = interpreter.len;
    while (true) {
        const prev = end;
        while (end > 0 and std.ascii.isDigit(interpreter[end - 1])) : (end -= 1) {}
        while (end > 0 and (interpreter[end - 1] == '.' or interpreter[end - 1] == '-')) : (end -= 1) {}
        if (end == prev) break;
    }
    const base = interpreter[0..end];
    if (base.len == 0) return null;

    for (shebang_map) |entry| {
        if (std.mem.eql(u8, entry.name, base)) {
            return findLangByName(entry.lang_name);
        }
    }
    return null;
}

test "extension detection" {
    var map = try buildExtensionMap(std.testing.allocator);
    defer map.deinit();

    try std.testing.expectEqualStrings("Zig", resolve(map.get(".zig").?, "").name);
    try std.testing.expectEqualStrings("C", resolve(map.get(".c").?, "").name);
    try std.testing.expectEqualStrings("C", resolve(map.get(".h").?, "").name);
    try std.testing.expect(map.get(".unknown") == null);
}

test "basename and common extensions" {
    var map = try buildExtensionMap(std.testing.allocator);
    defer map.deinit();

    try std.testing.expect(map.get("Makefile") != null);
    try std.testing.expect(map.get("Dockerfile") != null);
    try std.testing.expect(map.get("BUILD") != null);
    try std.testing.expect(map.get(".cu") != null);
    try std.testing.expect(map.get(".coffee") != null);
    try std.testing.expect(map.get(".vue") != null);
    try std.testing.expect(map.get(".cr") != null);
}

test "ambiguous .cl disambiguation" {
    var map = try buildExtensionMap(std.testing.allocator);
    defer map.deinit();

    const info = map.get(".cl").?;
    try std.testing.expect(needsContent(info));

    try std.testing.expectEqualStrings("OpenCL", resolve(info, "").name);
    try std.testing.expectEqualStrings("OpenCL", resolve(info, "#include <CL/cl.h>\n__kernel void").name);
    try std.testing.expectEqualStrings("Lisp", resolve(info, "(defun hello ()\n  (print \"hi\"))").name);
    try std.testing.expectEqualStrings("Lisp", resolve(info, "(in-package :my-pkg)\n(defvar *x* 1)").name);
}

test "ambiguous .m disambiguation" {
    var map = try buildExtensionMap(std.testing.allocator);
    defer map.deinit();

    const info = map.get(".m").?;
    try std.testing.expect(needsContent(info));

    try std.testing.expectEqualStrings("Objective-C", resolve(info, "").name);
    try std.testing.expectEqualStrings("Objective-C", resolve(info, "@interface Foo : NSObject\n@end").name);
    try std.testing.expectEqualStrings("Objective-C", resolve(info, "#import <Foundation/Foundation.h>\n").name);
    try std.testing.expectEqualStrings("MATLAB", resolve(info, "function result = myfunc(x)\nendfunction").name);
}

test "ambiguous .v disambiguation" {
    var map = try buildExtensionMap(std.testing.allocator);
    defer map.deinit();

    const info = map.get(".v").?;
    try std.testing.expect(needsContent(info));

    try std.testing.expectEqualStrings("Verilog", resolve(info, "").name);
    try std.testing.expectEqualStrings("Verilog", resolve(info, "module counter;\n  wire clk;\nendmodule").name);
    try std.testing.expectEqualStrings("V", resolve(info, "fn main() {\n  mut x := 1\n}").name);
}

test "ambiguous .vh disambiguation" {
    var map = try buildExtensionMap(std.testing.allocator);
    defer map.deinit();

    const info = map.get(".vh").?;
    try std.testing.expect(needsContent(info));

    try std.testing.expectEqualStrings("Verilog", resolve(info, "").name);
    try std.testing.expectEqualStrings("Verilog", resolve(info, "`ifndef FOO\n`define FOO 1\n`endif").name);
    try std.testing.expectEqualStrings("V", resolve(info, "pub fn foo() {\n  mut x := 1\n}").name);
}

test "shebang detection" {
    try std.testing.expectEqualStrings("Python", shebangDetect("#!/usr/bin/python3\n").?.name);
    try std.testing.expectEqualStrings("Python", shebangDetect("#!/usr/bin/env python\n").?.name);
    try std.testing.expectEqualStrings("Shell", shebangDetect("#!/bin/bash\n").?.name);
    try std.testing.expectEqualStrings("Shell", shebangDetect("#!/bin/sh\n").?.name);
    try std.testing.expectEqualStrings("Perl", shebangDetect("#!/usr/bin/perl -w\n").?.name);
    try std.testing.expectEqualStrings("Ruby", shebangDetect("#!/usr/bin/env ruby\n").?.name);
    try std.testing.expectEqualStrings("JavaScript", shebangDetect("#!/usr/bin/env node\n").?.name);
    try std.testing.expect(shebangDetect("not a shebang\n") == null);
    try std.testing.expect(shebangDetect("") == null);
}

test "shebang edge cases" {
    try std.testing.expectEqualStrings("Python", shebangDetect("#!/usr/bin/python3.11 -u\n").?.name);
    try std.testing.expectEqualStrings("Python", shebangDetect("#!/bin/env python3\n").?.name);
    try std.testing.expectEqualStrings("Lua", shebangDetect("#!/usr/bin/env lua\n").?.name);
    try std.testing.expect(shebangDetect("#!/usr/bin/env\n") == null);
    try std.testing.expect(shebangDetect("#!\n") == null);
}

test "needsContent for unique vs ambiguous" {
    var map = try buildExtensionMap(std.testing.allocator);
    defer map.deinit();

    try std.testing.expect(!needsContent(map.get(".zig").?));
    try std.testing.expect(!needsContent(map.get(".rs").?));
    try std.testing.expect(needsContent(map.get(".cl").?));
    try std.testing.expect(needsContent(map.get(".m").?));
}

test "resolve unique ignores content" {
    var map = try buildExtensionMap(std.testing.allocator);
    defer map.deinit();

    const info = map.get(".zig").?;
    try std.testing.expectEqualStrings("Zig", resolve(info, "").name);
    try std.testing.expectEqualStrings("Zig", resolve(info, "anything at all").name);
}

test "scoring picks most patterns matched" {
    var map = try buildExtensionMap(std.testing.allocator);
    defer map.deinit();

    const info = map.get(".cl").?;

    try std.testing.expectEqualStrings("OpenCL", resolve(info, "#include <foo.h>\n__kernel void").name);
    try std.testing.expectEqualStrings("Lisp", resolve(info, "(defun foo ()\n(defvar *x* 1)\n#include <bar.h>").name);
}

test "scoring tie falls back to default" {
    var map = try buildExtensionMap(std.testing.allocator);
    defer map.deinit();

    const info = map.get(".cl").?;

    try std.testing.expectEqualStrings("OpenCL", resolve(info, "#include <foo.h>\n(defun bar ())").name);
}

test "detect extension priority over basename" {
    var map = try buildExtensionMap(std.testing.allocator);
    defer map.deinit();

    const info = detect(".zig", "main.cpp", &map).?;
    try std.testing.expectEqualStrings("Zig", resolve(info, "").name);
}

test "detect falls back to basename" {
    var map = try buildExtensionMap(std.testing.allocator);
    defer map.deinit();

    const info = detect("", "Makefile", &map).?;
    try std.testing.expectEqualStrings("Makefile", resolve(info, "").name);
}

test "detect returns null for unknown" {
    var map = try buildExtensionMap(std.testing.allocator);
    defer map.deinit();

    try std.testing.expect(detect(".wut", "unknown.wut", &map) == null);
}
