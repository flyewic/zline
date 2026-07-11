const std = @import("std");

pub const CommentStyle = enum(u8) {
    c_style,
    hash_style,
    hash_c_block,
    double_dash,
    double_dash_c_block,
    semicolon,
    percent,
    html,
    css_block,
    haskell,
    pascal,
    ocaml,
    lua,
    julia,
    powershell,
    matlab,
    batch,
    fortran,
    cobol,
    vb_tick,
    vim_quote,
    wasm_text,
    no_comment,
};

const CommentMarkers = struct {
    line: ?[]const u8 = null,
    block_open: ?[]const u8 = null,
    block_close: ?[]const u8 = null,
};

pub const markers = [_]CommentMarkers{
    .{ .line = "//", .block_open = "/*", .block_close = "*/" },
    .{ .line = "#" },
    .{ .line = "#", .block_open = "/*", .block_close = "*/" },
    .{ .line = "--" },
    .{ .line = "--", .block_open = "/*", .block_close = "*/" },
    .{ .line = ";" },
    .{ .line = "%" },
    .{ .block_open = "<!--", .block_close = "-->" },
    .{ .block_open = "/*", .block_close = "*/" },
    .{ .line = "--", .block_open = "{-", .block_close = "-}" },
    .{ .line = "//", .block_open = "(*", .block_close = "*)" },
    .{ .block_open = "(*", .block_close = "*)" },
    .{ .line = "--", .block_open = "--[[", .block_close = "]]" },
    .{ .line = "#", .block_open = "#=", .block_close = "=#" },
    .{ .line = "#", .block_open = "<#", .block_close = "#>" },
    .{ .line = "%", .block_open = "%{", .block_close = "%}" },
    .{ .line = "::" },
    .{ .line = "!" },
    .{ .line = "*" },
    .{ .line = "'" },
    .{ .line = "\"" },
    .{ .line = ";;", .block_open = "(;", .block_close = ";)" },
    .{},
};

pub const Language = struct {
    name: []const u8,
    extensions: []const []const u8,
    style: CommentStyle,
};

fn L(comptime style: CommentStyle, comptime name: []const u8, comptime exts: []const []const u8) Language {
    return .{ .name = name, .extensions = exts, .style = style };
}

