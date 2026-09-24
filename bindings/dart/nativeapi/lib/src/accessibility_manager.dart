// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

class AccessibilityManager {
  const AccessibilityManager._();

  /// The shared instance backed by the native singleton.
  static const AccessibilityManager instance = AccessibilityManager._();

  void enable() {
    c.native_accessibility_manager_enable();
  }

  bool isEnabled() {
    return c.native_accessibility_manager_is_enabled();
  }
}
