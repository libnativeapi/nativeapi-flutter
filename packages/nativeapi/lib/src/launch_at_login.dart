// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;
import 'dart:ui';

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

final _bindings = c.cnativeApiBindings;

class LaunchAtLogin {
  /// Adopts a handle returned by the C API and releases it when this
  /// object becomes unreachable.
  LaunchAtLogin.fromHandle(this.nativeHandle) {
    _finalizer.attach(this, nativeHandle, detach: this);
  }

  /// Wraps a handle owned elsewhere; releasing it stays the owner's job.
  LaunchAtLogin.borrowed(this.nativeHandle);

  /// The underlying handle-table entry.
  final int nativeHandle;

  static final Finalizer<int> _finalizer = Finalizer<int>(
    (handle) => _bindings.native_launch_at_login_free(handle),
  );

  /// Releases the handle now instead of at collection.
  void dispose() {
    _finalizer.detach(this);
    _bindings.native_launch_at_login_free(nativeHandle);
  }

  /// Creates a new `LaunchAtLogin`; returns null if the native side failed.
  static LaunchAtLogin? create() {
    final handle = _bindings.native_launch_at_login_create();
    if (handle == 0) return null;
    return LaunchAtLogin.fromHandle(handle);
  }

  /// Creates a new `LaunchAtLogin`; returns null if the native side failed.
  static LaunchAtLogin? createWithId(String id) {
    final idNative = id.toNativeUtf8().cast<ffi.Char>();
    final handle = _bindings.native_launch_at_login_create_with_id(idNative);
    pkg_ffi.calloc.free(idNative);
    if (handle == 0) return null;
    return LaunchAtLogin.fromHandle(handle);
  }

  /// Creates a new `LaunchAtLogin`; returns null if the native side failed.
  static LaunchAtLogin? createWithIdAndDisplayName(String id, String displayName) {
    final idNative = id.toNativeUtf8().cast<ffi.Char>();
    final displayNameNative = displayName.toNativeUtf8().cast<ffi.Char>();
    final handle = _bindings.native_launch_at_login_create_with_id_and_display_name(idNative, displayNameNative);
    pkg_ffi.calloc.free(idNative);
    pkg_ffi.calloc.free(displayNameNative);
    if (handle == 0) return null;
    return LaunchAtLogin.fromHandle(handle);
  }

  static bool isSupported() {
    return _bindings.native_launch_at_login_is_supported();
  }

  String? get id {
    final resultPointer = _bindings.native_launch_at_login_get_id(nativeHandle);
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }

  String? get displayName {
    final resultPointer = _bindings.native_launch_at_login_get_display_name(nativeHandle);
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }

  bool setDisplayName(String displayName) {
    final displayNameNative = displayName.toNativeUtf8().cast<ffi.Char>();
    final result = _bindings.native_launch_at_login_set_display_name(nativeHandle, displayNameNative);
    pkg_ffi.calloc.free(displayNameNative);
    return result;
  }

  bool setProgram(String executablePath, List<String> arguments) {
    final executablePathNative = executablePath.toNativeUtf8().cast<ffi.Char>();
    final argumentsItems = pkg_ffi.calloc<ffi.Pointer<ffi.Char>>(arguments.length);
    for (var i = 0; i < arguments.length; i++) {
      argumentsItems[i] = arguments[i].toNativeUtf8().cast<ffi.Char>();
    }
    final argumentsList = pkg_ffi.calloc<c.native_string_list_t>();
    argumentsList.ref.items = argumentsItems;
    argumentsList.ref.count = arguments.length;
    final result = _bindings.native_launch_at_login_set_program(nativeHandle, executablePathNative, argumentsList.ref);
    pkg_ffi.calloc.free(executablePathNative);
    for (var i = 0; i < arguments.length; i++) {
      pkg_ffi.calloc.free(argumentsItems[i]);
    }
    pkg_ffi.calloc.free(argumentsItems);
    pkg_ffi.calloc.free(argumentsList);
    return result;
  }

  String? get executablePath {
    final resultPointer = _bindings.native_launch_at_login_get_executable_path(nativeHandle);
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }

  List<String> get arguments {
    final list = _bindings.native_launch_at_login_get_arguments(nativeHandle);
    final items = <String>[];
    for (var i = 0; i < list.count; i++) {
      final item = list.items[i];
      if (item == ffi.nullptr) continue;
      items.add(item.cast<pkg_ffi.Utf8>().toDartString());
    }
    final listPointer = pkg_ffi.calloc<c.native_string_list_t>();
    listPointer.ref = list;
    _bindings.native_string_list_free(listPointer);
    pkg_ffi.calloc.free(listPointer);
    return items;
  }

  bool enable() {
    return _bindings.native_launch_at_login_enable(nativeHandle);
  }

  bool disable() {
    return _bindings.native_launch_at_login_disable(nativeHandle);
  }

  bool get isEnabled {
    return _bindings.native_launch_at_login_is_enabled(nativeHandle);
  }

}

