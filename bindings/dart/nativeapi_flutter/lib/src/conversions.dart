import 'dart:ui' as ui;

import 'package:nativeapi/nativeapi.dart' as na;

/// Converts a nativeapi [na.Point] to a Flutter [ui.Offset].
extension PointToOffset on na.Point {
  ui.Offset toOffset() => ui.Offset(x, y);
}

/// Converts a Flutter [ui.Offset] to a nativeapi [na.Point].
extension OffsetToNative on ui.Offset {
  na.Point toNative() => na.Point(x: dx, y: dy);
}

/// Converts a nativeapi [na.Size] to a Flutter [ui.Size].
extension NativeSizeToSize on na.Size {
  ui.Size toSize() => ui.Size(width, height);
}

/// Converts a Flutter [ui.Size] to a nativeapi [na.Size].
extension SizeToNative on ui.Size {
  na.Size toNative() => na.Size(width: width, height: height);
}

/// Converts a nativeapi [na.Rectangle] to a Flutter [ui.Rect].
extension RectangleToRect on na.Rectangle {
  ui.Rect toRect() => ui.Rect.fromLTWH(x, y, width, height);
}

/// Converts a Flutter [ui.Rect] to a nativeapi [na.Rectangle].
extension RectToNative on ui.Rect {
  na.Rectangle toNative() =>
      na.Rectangle(x: left, y: top, width: width, height: height);
}

/// Converts a nativeapi [na.Color] (8-bit channels) to a Flutter [ui.Color].
extension NativeColorToColor on na.Color {
  ui.Color toColor() => ui.Color.fromARGB(a, r, g, b);
}

/// Converts a Flutter [ui.Color] to a nativeapi [na.Color] (8-bit channels).
extension ColorToNative on ui.Color {
  na.Color toNative() => na.Color(
    r: (r * 255).round(),
    g: (g * 255).round(),
    b: (b * 255).round(),
    a: (a * 255).round(),
  );
}

/// Converts a nativeapi [na.Brightness] to a Flutter [ui.Brightness]; `system`
/// has no Flutter counterpart and gives null.
extension NativeBrightnessToBrightness on na.Brightness {
  ui.Brightness? toBrightness() => switch (this) {
    na.Brightness.light => ui.Brightness.light,
    na.Brightness.dark => ui.Brightness.dark,
    na.Brightness.system => null,
  };
}

/// Converts a Flutter [ui.Brightness] to a nativeapi [na.Brightness].
extension BrightnessToNative on ui.Brightness {
  na.Brightness toNative() => switch (this) {
    ui.Brightness.light => na.Brightness.light,
    ui.Brightness.dark => na.Brightness.dark,
  };
}
