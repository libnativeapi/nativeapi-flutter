# nativeapi_flutter

Flutter integration for [nativeapi](https://pub.dev/packages/nativeapi): unified access to native system APIs — windows, tray icons, menus, displays, keyboard, dialogs, storage and more.

`nativeapi` itself is plain Dart. This package is what a Flutter app depends on: it re-exports `nativeapi` and adds

- widgets: `DragToMoveArea`, `DragToResizeArea`, `DragOutArea`, `DropRegion`, `ContextMenuRegion`;
- `ImageAsset.fromAsset()`, loading a nativeapi `Image` from a Flutter asset;
- conversions between nativeapi's value types and `dart:ui`'s: `point.toOffset()`, `size.toSize()`, `rectangle.toRect()`, `color.toColor()`, and `toNative()` on `Offset`, `Size`, `Rect`, `Color` and `Brightness`;
- `package:nativeapi_flutter/windowing.dart`, which bridges Flutter's experimental multi-window API to nativeapi windows.

## Installation

```bash
flutter pub add nativeapi_flutter
```

```dart
import 'package:nativeapi_flutter/nativeapi_flutter.dart';

final window = WindowManager.instance.getCurrent();
window?.contentSize = const Size(800, 600).toNative();
final Rect bounds = window!.bounds.toRect();
```

The nativeapi names that Flutter already uses are not re-exported: `Brightness`, `Color`, `Display`, `Image` and `Size` would shadow `dart:ui`'s, and `ModifierKey` and `ShortcutManager` would be ambiguous. To name one of them, also depend on `nativeapi` and import it with a prefix:

```dart
import 'package:nativeapi/nativeapi.dart' as na;

final List<na.Display> displays = DisplayManager.instance.getAll();
```

## License

[MIT](LICENSE)
