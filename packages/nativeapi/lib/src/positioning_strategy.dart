// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;
import 'dart:ui';

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

import 'foundation/geometry.dart';
import 'window.dart';

final _bindings = c.cnativeApiBindings;

enum PositioningStrategyType {
  absolute(0),
  cursorPosition(1),
  relative(2);

  const PositioningStrategyType(this.value);
  final int value;

  static PositioningStrategyType fromValue(int value) => switch (value) {
    0 => PositioningStrategyType.absolute,
    1 => PositioningStrategyType.cursorPosition,
    2 => PositioningStrategyType.relative,
    _ => PositioningStrategyType.absolute,
  };

  c.native_positioning_strategy_type_t get raw => c.native_positioning_strategy_type_t.fromValue(value);
}

class PositioningStrategy {
  /// Adopts a handle returned by the C API and releases it when this
  /// object becomes unreachable.
  PositioningStrategy.fromHandle(this.nativeHandle) {
    _finalizer.attach(this, nativeHandle, detach: this);
  }

  /// Wraps a handle owned elsewhere; releasing it stays the owner's job.
  PositioningStrategy.borrowed(this.nativeHandle);

  /// The underlying handle-table entry.
  final int nativeHandle;

  static final Finalizer<int> _finalizer = Finalizer<int>(
    (handle) => _bindings.native_positioning_strategy_free(handle),
  );

  /// Releases the handle now instead of at collection.
  void dispose() {
    _finalizer.detach(this);
    _bindings.native_positioning_strategy_free(nativeHandle);
  }

  static PositioningStrategy? absolute(Offset point) {
    final pointPointer = pkg_ffi.calloc<c.native_point_t>();
    pointPointer.ref.x = point.dx;
    pointPointer.ref.y = point.dy;
    final handle = _bindings.native_positioning_strategy_absolute(pointPointer.ref);
    pkg_ffi.calloc.free(pointPointer);
    if (handle == 0) return null;
    return PositioningStrategy.fromHandle(handle);
  }

  static PositioningStrategy? cursorPosition() {
    final handle = _bindings.native_positioning_strategy_cursor_position();
    if (handle == 0) return null;
    return PositioningStrategy.fromHandle(handle);
  }

  static PositioningStrategy? relativeWithRectAndOffset(Rect rect, Offset offset) {
    final rectPointer = pkg_ffi.calloc<c.native_rectangle_t>();
    rectPointer.ref.x = rect.left;
    rectPointer.ref.y = rect.top;
    rectPointer.ref.width = rect.width;
    rectPointer.ref.height = rect.height;
    final offsetPointer = pkg_ffi.calloc<c.native_point_t>();
    offsetPointer.ref.x = offset.dx;
    offsetPointer.ref.y = offset.dy;
    final handle = _bindings.native_positioning_strategy_relative_with_rect_and_offset(rectPointer.ref, offsetPointer.ref);
    pkg_ffi.calloc.free(rectPointer);
    pkg_ffi.calloc.free(offsetPointer);
    if (handle == 0) return null;
    return PositioningStrategy.fromHandle(handle);
  }

  static PositioningStrategy? relativeWithWindowAndOffset(Window window, Offset offset) {
    final offsetPointer = pkg_ffi.calloc<c.native_point_t>();
    offsetPointer.ref.x = offset.dx;
    offsetPointer.ref.y = offset.dy;
    final handle = _bindings.native_positioning_strategy_relative_with_window_and_offset(window.nativeHandle, offsetPointer.ref);
    pkg_ffi.calloc.free(offsetPointer);
    if (handle == 0) return null;
    return PositioningStrategy.fromHandle(handle);
  }

  PositioningStrategyType get type {
    final raw = _bindings.native_positioning_strategy_get_type(nativeHandle);
    return PositioningStrategyType.fromValue(raw.value);
  }

  Offset get absolutePosition {
    final raw = _bindings.native_positioning_strategy_get_absolute_position(nativeHandle);
    return Offset(raw.x, raw.y);
  }

  Rect get relativeRectangle {
    final raw = _bindings.native_positioning_strategy_get_relative_rectangle(nativeHandle);
    return Rect.fromLTWH(raw.x, raw.y, raw.width, raw.height);
  }

  Offset get relativeOffset {
    final raw = _bindings.native_positioning_strategy_get_relative_offset(nativeHandle);
    return Offset(raw.x, raw.y);
  }

}

