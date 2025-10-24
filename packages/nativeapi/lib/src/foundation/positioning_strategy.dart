import 'dart:ffi';

import 'package:ffi/ffi.dart' as ffi;
import 'package:nativeapi/src/foundation/cnativeapi_bindings_mixin.dart';
import 'package:nativeapi/src/foundation/geometry.dart';

/// Type of positioning strategy.
enum PositioningStrategyType {
  /// Position at fixed screen coordinates.
  absolute,

  /// Position at current mouse cursor location.
  cursorPosition,

  /// Position relative to a rectangle.
  relative,
}

/// Strategy for determining where to position UI elements.
///
/// PositioningStrategy defines how to calculate the position for UI elements
/// such as menus, tooltips, or popovers. It supports various positioning modes:
/// - Absolute: Fixed screen coordinates
/// - CursorPosition: Current mouse cursor position
/// - Relative: Position relative to a rectangle
///
/// Example:
/// ```dart
/// // Position menu at absolute screen coordinates
/// menu.open(PositioningStrategy.absolute(Offset(100, 200)));
///
/// // Position menu at current mouse location
/// menu.open(PositioningStrategy.cursorPosition());
///
/// // Position menu relative to a rectangle with offset
/// final buttonRect = Rect.fromLTWH(10, 10, 100, 30);
/// menu.open(PositioningStrategy.relative(buttonRect, Offset(0, 10)));
/// ```
class PositioningStrategy with CNativeApiBindingsMixin {
  final PositioningStrategyType _type;
  final Offset? _absolutePosition;
  final Rect? _relativeRectangle;
  final Offset? _relativeOffset;

  PositioningStrategy._({
    required PositioningStrategyType type,
    Offset? absolutePosition,
    Rect? relativeRectangle,
    Offset? relativeOffset,
  }) : _type = type,
       _absolutePosition = absolutePosition,
       _relativeRectangle = relativeRectangle,
       _relativeOffset = relativeOffset;

  /// Create a strategy for absolute positioning at fixed coordinates.
  ///
  /// Example:
  /// ```dart
  /// final strategy = PositioningStrategy.absolute(Offset(100, 200));
  /// menu.open(strategy);
  /// ```
  factory PositioningStrategy.absolute(Offset point) {
    return PositioningStrategy._(
      type: PositioningStrategyType.absolute,
      absolutePosition: point,
    );
  }

  /// Create a strategy for positioning at current mouse location.
  ///
  /// Example:
  /// ```dart
  /// final strategy = PositioningStrategy.cursorPosition();
  /// contextMenu.open(strategy);
  /// ```
  factory PositioningStrategy.cursorPosition() {
    return PositioningStrategy._(type: PositioningStrategyType.cursorPosition);
  }

  /// Create a strategy for positioning relative to a rectangle.
  ///
  /// Example:
  /// ```dart
  /// final buttonRect = Rect.fromLTWH(10, 10, 100, 30);
  /// // Position at bottom of button (no offset)
  /// final strategy = PositioningStrategy.relative(buttonRect);
  /// menu.open(strategy);
  ///
  /// // Position at bottom of button with 10px vertical offset
  /// final strategy2 = PositioningStrategy.relative(buttonRect, Offset(0, 10));
  /// menu.open(strategy2);
  /// ```
  factory PositioningStrategy.relative(
    Rect rect, [
    Offset offset = Offset.zero,
  ]) {
    return PositioningStrategy._(
      type: PositioningStrategyType.relative,
      relativeRectangle: rect,
      relativeOffset: offset,
    );
  }

  /// Get the type of this positioning strategy.
  PositioningStrategyType get type => _type;

  /// Get the absolute position (for Absolute type).
  ///
  /// Only valid when type == PositioningStrategyType.absolute
  Offset? get absolutePosition => _absolutePosition;

  /// Get the relative rectangle (for Relative type).
  ///
  /// Only valid when type == PositioningStrategyType.relative
  Rect? get relativeRectangle => _relativeRectangle;

  /// Get the relative offset point (for Relative type).
  ///
  /// Only valid when type == PositioningStrategyType.relative
  Offset? get relativeOffset => _relativeOffset;

  /// Convert this strategy to a native positioning strategy handle.
  ///
  /// The caller is responsible for freeing the returned handle using
  /// native_positioning_strategy_free().
  native_positioning_strategy_t toNative() {
    switch (_type) {
      case PositioningStrategyType.absolute:
        final position = _absolutePosition;
        if (position == null) {
          throw StateError(
            'Absolute position is required for absolute strategy',
          );
        }
        final pointPtr = ffi.calloc<native_point_t>();
        pointPtr.ref.x = position.dx;
        pointPtr.ref.y = position.dy;

        final strategy = bindings.native_positioning_strategy_absolute(
          pointPtr,
        );

        ffi.calloc.free(pointPtr);
        return strategy;

      case PositioningStrategyType.cursorPosition:
        return bindings.native_positioning_strategy_cursor_position();

      case PositioningStrategyType.relative:
        final rect = _relativeRectangle;
        if (rect == null) {
          throw StateError(
            'Relative rectangle is required for relative strategy',
          );
        }
        final rectPtr = ffi.calloc<native_rectangle_t>();
        rectPtr.ref.x = rect.left;
        rectPtr.ref.y = rect.top;
        rectPtr.ref.width = rect.width;
        rectPtr.ref.height = rect.height;

        final offset = _relativeOffset;
        final offsetPtr = offset != null
            ? (ffi.calloc<native_point_t>()
                ..ref.x = offset.dx
                ..ref.y = offset.dy)
            : nullptr;

        final strategy = bindings.native_positioning_strategy_relative(
          rectPtr,
          offsetPtr.cast<native_point_t>(),
        );

        ffi.calloc.free(rectPtr);
        if (offsetPtr != nullptr) {
          ffi.calloc.free(offsetPtr);
        }

        return strategy;
    }
  }
}
