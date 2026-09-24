# libnativeapi workspace

Aggregates all [libnativeapi](https://github.com/libnativeapi) repositories as git submodules, so cross-repo changes (core → codegen → bindings) can be made and tracked together. The binding code generator lives directly in this repo under `tools/codegen`.

## Repositories

| Submodule | Description |
| --- | --- |
| [core](https://github.com/libnativeapi/nativeapi) | C++ core library (`nativeapi`) |
| [bindings/flutter](https://github.com/libnativeapi/nativeapi-flutter) | Flutter binding (`nativeapi-flutter`) |
| [bindings/rust](https://github.com/libnativeapi/nativeapi-rust) | Rust binding (`nativeapi-rust`) |
| [bindings/csharp](https://github.com/libnativeapi/nativeapi-csharp) | C# binding (`nativeapi-csharp`) |

## Getting started

```bash
git clone --recursive git@github.com:libnativeapi/workspace.git
```

Already cloned without `--recursive`?

```bash
git submodule update --init
```

## Code generation

`tools/codegen` (in-repo, not a submodule) generates the C ABI and all language
bindings from the C++ headers in `core/`. Run it via the wrapper script:

```bash
./codegen         # full run: C ABI, then all bindings
./codegen check   # verify generated files are up to date (CI mode)
./codegen readme  # copy the shared README sections (tools/readme/) into every repo
./codegen sync    # after a core change: regenerate everything, bump each
                  #   binding's embedded core submodule, rerun bindgen/ffigen,
                  #   and commit core + bindings + workspace pointers
                  #   (add --push to also push, -m "..." for the core message)
```

See [tools/codegen/README.md](tools/codegen/README.md) for details.

## Common tasks

```bash
make status   # working-tree status of every submodule
make sync     # pull main in every submodule (fast-forward)
make bump     # stage updated submodule pointers for commit
```

Day-to-day development happens inside each submodule as if it were a standalone clone: commit and push from within the subdirectory as usual. The workspace repo only records snapshots — commit updated submodule pointers when the set of repos is in a known-good, compatible state.
