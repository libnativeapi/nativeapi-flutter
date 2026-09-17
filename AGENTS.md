# libnativeapi workspace

This is a workspace repo for the [libnativeapi](https://github.com/libnativeapi) project family. `core/` and `bindings/*` are git submodules of independent repositories; the code generator (`tools/codegen/`) and the `./codegen` script live directly in this repo. Work inside a submodule is committed and pushed from that subdirectory; the workspace repo tracks submodule pointers, the code generator, and shared tooling.

## Layout

```
core/               # submodule: nativeapi — the C++ core library
bindings/
├── flutter/        # submodule: nativeapi-flutter
├── rust/           # submodule: nativeapi-rust
└── csharp/         # submodule: nativeapi-csharp
tools/codegen/      # in-repo Rust workspace: the code generator
tools/gui/          # GUI tests and demo scenarios for the examples (built on the skills)
codegen             # Python entry point orchestrating the generators
.agents/skills/     # agent skills: GUI testing and demo recording (see below)
```

## Architecture

- `core` — the C++ core library (repo: `nativeapi`). The source of truth for the native API surface (windows, tray icons, menus, displays, keyboard, dialogs, storage, etc.) with per-platform implementations (macOS/Windows/Linux).
- `tools/codegen` — three crates: `shared` (libclang parser, IR, naming), `capi` (C ABI + umbrella header), `bindings` (Rust/Dart/C# generators, consuming the IR JSON emitted by `capi`). Only `capi` depends on libclang. See tools/codegen/README.md.
- `bindings/*` — language bindings wrapping the core library (repos: `nativeapi-<lang>`). Each embeds the core repo as a nested submodule (`cxx_impl`). The Rust binding layers `crates/nativeapi` (safe API) over `crates/cnativeapi` (FFI).

## Design specs

`specs/` holds the settled design rules for `core/` — layering, the identity/value object
model, the public API style, the platform seam, the event system, managers, and the C ABI.
Start at [specs/README.md](specs/README.md); read the relevant spec before adding or
reshaping public API in `core/src/`.

Any diff that touches a public header in `core/src/` must pass the checklist at the end of
[specs/api-style.md](specs/api-style.md) — naming vocabulary, parameter and return types,
failure reporting, platform-availability notes, and the codegen constraints. When existing
headers disagree with each other, follow the spec, not the nearest neighbour: it records
which side of each split is the rule and which is legacy.

There is no separate issue list: each spec carries the open questions and known legacy
gaps of its own area inline (an "未决" section, or a "存量缺口" note next to the rule it
breaks). When one is resolved, edit the spec text itself.

## Code generation

Always drive the generators through `./codegen` at the workspace root:

- `./codegen` — full run: C ABI, then all bindings
- `./codegen capi` / `./codegen bindings [--lang rust,dart,csharp]`
- `./codegen check` — read-only verification, non-zero exit when stale (CI mode)
- `./codegen sync [-m "msg"] [--push]` — full downstream propagation, see below

Generated files start with `// AUTO-GENERATED. DO NOT EDIT.` — change the C++ headers in `core/src/` and regenerate instead of editing outputs. Files without that banner are hand-written and never overwritten. The header list (`API_HEADERS`) lives in `tools/codegen/shared/src/lib.rs`.

## Changing the core API

A core change ripples to every binding. After editing headers in `core`, run:

```bash
./codegen sync -m "<core commit message>"
```

It regenerates everything, updates each binding's embedded core submodule (fetched from the local `core/`, so no push is required first), reruns `bindgen` (Rust raw FFI) and the flutter repo's `codegen.py` (umbrella headers + ffigen), then commits core, each changed binding (`Sync with core <sha>`), and the workspace submodule pointers. Add `--push` to publish in dangling-safe order (core → bindings → workspace).

Manual follow-ups sync cannot do (details in tools/codegen/README.md):

- New handle types need an `IdTypeTag<T>` entry in `core/src/foundation/id_allocator.h` (append only; a miss is a compile error, not silent).
- New Rust modules need a `pub mod` declaration in `bindings/rust/crates/nativeapi/src/lib.rs`.

## Agent skills

`.agents/skills/` holds skills (a `SKILL.md` plus scripts each) for verifying windowing
work on a real desktop. Read the relevant `SKILL.md` before doing any of this by hand:

| Skill | Use it to |
| --- | --- |
| `flutter-ui-probe` | find where texts/widgets are in a running debug Flutter app (VM service) |
| `gui-test` | end-to-end test an app: launch, drive with guarded synthetic mouse input (read its safety rules first), assert on real window geometry and state |
| `remote-hosts` | build and run on another machine over SSH — Windows today, Linux/macOS prepared (SSH session vs. logged-on desktop) |
| `record-demo` | record a scripted demo of an app and cut it into an X-ready MP4 |

Skills hold only generic harnesses, recorders, and templates. The GUI tests and demo
scenarios for *this project's* examples live in [tools/gui/](tools/gui/README.md).

## Conventions

- Each submodule tracks `branch = main`. Use `make sync` to fast-forward all of them; `make status` to see dirty state everywhere; `make bump` to stage pointer updates.
- Commit workspace submodule pointer updates only when the combination is compatible (a known-good snapshot).
- Never commit in a submodule while on a detached HEAD — check out `main` first (`./codegen sync` enforces this).
- Do not add Co-Authored-By trailers to commits.
