# nativeapi-csharp

C# bindings for [nativeapi](https://github.com/libnativeapi/nativeapi-core) — unified access to native system APIs: windows, tray icons, menus, displays, keyboard, dialogs, storage and more.

| Linux | macOS | Windows |
|:-----:|:-----:|:-------:|
| ✅ | ✅ | ✅ |

🚧 **Work in Progress**: not yet published to NuGet.

## Installation

Clone with submodules, build the native library (CMake 3.24+; on Linux also `libgtk-3-dev libx11-dev libxi-dev`), and reference `src/NativeAPI/NativeAPI.csproj` from your project:

```bash
git clone --recursive https://github.com/libnativeapi/nativeapi-workspace.git
cd nativeapi-workspace/bindings/csharp
cmake -S src/CNativeAPI/native -B build/native -DCMAKE_BUILD_TYPE=Release
cmake --build build/native
dotnet build NativeAPI.slnx
```

At runtime, set `NATIVEAPI_LIBRARY_PATH` to the built library if it is not on the standard probing paths.

## Quick Start

```csharp
using System;
using NativeAPI;

foreach (var display in DisplayManager.Shared.GetAll())
{
    using (display)
    {
        Console.WriteLine($"{display.Name}: {display.Size.Width}x{display.Size.Height}");
    }
}
```

## Examples

The examples are the `csharp_*` directories in the repository's [`examples/`](../../examples); from this directory:

```bash
export NATIVEAPI_LIBRARY_PATH=$PWD/build/native/libnativeapi.dylib
dotnet run --project ../../examples/csharp_display_example
dotnet run --project ../../examples/csharp_preferences_example
```

## Contributing

Development happens in [nativeapi-workspace](https://github.com/libnativeapi/nativeapi-workspace), which holds every binding and the code generator and checks out the core library as a submodule:

```bash
git clone --recursive https://github.com/libnativeapi/nativeapi-workspace.git
```

Files marked `AUTO-GENERATED. DO NOT EDIT.` are generated from the C++ headers in [nativeapi](https://github.com/libnativeapi/nativeapi-core). To change the API, send a pull request there; maintainers regenerate the bindings.

- API requests and native behavior bugs → [nativeapi-core issues](https://github.com/libnativeapi/nativeapi-core/issues)
- Bugs specific to one binding → [nativeapi-workspace issues](https://github.com/libnativeapi/nativeapi-workspace/issues)
- Not sure → [nativeapi-core issues](https://github.com/libnativeapi/nativeapi-core/issues)

## License

MIT
