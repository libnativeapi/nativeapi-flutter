// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

class Point {
  const Point({required this.x, required this.y});

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Point && other.x == x && other.y == y);

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Point(x: $x, y: $y)';

  factory Point.fromNative(c.native_point_t raw) => Point(x: raw.x, y: raw.y);

  /// Allocates the C form; free it with [freeNative].
  ffi.Pointer<c.native_point_t> allocNative() {
    final pointer = pkg_ffi.calloc<c.native_point_t>();
    pointer.ref.x = x;
    pointer.ref.y = y;
    return pointer;
  }

  static void freeNative(ffi.Pointer<c.native_point_t> pointer) {
    pkg_ffi.calloc.free(pointer);
  }
}

class Size {
  const Size({required this.width, required this.height});

  final double width;
  final double height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Size && other.width == width && other.height == height);

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'Size(width: $width, height: $height)';

  factory Size.fromNative(c.native_size_t raw) =>
      Size(width: raw.width, height: raw.height);

  /// Allocates the C form; free it with [freeNative].
  ffi.Pointer<c.native_size_t> allocNative() {
    final pointer = pkg_ffi.calloc<c.native_size_t>();
    pointer.ref.width = width;
    pointer.ref.height = height;
    return pointer;
  }

  static void freeNative(ffi.Pointer<c.native_size_t> pointer) {
    pkg_ffi.calloc.free(pointer);
  }
}

class Rectangle {
  const Rectangle({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Rectangle &&
          other.x == x &&
          other.y == y &&
          other.width == width &&
          other.height == height);

  @override
  int get hashCode => Object.hash(x, y, width, height);

  @override
  String toString() =>
      'Rectangle(x: $x, y: $y, width: $width, height: $height)';

  factory Rectangle.fromNative(c.native_rectangle_t raw) =>
      Rectangle(x: raw.x, y: raw.y, width: raw.width, height: raw.height);

  /// Allocates the C form; free it with [freeNative].
  ffi.Pointer<c.native_rectangle_t> allocNative() {
    final pointer = pkg_ffi.calloc<c.native_rectangle_t>();
    pointer.ref.x = x;
    pointer.ref.y = y;
    pointer.ref.width = width;
    pointer.ref.height = height;
    return pointer;
  }

  static void freeNative(ffi.Pointer<c.native_rectangle_t> pointer) {
    pkg_ffi.calloc.free(pointer);
  }
}
