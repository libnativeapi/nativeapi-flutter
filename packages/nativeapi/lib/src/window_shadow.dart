// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;
import 'dart:ui';

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

import 'foundation/color.dart';
import 'foundation/geometry.dart';

final _bindings = c.cnativeApiBindings;

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
    (handle) => _bindings.native_window_shadow_free(handle),
  );

  /// Releases the handle now instead of at collection.
  void dispose() {
    _finalizer.detach(this);
    _bindings.native_window_shadow_free(nativeHandle);
  }

  /// Creates a new `WindowShadow`; returns null if the native side failed.
  static WindowShadow? create() {
    final handle = _bindings.native_window_shadow_create();
    if (handle == 0) return null;
    return WindowShadow.fromHandle(handle);
  }

  set color(Color value) {
    final valuePointer = pkg_ffi.calloc<c.native_color_t>();
    valuePointer.ref.r = (value.r * 255).round();
    valuePointer.ref.g = (value.g * 255).round();
    valuePointer.ref.b = (value.b * 255).round();
    valuePointer.ref.a = (value.a * 255).round();
    _bindings.native_window_shadow_set_color(nativeHandle, valuePointer.ref);
    pkg_ffi.calloc.free(valuePointer);
  }

  Color get color {
    final raw = _bindings.native_window_shadow_get_color(nativeHandle);
    return Color.fromARGB(raw.a, raw.r, raw.g, raw.b);
  }

  bool setBlurRadius(double radius) {
    return _bindings.native_window_shadow_set_blur_radius(nativeHandle, radius);
  }

  double get blurRadius {
    return _bindings.native_window_shadow_get_blur_radius(nativeHandle);
  }

  bool setOffset(Offset offset) {
    final offsetPointer = pkg_ffi.calloc<c.native_point_t>();
    offsetPointer.ref.x = offset.dx;
    offsetPointer.ref.y = offset.dy;
    final result = _bindings.native_window_shadow_set_offset(
      nativeHandle,
      offsetPointer.ref,
    );
    pkg_ffi.calloc.free(offsetPointer);
    return result;
  }

  Offset get offset {
    final raw = _bindings.native_window_shadow_get_offset(nativeHandle);
    return Offset(raw.x, raw.y);
  }
}
