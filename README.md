# nativeapi

Unified access to native system APIs — windows, tray icons, menus, displays, keyboard, dialogs, storage and more — from Dart/Flutter, Rust, C#, JavaScript/TypeScript and Python, all built on one C++ core.

| Android | iOS | Linux | macOS | Windows |
|:-------:|:---:|:-----:|:-----:|:-------:|
| ✅ | ✅ | ✅ | ✅ | ✅ |

🚧 **Work in Progress**: the API is under active development.

This repository is the home of every binding: the Dart, Rust, C#, JS and Python bindings, the code generator, the design specs and the shared tooling live here directly, and the C++ core ([nativeapi-core](https://github.com/libnativeapi/nativeapi-core)) is checked out as a git submodule. A core change and its regenerated bindings (core → codegen → bindings) are made and tracked together.

## Bindings

| Binding | Packages | Status |
| --- | --- | --- |
| [Dart / Flutter](bindings/dart) | [`nativeapi`](https://pub.dev/packages/nativeapi), [`cnativeapi`](https://pub.dev/packages/cnativeapi) on pub.dev; `nativeapi_flutter` (not yet published) | published |
| [Rust](bindings/rust) | [`nativeapi`](https://crates.io/crates/nativeapi), [`cnativeapi`](https://crates.io/crates/cnativeapi) on crates.io | published |
| [C#](bindings/csharp) | `NativeAPI` | not yet on NuGet; build from source |
| [JavaScript / TypeScript](bindings/js) | `nativeapi` (Node-API addon for Node.js, Deno and Bun) | not yet on npm |
| [Python](bindings/python) | `nativeapi` (`ctypes`, Python 3.10+) | prototype, not yet on PyPI |

Each binding's README covers installation and usage.

## History

This repository was `nativeapi-flutter`, then `nativeapi-workspace`, and is now `nativeapi`; the old names redirect here, and its history, issues and stars carry over. The histories of the former `workspace`, `nativeapi-rust` and `nativeapi-csharp` repositories are merged in, so the Rust and C# bindings keep their full history under `bindings/`. The old `nativeapi-rust` and `nativeapi-csharp` repositories are archived.

## Layout

| Path | Description |
| --- | --- |
| [core](https://github.com/libnativeapi/nativeapi-core) | submodule: the C++ core library (`nativeapi-core`) |
| [bindings/dart](bindings/dart) | Dart binding (packages `nativeapi`, `cnativeapi`, `nativeapi_flutter`) |
| [bindings/rust](bindings/rust) | Rust binding (crates `nativeapi`, `cnativeapi`) |
| [bindings/csharp](bindings/csharp) | C# binding |
| [bindings/js](bindings/js) | JavaScript / TypeScript binding (Node-API addon) |
| [bindings/python](bindings/python) | Python binding (`ctypes`) |
| [examples](examples) | example apps of every binding, prefixed by binding: `flutter_*`, `rust_*`, `csharp_*`, `js_*`, `python_*`, … |
| [tools/codegen](tools/codegen) | the C ABI and binding generators |
| [specs](specs) | design rules for the core's public API |

## Getting started

```bash
git clone --recursive https://github.com/libnativeapi/nativeapi.git
```

Already cloned without `--recursive`?

```bash
git submodule update --init --recursive
```

The root `pubspec.yaml` is the pub workspace (and melos) root for the Dart packages and the Flutter examples, and the root `Cargo.toml` is the cargo workspace for the Rust crates and examples, so `flutter pub get` and `cargo build` run from the repository root. The C# solution is `bindings/csharp/NativeAPI.slnx`.

## Code generation

`tools/codegen` generates the C ABI and all language bindings from the C++ headers in `core/`. Run it via the wrapper script:

```bash
./codegen         # full run: C ABI, then all bindings
./codegen check   # verify generated files are up to date (CI mode)
./codegen readme  # copy the shared README sections (tools/readme/) into every README
./codegen sync    # after a core change: regenerate everything, rerun
                  #   bindgen/ffigen, and commit core, then this repo
                  #   (add --push to also push, -m "..." for the core message)
```

See [tools/codegen/README.md](tools/codegen/README.md) for details.

## Common tasks

```bash
make status   # working-tree status of this repo and the core submodule
make sync     # fast-forward core to origin/main
make bump     # stage the updated core pointer for commit
```

Work on the bindings, the tooling and the specs is committed here directly. Work inside `core` is committed and pushed from that subdirectory as if it were a standalone clone; this repository then records the updated pointer once the combination is known to be compatible.

## Issues

- API requests and native behavior bugs → [nativeapi-core issues](https://github.com/libnativeapi/nativeapi-core/issues)
- Bugs specific to one binding → [nativeapi issues](https://github.com/libnativeapi/nativeapi/issues)

## Releases

Each binding is released from a tag of its own: `v<version>` publishes the Dart packages to pub.dev (`dart-release.yml`), `rust-v<version>` publishes the crates to crates.io (`rust-release.yml`). The C#, JS and Python bindings are not published yet.

## License

MIT
