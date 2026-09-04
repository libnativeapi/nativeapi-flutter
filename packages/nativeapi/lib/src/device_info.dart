// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;
import 'dart:ui';

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

final _bindings = c.cnativeApiBindings;

class DeviceInfo {
  const DeviceInfo._();

  /// The shared instance backed by the native singleton.
  static const DeviceInfo instance = DeviceInfo._();

  String? getName() {
    final resultPointer = _bindings.native_device_info_get_name();
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }

  String? getModel() {
    final resultPointer = _bindings.native_device_info_get_model();
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }

  String? getManufacturer() {
    final resultPointer = _bindings.native_device_info_get_manufacturer();
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }

  String? getOsName() {
    final resultPointer = _bindings.native_device_info_get_os_name();
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }

  String? getOsVersion() {
    final resultPointer = _bindings.native_device_info_get_os_version();
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }

  String? getKernelVersion() {
    final resultPointer = _bindings.native_device_info_get_kernel_version();
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }

  String? getArchitecture() {
    final resultPointer = _bindings.native_device_info_get_architecture();
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }

}

