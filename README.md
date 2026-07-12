# zline

a line counter that goes fast

```
$ zline src/

 Language   Files   Lines   Code   Comments   Blanks
────────────────────────────────────────────────────
      Zig       7    2186   1908         27      251
────────────────────────────────────────────────────
    TOTAL       7    2186   1908         27      251

Scan: 29µs | Count: 87µs | 1 language (7 files, 2186 lines)
```

```
$ zline --output json --languages Go,Python my-project/

{
  "languages": [
    {"language": "Go", "files": 38, "lines": 5658, "code": 4759, "comments": 110, "blanks": 789},
    {"language": "Python", "files": 3, "lines": 589, "code": 364, "comments": 141, "blanks": 84}
  ],
  "total": {"files": 41, "lines": 6247, "code": 5123, "comments": 251, "blanks": 873}
}
```

## features

- comment detection for 160+ languages
- 3-stage language detection: extension → heuristics → shebang
- pattern matching to resolve ambiguous extensions (`.m` → MATLAB vs Obj-C)
- shebang detection for extensionless scripts (`#!/usr/bin/env python3`)
- multiple output formats: table (default), json, csv
- filter languages to show with `--languages zig,rust,go`
- filter columns with `--fields language,lines,code`
- sort by any column with `--sort lines`
- counts lines inside archives (`.zip`, `.tar`, `.tar.gz`, `.tar.bz2`, `.tar.xz`)
- multi-threaded counting for large directories
- single file target support
- cross platform

## install

### homebrew

```bash
brew tap flyewic/zline https://github.com/flyewic/zline
brew install zline
```

### scoop

```bash
scoop bucket add flyewic https://github.com/flyewic/zline
scoop install zline
```

### nix

```bash
nix profile install github:flyewic/zline
```

or try it without installing:

```bash
nix run github:flyewic/zline -- src/
```

### direct download

get the latest from [releases](https://github.com/flyewic/zline/releases), pick your platform, drop it in `$PATH`.

### build from source

you need [zig 0.16.0](https://ziglang.org/download/)

```bash
git clone https://github.com/flyewic/zline.git
cd zline
zig build -Doptimize=ReleaseSafe   # with safety checks
zig build -Doptimize=ReleaseSmall  # minimal size
cp zig-out/bin/zline ~/.local/bin/
```

that's it

## usage

```bash
zline [options] [path]
```

defaults to the current directory if you leave out the path

| flag | what it does |
|---|---|
| `-h, --help` | print help |
| `-v, --version` | print version |
| `-j, --jobs N` | number of parallel workers (default: your cpu count) |
| `--sort FIELD` | sort by `name`, `files`, `lines`, `code`, `comments`, or `blanks` |
| `--fields FIELDS` | comma-separated columns, like `language,lines,code` |
| `--hidden` | include hidden files and directories |
| `-o, --output FORMAT` | output format: `table` (default), `json`, `csv` |
| `-l, --languages LANGS` | comma-separated languages to show, case-insensitive (`zig,rust,go`) |

### examples

```bash
zline --fields language,lines,code src/
zline --sort comments .
zline -j 16 ~/huge-repo
zline --hidden ~/dotfiles
zline --output json src/
zline -o csv -l zig,rust --sort code
zline --languages Python,JavaScript --fields language,lines --output json
```

## development

```bash
zig build test                      # run tests
zig build                           # debug build with leak detection
zig build -Doptimize=ReleaseSafe    # release build (safety checks on)
zig build -Doptimize=ReleaseSmall   # min-size release (for distribution)
```

the debug build uses `DebugAllocator` and will panic if anything leaked. the release build uses raw page allocation, no overhead.

## troubleshooting

### macOS gatekeeper

downloaded binaries are unsigned, so gatekeeper blocks them. pick your fix:

```
# quick: strip the quarantine flag
xattr -dr com.apple.quarantine /usr/local/bin/zline

# or: right-click the binary in Finder → Open (once)

# or: build from source, gatekeeper won't interfere
zig build -Doptimize=ReleaseSmall
```

### windows smart screen

first launch may trigger windows defender smartscreen. click "More info" → "Run anyway". happens once.

## adding languages

open `src/langs.zig`. most are a single line:

```zig
L(.c_style, "Rust", &.{ ".rs" }),
```

the `CommentStyle` enum handles the comment syntax for you. only unique cases like lua or julia get their own block.

for extensions shared by multiple languages (`.m` is both Objective-C and MATLAB), add entries to the `ambiguous_defs` array with pattern scoring rules. the tool will peek at file contents to decide.

## license

MIT, go nuts
