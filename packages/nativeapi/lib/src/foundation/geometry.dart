export 'dart:ui' show Offset, Size, Rect;

import 'package:cnativeapi/cnativeapi.dart' show native_placement_t;

/// Placement options for positioning UI elements relative to an anchor.
///
/// Placement defines how a UI element (such as a menu or popover) should be
/// positioned relative to a reference point or rectangle.
///
/// Example:
/// ```dart
/// // Position menu below the anchor, horizontally centered
/// menu.open(strategy, Placement.bottom);
///
/// // Position menu below the anchor, aligned to the left
/// menu.open(strategy, Placement.bottomStart);
///
/// // Position menu above the anchor, aligned to the right
/// menu.open(strategy, Placement.topEnd);
/// ```
enum Placement {
  /// Position above the anchor, horizontally centered.
  top,

  /// Position above the anchor, aligned to the start (left).
  topStart,

  /// Position above the anchor, aligned to the end (right).
  topEnd,

  /// Position to the right of the anchor, vertically centered.
  right,

  /// Position to the right of the anchor, aligned to the start (top).
  rightStart,

  /// Position to the right of the anchor, aligned to the end (bottom).
  rightEnd,

  /// Position below the anchor, horizontally centered.
  bottom,

  /// Position below the anchor, aligned to the start (left).
  bottomStart,

  /// Position below the anchor, aligned to the end (right).
  bottomEnd,

  /// Position to the left of the anchor, vertically centered.
  left,

  /// Position to the left of the anchor, aligned to the start (top).
  leftStart,

  /// Position to the left of the anchor, aligned to the end (bottom).
  leftEnd;

  /// Convert this Placement to a native placement enum value.
  native_placement_t toNative() {
    switch (this) {
      case Placement.top:
        return native_placement_t.NATIVE_PLACEMENT_TOP;
      case Placement.topStart:
        return native_placement_t.NATIVE_PLACEMENT_TOP_START;
      case Placement.topEnd:
        return native_placement_t.NATIVE_PLACEMENT_TOP_END;
      case Placement.right:
        return native_placement_t.NATIVE_PLACEMENT_RIGHT;
      case Placement.rightStart:
        return native_placement_t.NATIVE_PLACEMENT_RIGHT_START;
      case Placement.rightEnd:
        return native_placement_t.NATIVE_PLACEMENT_RIGHT_END;
      case Placement.bottom:
        return native_placement_t.NATIVE_PLACEMENT_BOTTOM;
      case Placement.bottomStart:
        return native_placement_t.NATIVE_PLACEMENT_BOTTOM_START;
      case Placement.bottomEnd:
        return native_placement_t.NATIVE_PLACEMENT_BOTTOM_END;
      case Placement.left:
        return native_placement_t.NATIVE_PLACEMENT_LEFT;
      case Placement.leftStart:
        return native_placement_t.NATIVE_PLACEMENT_LEFT_START;
      case Placement.leftEnd:
        return native_placement_t.NATIVE_PLACEMENT_LEFT_END;
    }
  }
}
