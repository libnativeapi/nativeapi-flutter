// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

import 'foundation/color.dart';
import 'foundation/geometry.dart';

class WindowShadow {
  /// Adopts a handle returned by the C API and releases it when this
  /// object becomes unreachable.
  WindowShadow.fromHandle(this.nativeHandle) {
    _finalizer.attach(this, nativeHandle, detach: this);
  }

  /// Wraps a handle owned elsewhere; releasing it stays the owner's job.
  WindowShadow.borrowed(this.nativeHandle);

  /// The underlying handle-table entry.
  final int nativeHandle;

  static final Finalizer<int> _finalizer = Finalizer<int>(
    (handle) => c.native_window_shadow_free(handle),
  );

  /// Releases the handle now instead of at collection.
  void dispose() {
    _finalizer.detach(this);
    c.native_window_shadow_free(nativeHandle);
  }

  /// Creates a new `WindowShadow`; returns null if the native side failed.
  static WindowShadow? create() {
    final handle = c.native_window_shadow_create();
    if (handle == 0) return null;
    return WindowShadow.fromHandle(handle);
  }

  set color(Color value) {
    final valuePointer = value.allocNative();
    c.native_window_shadow_set_color(nativeHandle, valuePointer.ref);
    Color.freeNative(valuePointer);
  }

  Color get color {
    final raw = c.native_window_shadow_get_color(nativeHandle);
    return Color.fromNative(raw);
  }

  bool setBlurRadius(double radius) {
    return c.native_window_shadow_set_blur_radius(nativeHandle, radius);
  }

  double get blurRadius {
    return c.native_window_shadow_get_blur_radius(nativeHandle);
  }

  bool setOffset(Point offset) {
    final offsetPointer = offset.allocNative();
    final result = c.native_window_shadow_set_offset(
      nativeHandle,
      offsetPointer.ref,
    );
    Point.freeNative(offsetPointer);
    return result;
  }

  Point get offset {
    final raw = c.native_window_shadow_get_offset(nativeHandle);
    return Point.fromNative(raw);
  }
}
