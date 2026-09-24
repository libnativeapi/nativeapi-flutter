# nativeapi for Dart and Flutter

Dart and Flutter bindings for [nativeapi](https://github.com/libnativeapi/nativeapi-core) — unified access to native system APIs: windows, tray icons, menus, displays, keyboard, dialogs, storage and more.

| Android | iOS | Linux | macOS | Windows |
|:-------:|:---:|:-----:|:-----:|:-------:|
| ✅ | ✅ | ✅ | ✅ | ✅ |

🚧 **Work in Progress**: this package is under active development.

English | [简体中文](./README-ZH.md)

## Packages

| Package | What it is |
| --- | --- |
| [`nativeapi`](nativeapi) | The API: windows, tray icons, menus, displays, keyboard, dialogs, storage and more. Plain Dart, usable without Flutter. |
| [`cnativeapi`](cnativeapi) | Raw FFI bindings to core's C ABI; its build hook compiles core. Used by `nativeapi`. |
| [`nativeapi_flutter`](nativeapi_flutter) | For Flutter apps: re-exports `nativeapi` and adds widgets, `dart:ui` conversions and the multi-window bridge. |

## Installation

A Flutter app:

```bash
flutter pub add nativeapi_flutter
```

A Dart app (command line, or any other Dart host):

```bash
dart pub add nativeapi
```

`nativeapi` has its own `Point`, `Size`, `Rectangle` and `Color` types. `nativeapi_flutter` converts them to and from `dart:ui` (`window.bounds.toRect()`, `Offset(10, 20).toNative()`), and leaves out the nativeapi names that Flutter already uses (`Brightness`, `Color`, `Display`, `Image`, `ModifierKey`, `ShortcutManager`, `Size`); import `package:nativeapi/nativeapi.dart` with a prefix to name one of those.

## Quick Start

```dart
import 'package:nativeapi/nativeapi.dart';

for (final display in DisplayManager.instance.getAll()) {
  print('${display.name ?? ''}: ${display.size.width}x${display.size.height}');
}
```

### Custom window chrome

With `package:nativeapi_flutter/nativeapi_flutter.dart`, wrap a custom title bar in `DragToMoveArea` to move the window by dragging (double tap to maximize/restore), and the window content in `DragToResizeArea` to resize from its edges and corners:

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

### Flutter-rendered secondary windows

`Window.create()` opens a bare native window with no Flutter view in it. To render widgets in a second window, create it with Flutter's multi-window API and hand the controller to nativeapi:

```dart
import 'package:flutter/src/foundation/_features.dart' show isWindowingEnabled;
import 'package:flutter/src/widgets/_window.dart' as fw;
import 'package:nativeapi_flutter/nativeapi_flutter.dart';
import 'package:nativeapi_flutter/windowing.dart';

// Before WidgetsFlutterBinding.ensureInitialized(): stable has no
// `flutter config --enable-windowing`, so the app switches the API on itself.
isWindowingEnabled = true;

final controller = fw.RegularWindowController(
  size: const Size(320, 48),
  title: 'Toolbar',
);

// In the widget tree: fw.RegularWindow(controller: controller, child: ...)

final window = controller.nativeWindow; // a nativeapi Window, same id as WindowManager's
window?.titleBarStyle = TitleBarStyle.hidden;
window?.isAlwaysOnTop = true;
```

All windows share one engine and one isolate, so they talk to each other through ordinary Dart objects — no runner changes, no message channels. Flutter's multi-window API is experimental and internal to the framework, which is why the bridge lives in its own library, `package:nativeapi_flutter/windowing.dart`. It is written against the **stable** channel (checked with 3.47.5); stable does not offer `flutter config --enable-windowing`, so the examples set Flutter's internal `isWindowingEnabled` in `main()`. See [`floating_toolbar_example`](../../examples/flutter_floating_toolbar_example) for a child window built this way, and [`browser_tabs_example`](../../examples/flutter_browser_tabs_example) and [`detachable_window_example`](../../examples/flutter_detachable_window_example).

## Examples

The examples are the `flutter_*` directories in the repository's [`examples/`](../../examples). Each is a Flutter app for one module; they resolve through the pub workspace at the repository root:

```bash
flutter pub get          # at the repository root
cd examples/flutter_display_example
flutter run
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

[MIT](./LICENSE)
