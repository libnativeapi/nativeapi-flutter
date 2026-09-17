# nativeapi-flutter

Flutter bindings for [nativeapi](https://github.com/libnativeapi/nativeapi) — unified access to native system APIs: windows, tray icons, menus, displays, keyboard, dialogs, storage and more.

| Android | iOS | Linux | macOS | Windows |
|:-------:|:---:|:-----:|:-----:|:-------:|
| ✅ | ✅ | ✅ | ✅ | ✅ |

🚧 **Work in Progress**: this package is under active development.

English | [简体中文](./README-ZH.md)

## Installation

```bash
flutter pub add nativeapi
```

## Quick Start

```dart
import 'package:nativeapi/nativeapi.dart';

for (final display in DisplayManager.instance.getAll()) {
  print('${display.name ?? ''}: ${display.size.width}x${display.size.height}');
}
```

### Custom window chrome

Wrap a custom title bar in `DragToMoveArea` to move the window by dragging (double tap to maximize/restore), and the window content in `DragToResizeArea` to resize from its edges and corners:

```dart
DragToResizeArea(
  resizeEdgeSize: 8,
  child: Column(
    children: [
      DragToMoveArea(
        child: SizedBox(height: 40, child: Center(child: Text('My window'))),
      ),
      Expanded(child: MyContent()),
    ],
  ),
)
```

Both widgets use `WindowManager.instance.getCurrent()` unless a `window` is passed. Moving via `DragToMoveArea` is not yet implemented on Linux.

## Examples

See [`examples/`](examples). Each directory is a Flutter app for one module:

```bash
flutter pub get
cd examples/display_example
flutter run
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

[MIT](./LICENSE)
