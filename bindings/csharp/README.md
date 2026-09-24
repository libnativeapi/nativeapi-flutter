# nativeapi-csharp

C# bindings for [nativeapi](https://github.com/libnativeapi/nativeapi) — unified access to native system APIs: windows, tray icons, menus, displays, keyboard, dialogs, storage and more.

| Linux | macOS | Windows |
|:-----:|:-----:|:-------:|
| ✅ | ✅ | ✅ |

🚧 **Work in Progress**: not yet published to NuGet.

## Installation

Clone with submodules, build the native library (CMake 3.24+; on Linux also `libgtk-3-dev libx11-dev libxi-dev`), and reference `src/NativeAPI/NativeAPI.csproj` from your project:

```bash
git clone --recursive https://github.com/libnativeapi/nativeapi-csharp.git
cd nativeapi-csharp
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

See [`examples/`](examples):

```bash
export NATIVEAPI_LIBRARY_PATH=$PWD/build/native/libnativeapi.dylib
dotnet run --project examples/DisplayExample
dotnet run --project examples/PreferencesExample
```

## Contributing

This repository is developed from the [workspace](https://github.com/libnativeapi/workspace), which checks out the core library, every binding and the code generator together:

```bash
git clone --recursive https://github.com/libnativeapi/workspace.git
```

Files marked `AUTO-GENERATED. DO NOT EDIT.` are generated from the C++ headers in [nativeapi](https://github.com/libnativeapi/nativeapi). To change the API, send a pull request there; maintainers regenerate the bindings.

- API requests and native behavior bugs → [nativeapi issues](https://github.com/libnativeapi/nativeapi/issues)
- Bugs specific to one binding → that binding's repository
- Not sure → [nativeapi issues](https://github.com/libnativeapi/nativeapi/issues)

## License

MIT
