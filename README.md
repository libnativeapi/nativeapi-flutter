# nativeapi-csharp

C# bindings for [libnativeapi](https://github.com/libnativeapi/nativeapi).

## Layout

- `src/NativeAPI/` — the managed binding. Files starting with
  `// AUTO-GENERATED. DO NOT EDIT.` are produced by the workspace code
  generator (`./codegen` in the workspace repo); edit the C++ headers and
  regenerate instead of editing them.
- `cxx_impl/` — the core C++ library as a git submodule; the native code the
  bindings call into.
- `native/` — CMake wrapper that builds `cxx_impl` into the shared library
  (`libnativeapi.dylib` / `libnativeapi.so` / `nativeapi.dll`) the managed
  binding loads at runtime.

## Build

```bash
# Managed assembly
dotnet build src/NativeAPI

# Native shared library (requires CMake >= 3.24)
cmake -S native -B build/native -DCMAKE_BUILD_TYPE=Release
cmake --build build/native
```

At runtime the binding resolves the native library through the standard .NET
probing paths; set `NATIVEAPI_LIBRARY_PATH` to point at an explicit
`libnativeapi` build when it lives somewhere else.

```csharp
using NativeAPI;

foreach (var display in DisplayManager.Shared.GetAll())
{
    Console.WriteLine($"{display.Name}: {display.Size.Width}x{display.Size.Height}");
}
```
