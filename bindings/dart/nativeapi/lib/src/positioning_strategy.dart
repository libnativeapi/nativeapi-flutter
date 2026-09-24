// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

import 'foundation/geometry.dart';
import 'window.dart';

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

  c.native_positioning_strategy_type_t get raw =>
      c.native_positioning_strategy_type_t.fromValue(value);
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
    (handle) => c.native_positioning_strategy_free(handle),
  );

  /// Releases the handle now instead of at collection.
  void dispose() {
    _finalizer.detach(this);
    c.native_positioning_strategy_free(nativeHandle);
  }

  static PositioningStrategy? absolute(Point point) {
    final pointPointer = point.allocNative();
    final handle = c.native_positioning_strategy_absolute(pointPointer.ref);
    Point.freeNative(pointPointer);
    if (handle == 0) return null;
    return PositioningStrategy.fromHandle(handle);
  }

  static PositioningStrategy? cursorPosition() {
    final handle = c.native_positioning_strategy_cursor_position();
    if (handle == 0) return null;
    return PositioningStrategy.fromHandle(handle);
  }

  static PositioningStrategy? relativeWithRectAndOffset(
    Rectangle rect,
    Point offset,
  ) {
    final rectPointer = rect.allocNative();
    final offsetPointer = offset.allocNative();
    final handle = c.native_positioning_strategy_relative_with_rect_and_offset(
      rectPointer.ref,
      offsetPointer.ref,
    );
    Rectangle.freeNative(rectPointer);
    Point.freeNative(offsetPointer);
    if (handle == 0) return null;
    return PositioningStrategy.fromHandle(handle);
  }

  static PositioningStrategy? relativeWithWindowAndOffset(
    Window window,
    Point offset,
  ) {
    final offsetPointer = offset.allocNative();
    final handle = c
        .native_positioning_strategy_relative_with_window_and_offset(
          window.nativeHandle,
          offsetPointer.ref,
        );
    Point.freeNative(offsetPointer);
    if (handle == 0) return null;
    return PositioningStrategy.fromHandle(handle);
  }

  PositioningStrategyType get type {
    final raw = c.native_positioning_strategy_get_type(nativeHandle);
    return PositioningStrategyType.fromValue(raw.value);
  }

  Point get absolutePosition {
    final raw = c.native_positioning_strategy_get_absolute_position(
      nativeHandle,
    );
    return Point.fromNative(raw);
  }

  Rectangle get relativeRectangle {
    final raw = c.native_positioning_strategy_get_relative_rectangle(
      nativeHandle,
    );
    return Rectangle.fromNative(raw);
  }

  Point get relativeOffset {
    final raw = c.native_positioning_strategy_get_relative_offset(nativeHandle);
    return Point.fromNative(raw);
  }
}
