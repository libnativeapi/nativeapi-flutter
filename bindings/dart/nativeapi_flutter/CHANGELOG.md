## Unreleased

* Holds the Flutter side of nativeapi, which is now a plain Dart package: the
  widgets (`DragToMoveArea`, `DragToResizeArea`, `DragOutArea`, `DropRegion`,
  `ContextMenuRegion`), `ImageAsset` and `package:nativeapi_flutter/windowing.dart`
  moved here from `nativeapi`.
* Conversions between nativeapi's `Point`, `Size`, `Rectangle`, `Color` and
  `Brightness` and `dart:ui`'s `Offset`, `Size`, `Rect`, `Color` and
  `Brightness`.
* The re-export of `package:nativeapi` leaves out `Brightness`, `Color`,
  `Display`, `Image`, `ModifierKey`, `ShortcutManager` and `Size`, which clash
  with Flutter's names.

## 0.3.1

* Initial release. It re-exports `package:nativeapi`.
