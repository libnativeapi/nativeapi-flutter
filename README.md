# libnativeapi workspace

The development home of the [libnativeapi](https://github.com/libnativeapi) project: the Flutter binding, the code generator, the design specs and the shared tooling live directly in this repository, while the C++ core and the Rust and C# bindings are git submodules. Cross-repo changes (core → codegen → bindings) are made and tracked together here.

This repository was `nativeapi-flutter` until 2026-09; its history, issues and stars carry over, and the former `workspace` repository's history is merged in.

## Layout

| Path | Description |
| --- | --- |
| [core](https://github.com/libnativeapi/nativeapi) | submodule: C++ core library (`nativeapi`) |
| [bindings/flutter](bindings/flutter) | Flutter binding (in this repository) |
| [bindings/rust](https://github.com/libnativeapi/nativeapi-rust) | submodule: Rust binding (`nativeapi-rust`) |
| [bindings/csharp](https://github.com/libnativeapi/nativeapi-csharp) | submodule: C# binding (`nativeapi-csharp`) |
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

## Code generation

`tools/codegen` generates the C ABI and all language bindings from the C++ headers in `core/`. Run it via the wrapper script:

```bash
./codegen         # full run: C ABI, then all bindings
./codegen check   # verify generated files are up to date (CI mode)
./codegen readme  # copy the shared README sections (tools/readme/) into every repo
./codegen sync    # after a core change: regenerate everything, bump each
                  #   binding's embedded core submodule, rerun bindgen/ffigen,
                  #   and commit core, the submodule bindings and this repo
                  #   (add --push to also push, -m "..." for the core message)
```

See [tools/codegen/README.md](tools/codegen/README.md) for details.

## Common tasks

```bash
make status   # working-tree status of this repo and every submodule
make sync     # pull main in every submodule (fast-forward)
make bump     # stage updated submodule pointers for commit
```

Work on the Flutter binding, the tooling and the specs is committed here directly. Work inside `core` or a submodule binding is committed and pushed from that subdirectory as if it were a standalone clone; this repository then records the updated submodule pointer once the combination is known to be compatible.
