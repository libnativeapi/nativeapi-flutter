// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;
import 'dart:ui';

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

final _bindings = c.cnativeApiBindings;

class AppInfo {
  const AppInfo._();

  /// The shared instance backed by the native singleton.
  static const AppInfo instance = AppInfo._();

  String? getName() {
    final resultPointer = _bindings.native_app_info_get_name();
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }

  String? getIdentifier() {
    final resultPointer = _bindings.native_app_info_get_identifier();
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }

  String? getVersion() {
    final resultPointer = _bindings.native_app_info_get_version();
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }

  String? getBuildNumber() {
    final resultPointer = _bindings.native_app_info_get_build_number();
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }

}

