# libnativeapi workspace

This is the workspace repo (`nativeapi-workspace`, formerly `nativeapi-flutter`) for the [libnativeapi](https://github.com/libnativeapi) project family. All three bindings (`bindings/dart/`, `bindings/rust/`, `bindings/csharp/`), the code generator (`tools/codegen/`), the `./codegen` script, the specs and the shared tooling live directly in this repo (the Rust and C# histories were merged in from `nativeapi-rust` and `nativeapi-csharp`); only `core/` is a git submodule of an independent repository. Work inside `core/` is committed and pushed from that subdirectory; everything else is committed here.

## Layout

```
core/               # submodule: nativeapi-core — the C++ core library
bindings/
├── dart/           # the Dart binding: nativeapi/, cnativeapi/, nativeapi_flutter/
├── rust/           # the Rust binding: crates/{nativeapi,cnativeapi}
└── csharp/         # the C# binding: src/, tests/, NativeAPI.slnx
examples/           # every binding's example apps, prefixed flutter_*, rust_*, csharp_*
pubspec.yaml        # pub workspace + melos root: Dart packages and Flutter examples
Cargo.toml          # cargo workspace root: Rust crates and examples
tools/codegen/      # in-repo Rust workspace: the code generator
tools/gui/          # GUI tests and demo scenarios for the examples (built on the skills)
codegen             # Python entry point orchestrating the generators
.agents/skills/     # agent skills: core API changes, GUI testing, demo recording (see below)
.claude/skills      # symlink → ../.agents/skills, so Claude Code discovers the same skills
```

## Architecture

- `core` — the C++ core library (repo: `nativeapi-core`). The source of truth for the native API surface (windows, tray icons, menus, displays, keyboard, dialogs, storage, etc.) with per-platform implementations (macOS/Windows/Linux).
- `tools/codegen` — three crates: `shared` (libclang parser, IR, naming), `capi` (C ABI + umbrella header), `bindings` (Rust/Dart/C# generators, consuming the IR JSON emitted by `capi`). Only `capi` depends on libclang. See tools/codegen/README.md.
- `bindings/*` — language bindings wrapping the core library. All live in this repo and build against the `core/` submodule directly (Rust `build.rs`, the Flutter plugin's CMake and generated Apple source wrappers, the C# native CMake). Only a published package carries its own copy of core, in `cxx_impl/`, which the release workflows vendor and never commit. The Rust binding layers `nativeapi` (safe API) over `cnativeapi` (FFI).

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
- `./codegen readme` — copy the shared README sections (`tools/readme/*.md`, e.g. Contributing) into core and every binding; `check` flags drift, `sync` runs it. Edit the snippet, never the copies.
- `./codegen sync [-m "msg"] [--push]` — full downstream propagation, see below

Generated files start with `// AUTO-GENERATED. DO NOT EDIT.` — change the C++ headers in `core/src/` and regenerate instead of editing outputs. Files without that banner are hand-written and never overwritten. The header list (`API_HEADERS`) lives in `tools/codegen/shared/src/lib.rs`.

## Changing the core API

A core change ripples to every binding. After editing headers in `core`, run:

```bash
./codegen sync -m "<core commit message>"
```

It regenerates everything, reruns `bindgen` (Rust raw FFI) and the Dart binding's `codegen.py` (umbrella headers + ffigen), then commits core and this repo (`Sync with core <sha>`: the core pointer plus everything regenerated under `bindings/`). Add `--push` to publish in dangling-safe order (core → workspace).

Manual follow-ups sync cannot do (details in tools/codegen/README.md):

- New handle types need an `IdTypeTag<T>` entry in `core/src/foundation/id_allocator.h` (append only; a miss is a compile error, not silent).
- Hand-written files in the bindings (exports, re-exports, changelogs, examples) are never touched by the generators. Rust's `pub mod` list is generated (`modules.rs`); Flutter's `lib/nativeapi.dart` exports are not.

The `core-api-change` skill walks the whole flow, including what to check before `sync` commits.

## Agent skills

`.agents/skills/` holds skills (a `SKILL.md` plus scripts each) for verifying windowing
work on a real desktop. Read the relevant `SKILL.md` before doing any of this by hand:

| Skill | Use it to |
| --- | --- |
| `core-api-change` | carry a public API change from `core/src/*.h` through codegen, the three bindings and the commits in core and this repo — including the pre-flight before `./codegen sync` |
| `flutter-ui-probe` | find where texts/widgets are in a running debug Flutter app (VM service) |
| `gui-test` | end-to-end test an app: launch, drive with guarded synthetic mouse input (read its safety rules first), assert on real window geometry and state |
| `remote-hosts` | build and run on another machine over SSH — Windows today, Linux/macOS prepared (SSH session vs. logged-on desktop) |
| `record-demo` | record a scripted demo of an app and cut it into an X-ready MP4 |

Skills hold only generic harnesses, recorders, and templates. The GUI tests and demo
scenarios for *this project's* examples live in [tools/gui/](tools/gui/README.md).

## Conventions

- `core` tracks `branch = main`. Use `make sync` to fast-forward it; `make status` to see dirty state everywhere; `make bump` to stage its pointer.
- The leanflutter packages built on nativeapi (`tray_manager`, `window_manager`, `launch_at_startup`, …) live in their own repos under github.com/leanflutter and depend on the published `nativeapi`; they are not part of this repo. To try one against local changes, point a `dependency_overrides` entry in that package at `bindings/dart/nativeapi` (and `cnativeapi`) and never commit the override.
- Commit workspace submodule pointer updates only when the combination is compatible (a known-good snapshot).
- Examples live in `examples/<binding>_<name>_example` (`flutter_`, `rust_`, `csharp_`), not inside the bindings; a new Flutter or Rust example must also be listed in the root `pubspec.yaml` / `Cargo.toml`, a C# one in `bindings/csharp/NativeAPI.slnx`. Only the pub.dev package examples (`bindings/dart/*/example`) stay inside their package.
- CI is one workflow per binding (`dart-ci.yml`, `rust-ci.yml`, `csharp-ci.yml`), each running only for changes under its `bindings/<lang>/` and its examples (`examples/flutter_*` for Dart, `examples/rust_*`, `examples/csharp_*`). Release tags are per binding: `v*` publishes the Dart packages (`dart-release.yml`), `rust-v*` publishes the crates (`rust-release.yml`); never push a bare `v*` tag for anything but the Dart packages.
- The Dart packages `cnativeapi`, `nativeapi` and `nativeapi_flutter` share one version: a release bumps all three pubspecs and CHANGELOGs, because pub.dev's automated publishing matches the tag `v<version>` against each package's own version. `nativeapi_flutter` is the Flutter-facing package; for now it only re-exports `package:nativeapi`.
- Never commit in a submodule while on a detached HEAD — check out `main` first (`./codegen sync` enforces this).
- Do not add Co-Authored-By trailers to commits.
