// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

import 'foundation/geometry.dart';

class WindowShape {
  /// Adopts a handle returned by the C API and releases it when this
  /// object becomes unreachable.
  WindowShape.fromHandle(this.nativeHandle) {
    _finalizer.attach(this, nativeHandle, detach: this);
  }

  /// Wraps a handle owned elsewhere; releasing it stays the owner's job.
  WindowShape.borrowed(this.nativeHandle);

  /// The underlying handle-table entry.
  final int nativeHandle;

  static final Finalizer<int> _finalizer = Finalizer<int>(
    (handle) => c.native_window_shape_free(handle),
  );

  /// Releases the handle now instead of at collection.
  void dispose() {
    _finalizer.detach(this);
    c.native_window_shape_free(nativeHandle);
  }

  /// Creates a new `WindowShape`; returns null if the native side failed.
  static WindowShape? create() {
    final handle = c.native_window_shape_create();
    if (handle == 0) return null;
    return WindowShape.fromHandle(handle);
  }

  bool addPoint(Point point) {
    final pointPointer = point.allocNative();
    final result = c.native_window_shape_add_point(
      nativeHandle,
      pointPointer.ref,
    );
    Point.freeNative(pointPointer);
    return result;
  }

  void clear() {
    c.native_window_shape_clear(nativeHandle);
  }

  int get pointCount {
    return c.native_window_shape_get_point_count(nativeHandle);
  }

  Point getPointAt(int index) {
    final raw = c.native_window_shape_get_point_at(nativeHandle, index);
    return Point.fromNative(raw);
  }
}
