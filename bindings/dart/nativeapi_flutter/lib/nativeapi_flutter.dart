/// Flutter integration for nativeapi.
///
/// Re-exports `package:nativeapi` and adds the Flutter side: widgets, loading
/// an image from a Flutter asset, and conversions between nativeapi's value
/// types and `dart:ui`'s (`Offset`, `Size`, `Rect`, `Color`, `Brightness`).
///
/// A few nativeapi names are not re-exported because Flutter already uses
/// them: `Brightness`, `Color`, `Display`, `Image` and `Size` would silently
/// shadow `dart:ui`, and `ModifierKey` and `ShortcutManager` would be ambiguous
/// with Flutter's. Values of those types still work through this library (the
/// conversions below, `ImageAsset.fromAsset`); to name one, import
/// `package:nativeapi/nativeapi.dart` with a prefix:
///
/// ```dart
/// import 'package:nativeapi/nativeapi.dart' as na;
///
/// window.setMinimumSize(const na.Size(width: 400, height: 300));
/// ```
library;

export 'package:nativeapi/nativeapi.dart'
    hide Brightness, Color, Display, Image, ModifierKey, ShortcutManager, Size;

export 'src/conversions.dart';
export 'src/widgets/context_menu_region.dart';
export 'src/widgets/drag_out_area.dart';
export 'src/widgets/drag_to_move_area.dart';
export 'src/widgets/drag_to_resize_area.dart';
export 'src/widgets/drop_region.dart';
export 'src/widgets/image_asset.dart';
