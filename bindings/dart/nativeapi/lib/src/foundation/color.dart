// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

class Color {
  const Color({
    required this.r,
    required this.g,
    required this.b,
    required this.a,
  });

  final int r;
  final int g;
  final int b;
  final int a;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Color &&
          other.r == r &&
          other.g == g &&
          other.b == b &&
          other.a == a);

  @override
  int get hashCode => Object.hash(r, g, b, a);

  @override
  String toString() => 'Color(r: $r, g: $g, b: $b, a: $a)';

  factory Color.fromNative(c.native_color_t raw) =>
      Color(r: raw.r, g: raw.g, b: raw.b, a: raw.a);

  /// Allocates the C form; free it with [freeNative].
  ffi.Pointer<c.native_color_t> allocNative() {
    final pointer = pkg_ffi.calloc<c.native_color_t>();
    pointer.ref.r = r;
    pointer.ref.g = g;
    pointer.ref.b = b;
    pointer.ref.a = a;
    return pointer;
  }

  static void freeNative(ffi.Pointer<c.native_color_t> pointer) {
    pkg_ffi.calloc.free(pointer);
  }
}
