# nativeapi-csharp

C# bindings for [libnativeapi](https://github.com/libnativeapi/nativeapi).

## Layout

```
src/
├── CNativeAPI/          # raw interop layer (assembly CNativeAPI)
│   ├── cxx_impl/        # the core C++ library, as a git submodule
│   ├── native/          # CMake wrapper building cxx_impl into the shared
│   │                    #   library (libnativeapi.dylib / .so / nativeapi.dll)
│   ├── generated/       # [generated] C struct mirrors, delegates, DllImports
│   └── NativeLibraryResolver.cs
└── NativeAPI/           # public API layer (assembly NativeAPI)
    └── *.cs             # [generated] idiomatic C# wrappers
examples/
├── DisplayExample/
└── PreferencesExample/
```

Files starting with `// AUTO-GENERATED. DO NOT EDIT.` are produced by the
workspace code generator (`./codegen` in the workspace repo); edit the C++
headers and regenerate instead of editing them. `CNativeAPI` mirrors the C ABI
one-to-one (C naming included, like Rust's `bindings.rs`); everything idiomatic
lives in `NativeAPI`.

## Build

```bash
# Managed assemblies + examples
dotnet build NativeAPI.slnx

# Native shared library (requires CMake >= 3.24)
cmake -S src/CNativeAPI/native -B build/native -DCMAKE_BUILD_TYPE=Release
cmake --build build/native
```

## Continuous integration

GitHub Actions runs on pushes and pull requests to `main`, with manual dispatch
available. It checks formatting and builds with .NET analyzers, then builds the
native library, managed libraries, examples, and xUnit tests on Linux, macOS, and
Windows. Tests load the actual native library via `NATIVEAPI_LIBRARY_PATH` and
verify Unicode preferences, collection marshalling, and handle disposal. Tests
use an isolated storage scope and do not open desktop windows.

The workflow installs the .NET 9 SDK for `.slnx` support and the .NET 8 runtime for
the current `net8.0` projects. Linux native builds require `libgtk-3-dev`,
`libx11-dev`, `libxi-dev`, CMake, and pkg-config.

```bash
dotnet format NativeAPI.slnx --verify-no-changes
dotnet build NativeAPI.slnx -c Release -warnaserror
# Set NATIVEAPI_LIBRARY_PATH to the built shared library before running tests.
dotnet test NativeAPI.slnx -c Release --no-build
```

## Run the examples

At runtime the binding resolves the native library through the standard .NET
probing paths; set `NATIVEAPI_LIBRARY_PATH` to point at an explicit build:

```bash
export NATIVEAPI_LIBRARY_PATH=$PWD/build/native/libnativeapi.dylib
dotnet run --project examples/DisplayExample
dotnet run --project examples/PreferencesExample
```

```csharp
using NativeAPI;

foreach (var display in DisplayManager.Shared.GetAll())
{
    Console.WriteLine($"{display.Name}: {display.Size.Width}x{display.Size.Height}");
}
```
