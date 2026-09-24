# libnativeapi workspace

The development home of the [libnativeapi](https://github.com/libnativeapi) project: the Dart, Rust and C# bindings, the code generator, the design specs and the shared tooling live directly in this repository, and the C++ core is a git submodule. A core change and its regenerated bindings (core → codegen → bindings) are made and tracked together here.

This repository was `nativeapi-flutter` until 2026-09; its history, issues and stars carry over. The histories of the former `workspace`, `nativeapi-rust` and `nativeapi-csharp` repositories are merged in.

## Layout

| Path | Description |
| --- | --- |
| [core](https://github.com/libnativeapi/nativeapi-core) | submodule: C++ core library (`nativeapi-core`) |
| [bindings/dart](bindings/dart) | Dart binding (packages `nativeapi`, `cnativeapi`, `nativeapi_flutter`) |
| [bindings/rust](bindings/rust) | Rust binding (crates `nativeapi`, `cnativeapi`) |
| [bindings/csharp](bindings/csharp) | C# binding |
| [examples](examples) | example apps of every binding: `flutter_*`, `rust_*`, `csharp_*` |
| `tools/codegen` | the C ABI and binding generators |
| `specs` | design rules for the core's public API |

## Getting started

```bash
git clone --recursive git@github.com:libnativeapi/nativeapi-workspace.git
```

Already cloned without `--recursive`?

```bash
git submodule update --init --recursive
```

The root `pubspec.yaml` is the pub workspace (and melos) root for the Dart packages and the Flutter examples, and the root `Cargo.toml` is the cargo workspace for the Rust crates and examples, so `flutter pub get` and `cargo build` run from the repository root.

## Code generation

`tools/codegen` generates the C ABI and all language bindings from the C++ headers in `core/`. Run it via the wrapper script:

```bash
./codegen         # full run: C ABI, then all bindings
./codegen check   # verify generated files are up to date (CI mode)
./codegen readme  # copy the shared README sections (tools/readme/) into every repo
./codegen sync    # after a core change: regenerate everything, rerun
                  #   bindgen/ffigen, and commit core, then this repo
                  #   (add --push to also push, -m "..." for the core message)
```

See [tools/codegen/README.md](tools/codegen/README.md) for details.

## Common tasks

```bash
make status   # working-tree status of this repo and every submodule
make sync     # fast-forward core to origin/main
make bump     # stage the updated core pointer for commit
```

Work on the bindings, the tooling and the specs is committed here directly. Work inside `core` is committed and pushed from that subdirectory as if it were a standalone clone; this repository then records the updated pointer once the combination is known to be compatible.

## Releases

Each binding is released from a tag of its own: `v<version>` publishes the Dart packages to pub.dev (`dart-release.yml`), `rust-v<version>` publishes the crates to crates.io (`rust-release.yml`). The C# binding is not published yet.
