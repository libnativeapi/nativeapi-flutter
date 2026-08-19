// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;
import 'dart:ui';

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

enum Placement {
  top(0),
  topStart(1),
  topEnd(2),
  right(3),
  rightStart(4),
  rightEnd(5),
  bottom(6),
  bottomStart(7),
  bottomEnd(8),
  left(9),
  leftStart(10),
  leftEnd(11);

  const Placement(this.value);
  final int value;

  static Placement fromValue(int value) => switch (value) {
    0 => Placement.top,
    1 => Placement.topStart,
    2 => Placement.topEnd,
    3 => Placement.right,
    4 => Placement.rightStart,
    5 => Placement.rightEnd,
    6 => Placement.bottom,
    7 => Placement.bottomStart,
    8 => Placement.bottomEnd,
    9 => Placement.left,
    10 => Placement.leftStart,
    11 => Placement.leftEnd,
    _ => Placement.top,
  };

  c.native_placement_t get raw => c.native_placement_t.fromValue(value);
}