pub const languages = [_]Language{
    L(.c_style, "Zig", &.{ ".zig", ".zon" }),
    L(.c_style, "C", &.{ ".c", ".h", ".ec" }),
    L(.c_style, "C++", &.{ ".cpp", ".hpp", ".cc", ".cxx", ".hh", ".hxx" }),
    L(.c_style, "C#", &.{ ".cs" }),
    L(.c_style, "Java", &.{ ".java", ".jsp", ".jspf" }),
    L(.c_style, "JavaScript", &.{ ".js", ".jsx", ".mjs", ".cjs" }),
    L(.c_style, "TypeScript", &.{ ".ts", ".tsx", ".cts", ".mts" }),
    L(.c_style, "Go", &.{ ".go" }),
    L(.c_style, "Rust", &.{ ".rs" }),
    L(.c_style, "Swift", &.{ ".swift" }),
    L(.c_style, "Kotlin", &.{ ".kt", ".kts" }),
    L(.c_style, "Dart", &.{ ".dart" }),
    L(.c_style, "Scala", &.{ ".scala", ".sc" }),
    L(.c_style, "PHP", &.{ ".php", ".phtml", ".phps", ".phpt" }),
    L(.c_style, "SCSS", &.{ ".scss" }),
    L(.c_style, "Less", &.{ ".less" }),
    L(.c_style, "Verilog", &.{ ".v", ".sv", ".vh", ".svh" }),
    L(.c_style, "Protocol Buffers", &.{".proto"}),
    L(.c_style, "Thrift", &.{".thrift"}),
    L(.c_style, "Solidity", &.{ ".sol" }),
    L(.c_style, "CUE", &.{ ".cue" }),
    L(.c_style, "Objective-C", &.{ ".m", ".mm" }),
    L(.c_style, "Vala", &.{ ".vala", ".vapi" }),
    L(.c_style, "Groovy", &.{ ".groovy", ".gvy", "Jenkinsfile", ".jenkinsfile" }),
    L(.c_style, "Reason", &.{ ".re", ".rei" }),
    L(.c_style, "D", &.{ ".d" }),
    L(.c_style, "CUDA", &.{ ".cu", ".cuh" }),
    L(.c_style, "GLSL", &.{ ".glsl", ".vert", ".frag", ".geom", ".comp", ".fsh", ".vsh" }),
    L(.c_style, "HLSL", &.{ ".hlsl", ".fx", ".fxh", ".hlsli" }),
    L(.c_style, "Haxe", &.{ ".hx", ".hxml" }),
    L(.c_style, "ActionScript", &.{ ".as" }),
    L(.c_style, "Gradle", &.{ ".gradle", ".gradle.kts" }),
    L(.c_style, "OpenCL", &.{ ".cl" }),
    L(.c_style, "Pony", &.{ ".pony" }),
    L(.c_style, "TTCN-3", &.{ ".ttcn", ".ttcn3" }),
    L(.c_style, "QML", &.{ ".qml" }),
    L(.c_style, "Sass", &.{ ".sass" }),
    L(.c_style, "Metal", &.{ ".metal" }),
    L(.c_style, "Processing", &.{ ".pde" }),
    L(.c_style, "Hare", &.{ ".ha" }),
    L(.c_style, "Slang", &.{ ".slang", ".slangh" }),
    L(.c_style, "V", &.{ ".v", ".vh" }),
    L(.c_style, "Jai", &.{ ".jai" }),
    L(.c_style, "Odin", &.{ ".odin" }),
    L(.c_style, "Wren", &.{ ".wren" }),
    L(.c_style, "Umka", &.{ ".um" }),
    L(.c_style, "C3", &.{ ".c3", ".c3i" }),
    L(.c_style, "Apex", &.{ ".cls", ".trigger" }),
    L(.c_style, "OpenSCAD", &.{ ".scad" }),
    L(.c_style, "Pkl", &.{ ".pkl" }),
    L(.c_style, "Prisma", &.{ ".prisma" }),
    L(.c_style, "Slint", &.{ ".slint" }),
    L(.c_style, "Templ", &.{ ".templ" }),
    L(.c_style, "ReScript", &.{ ".res", ".resi" }),
    L(.c_style, "Gleam", &.{ ".gleam" }),
    L(.c_style, "SurrealQL", &.{ ".surql" }),
    L(.c_style, "Ziggy", &.{ ".zos" }),

    L(.hash_style, "Python", &.{ ".py", ".pyw", ".pyi" }),
    L(.hash_style, "Ruby", &.{ ".rb", ".rake", ".gemspec", "Vagrantfile", "Gemfile" }),
    L(.hash_style, "Perl", &.{ ".pl", ".pm", ".plx", ".ph" }),
    L(.hash_style, "R", &.{ ".r", ".R", ".Rmd" }),
    L(.hash_style, "Elixir", &.{ ".ex", ".exs" }),
    L(.hash_style, "Bash", &.{ ".sh", ".bash" }),
    L(.hash_style, "Zsh", &.{ ".zsh" }),
    L(.hash_style, "Fish", &.{ ".fish" }),
    L(.hash_style, "Ksh", &.{ ".ksh" }),
    L(.hash_style, "Csh", &.{ ".csh" }),
    L(.hash_style, "Makefile", &.{ ".make", ".mk", "Makefile", "makefile", "GNUmakefile" }),
    L(.hash_style, "CMake", &.{ ".cmake", "CMakeLists.txt" }),
    L(.hash_style, "Dockerfile", &.{ "Dockerfile", "Containerfile", ".dockerfile" }),
    L(.hash_style, "YAML", &.{ ".yaml", ".yml" }),
    L(.hash_style, "TOML", &.{ ".toml" }),
    L(.hash_style, "GraphQL", &.{ ".graphql", ".gql" }),
    L(.hash_style, "Vyper", &.{ ".vy" }),
    L(.hash_style, "Nix", &.{ ".nix" }),
    L(.hash_style, "Starlark", &.{ ".bzl", "BUILD", "BUILD.bazel" }),
    L(.hash_style, "RON", &.{ ".ron" }),
    L(.hash_style, "Crystal", &.{ ".cr" }),
    L(.hash_style, "Nim", &.{ ".nim", ".nims", ".nimble" }),
    L(.hash_style, "Tcl", &.{ ".tcl" }),
    L(.hash_style, "Awk", &.{ ".awk" }),
    L(.hash_style, "Raku", &.{ ".raku", ".rakumod" }),
    L(.hash_style, "CoffeeScript", &.{".coffee"}),
    L(.hash_style, "Mojo", &.{ ".mojo" }),
    L(.hash_style, "EEx", &.{ ".eex" }),
    L(.hash_style, "HEEx", &.{ ".heex" }),
    L(.hash_style, "Nickel", &.{ ".ncl" }),
    L(.hash_style, "Nushell", &.{ ".nu" }),
    L(.hash_style, "Meson", &.{ "meson.build" }),
    L(.hash_style, "Sage", &.{ ".sage" }),
    L(.hash_style, "Gnuplot", &.{ ".gp", ".gnuplot" }),
    L(.hash_style, "GDScript", &.{ ".gd" }),
    L(.hash_style, "Haml", &.{ ".haml" }),
    L(.hash_style, "Jinja", &.{ ".jinja", ".jinja2", ".j2" }),
    L(.hash_style, "Just", &.{ ".just", "Justfile" }),
    L(.hash_style, "Properties", &.{ ".properties" }),
    L(.hash_style, "Racket", &.{ ".rkt", ".rktl" }),
    L(.hash_style, "Rego", &.{ ".rego" }),
    L(.hash_style, "Robot Framework", &.{ ".robot" }),
    L(.hash_style, "Slim", &.{ ".slim" }),
    L(.hash_style, "Twig", &.{ ".twig" }),

    L(.hash_c_block, "Terraform", &.{ ".tf", ".tfvars" }),
    L(.hash_c_block, "HCL", &.{ ".hcl", ".nomad" }),

    L(.double_dash, "Ada", &.{ ".adb", ".ads", ".ada" }),
    L(.double_dash, "VHDL", &.{ ".vhd", ".vhdl" }),
    L(.double_dash, "Dhall", &.{ ".dhall" }),

    L(.double_dash_c_block, "SQL", &.{ ".sql", ".psql", ".cql" }),
    L(.double_dash_c_block, "PL/SQL", &.{ ".pks", ".pkb" }),

    L(.semicolon, "Clojure", &.{ ".clj", ".cljs", ".cljc", ".edn" }),
    L(.semicolon, "Lisp", &.{ ".lisp", ".lsp", ".cl" }),
    L(.semicolon, "Scheme", &.{ ".scm", ".ss" }),
    L(.semicolon, "Assembly", &.{ ".asm", ".s", ".S" }),
    L(.semicolon, "INI", &.{ ".ini", ".cfg", ".editorconfig" }),
    L(.semicolon, "Emacs Lisp", &.{ ".el" }),
    L(.semicolon, "Papyrus", &.{ ".psc" }),

    L(.percent, "Erlang", &.{ ".erl", ".hrl" }),
    L(.percent, "Prolog", &.{ ".pro" }),
    L(.percent, "LaTeX", &.{ ".tex", ".latex", ".sty" }),

    L(.html, "HTML", &.{ ".html", ".htm", ".xhtml", ".shtml" }),
    L(.html, "XML", &.{ ".xml", ".xsd", ".xsl", ".wsdl", ".xaml", ".csproj", ".vbproj", ".props", ".targets", ".ui", ".resx", ".plist", ".xib", "pom.xml" }),
    L(.html, "SVG", &.{ ".svg" }),
    L(.html, "Svelte", &.{ ".svelte" }),
    L(.html, "Vue", &.{ ".vue" }),
    L(.html, "Razor", &.{ ".cshtml", ".razor" }),
    L(.html, "Astro", &.{ ".astro" }),
    L(.html, "Ruby HTML", &.{ ".rhtml" }),

    L(.css_block, "CSS", &.{ ".css", ".wxss" }),

    L(.haskell, "Haskell", &.{ ".hs", ".lhs" }),
    L(.haskell, "Elm", &.{ ".elm" }),
    L(.haskell, "PureScript", &.{".purs"}),
    L(.haskell, "Idris", &.{ ".idr" }),

    L(.pascal, "F#", &.{ ".fs", ".fsx", ".fsi" }),
    L(.pascal, "Pascal", &.{ ".pas", ".pp", ".inc" }),
    L(.pascal, "Delphi", &.{ ".dpr" }),

    L(.ocaml, "OCaml", &.{ ".ml", ".mli" }),

    L(.no_comment, "JSON", &.{ ".json", ".jsonl", ".geojson", ".har" }),
    L(.no_comment, "Markdown", &.{ ".md", ".markdown", ".mdx" }),
    L(.no_comment, "reStructuredText", &.{".rst"}),
    L(.no_comment, "Brainfuck", &.{ ".b", ".bf" }),
    L(.no_comment, "Text", &.{ ".txt", ".text" }),
    L(.no_comment, "AsciiDoc", &.{ ".adoc", ".asciidoc" }),
    L(.no_comment, "Handlebars", &.{ ".hbs", ".handlebars" }),
    L(.no_comment, "Pug", &.{ ".jade", ".pug" }),
    L(.no_comment, "Smarty", &.{ ".smarty", ".tpl" }),

    .{ .name = "Lua", .extensions = &.{ ".lua", ".nse" }, .style = .lua },
    .{ .name = "Julia", .extensions = &.{ ".jl" }, .style = .julia },
    .{ .name = "PowerShell", .extensions = &.{ ".ps1", ".psm1", ".psd1" }, .style = .powershell },
    .{ .name = "MATLAB", .extensions = &.{ ".m" }, .style = .matlab },
    .{ .name = "Batch", .extensions = &.{ ".bat", ".cmd", ".btm" }, .style = .batch },
    .{ .name = "Fortran", .extensions = &.{ ".f", ".for", ".f90", ".f95", ".F", ".F90", ".F95", ".f03" }, .style = .fortran },
    .{ .name = "COBOL", .extensions = &.{ ".cob", ".cbl", ".cobol", ".cpy" }, .style = .cobol },
    .{ .name = "Vim Script", .extensions = &.{ ".vim" }, .style = .vim_quote },
    .{ .name = "BASIC", .extensions = &.{ ".bas", ".bi", ".bb" }, .style = .vb_tick },
    .{ .name = "Visual Basic", .extensions = &.{ ".vb", ".vbs" }, .style = .vb_tick },
    .{ .name = "VBA", .extensions = &.{ ".vba" }, .style = .vb_tick },
    .{ .name = "WebAssembly Text", .extensions = &.{ ".wat", ".wast" }, .style = .wasm_text },
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
    .{ .name = "bash", .lang_name = "Bash" },
    .{ .name = "sh", .lang_name = "Bash" },
    .{ .name = "zsh", .lang_name = "Zsh" },
    .{ .name = "fish", .lang_name = "Fish" },
    .{ .name = "ksh", .lang_name = "Ksh" },
    .{ .name = "csh", .lang_name = "Csh" },
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
    try std.testing.expectEqualStrings("Bash", shebangDetect("#!/bin/bash\n").?.name);
    try std.testing.expectEqualStrings("Bash", shebangDetect("#!/bin/sh\n").?.name);
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

test "ambiguous .cls disambiguation" {
    var map = try buildExtensionMap(std.testing.allocator);
    defer map.deinit();

    const info = map.get(".cls").?;
    try std.testing.expect(needsContent(info));

    try std.testing.expectEqualStrings("LaTeX", resolve(info, "").name);
    try std.testing.expectEqualStrings("LaTeX", resolve(info, "\\documentclass{article}\n\\begin{document}").name);
    try std.testing.expectEqualStrings("Apex", resolve(info, "public class MyController {\n    @isTest\n}").name);
    try std.testing.expectEqualStrings("Apex", resolve(info, "trigger AccountTrigger on Account (before insert) {\n}").name);
}

test "shebang make and pwsh" {
    try std.testing.expectEqualStrings("Makefile", shebangDetect("#!/usr/bin/make\n").?.name);
    try std.testing.expectEqualStrings("PowerShell", shebangDetect("#!/usr/bin/pwsh\n").?.name);
}

test "new languages in extension map" {
    var map = try buildExtensionMap(std.testing.allocator);
    defer map.deinit();

    try std.testing.expect(detect(".trigger", "MyTrigger.trigger", &map) != null);
    try std.testing.expect(detect(".scad", "model.scad", &map) != null);
    try std.testing.expect(detect(".pkl", "config.pkl", &map) != null);
    try std.testing.expect(detect(".prisma", "schema.prisma", &map) != null);
    try std.testing.expect(detect(".slint", "ui.slint", &map) != null);
    try std.testing.expect(detect(".adoc", "readme.adoc", &map) != null);
    try std.testing.expect(detect(".hbs", "template.hbs", &map) != null);
    try std.testing.expect(detect(".twig", "page.twig", &map) != null);
    try std.testing.expect(detect(".jinja", "page.jinja", &map) != null);
    try std.testing.expect(detect(".j2", "page.j2", &map) != null);
    try std.testing.expect(detect(".robot", "test.robot", &map) != null);
    try std.testing.expect(detect(".rego", "policy.rego", &map) != null);
    try std.testing.expect(detect(".just", "justfile.just", &map) != null);
    try std.testing.expect(detect(".haml", "view.haml", &map) != null);
    try std.testing.expect(detect(".slim", "view.slim", &map) != null);
    try std.testing.expect(detect(".tpl", "template.tpl", &map) != null);
    try std.testing.expect(detect(".cshtml", "view.cshtml", &map) != null);
    try std.testing.expect(detect(".vba", "module.vba", &map) != null);
    try std.testing.expect(detect(".txt", "notes.txt", &map) != null);
    try std.testing.expect(detect(".properties", "config.properties", &map) != null);

    try std.testing.expect(detect(".cts", "module.cts", &map) != null);
    try std.testing.expect(detect(".mts", "module.mts", &map) != null);
    try std.testing.expect(detect(".ksh", "script.ksh", &map) != null);
    try std.testing.expect(detect(".F90", "mod.F90", &map) != null);
    try std.testing.expect(detect(".cobol", "prog.cobol", &map) != null);
    try std.testing.expect(detect(".Rmd", "report.Rmd", &map) != null);
    try std.testing.expect(detect(".xaml", "ui.xaml", &map) != null);
    try std.testing.expect(detect(".csproj", "proj.csproj", &map) != null);
}
