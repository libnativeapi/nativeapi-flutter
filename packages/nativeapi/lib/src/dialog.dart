// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;
import 'dart:ui';

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

enum DialogModality {
  none(0),
  application(1),
  window(2);

  const DialogModality(this.value);
  final int value;

  static DialogModality fromValue(int value) => switch (value) {
    0 => DialogModality.none,
    1 => DialogModality.application,
    2 => DialogModality.window,
    _ => DialogModality.none,
  };

  c.native_dialog_modality_t get raw => c.native_dialog_modality_t.fromValue(value);
}

