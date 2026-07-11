# zline

a line counter that goes fast

```
$ zline src/

 Language   Files   Lines   Code   Comments   Blanks
────────────────────────────────────────────────────
      Zig       7    1231   1066         15      150
────────────────────────────────────────────────────
    TOTAL       7    1231   1066         15      150

Scan: 156µs · Count: 50ms · 1 language (7 files, 1231 lines)
```

## features

- comment detection for 110+ languages
- filter columns with `--fields language,lines,code`
- sort by any column with `--sort lines`
- cross platform (hopefully)

## install

### download a binary

get the latest from [releases](https://github.com/flyewic/zline/releases), pick your platform, drop it in `$PATH`.

### build from source

you need [zig 0.16.0](https://ziglang.org/download/)

```bash
git clone https://github.com/flyewic/zline.git
cd zline
zig build -Doptimize=ReleaseSafe   # ~645KB, with safety checks
zig build -Doptimize=ReleaseSmall  # ~198KB, minimal size
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

### examples

```bash
zline --fields language,lines,code src/
zline --sort comments .
zline -j 16 ~/huge-repo
```

## development

```bash
zig build test                      # run tests
zig build                           # debug build with leak detection
zig build -Doptimize=ReleaseSafe    # release build (safety checks on)
zig build -Doptimize=ReleaseSmall   # min-size release (for distribution)
```

the debug build uses `DebugAllocator` and will panic if anything leaked. the release build uses raw page allocation, no overhead.

## adding languages

open `src/langs.zig`. most are a single line:

```zig
L(cStyle, "Rust", &.{ ".rs" }),
```

template styles handle the comment syntax for you. only unique cases like lua or julia get their own block.

## license

MIT, go nuts
