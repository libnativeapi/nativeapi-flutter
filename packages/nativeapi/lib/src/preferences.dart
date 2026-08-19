// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;
import 'dart:ui';

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

final _bindings = c.cnativeApiBindings;

class Preferences {
  /// Adopts a handle returned by the C API and releases it when this
  /// object becomes unreachable.
  Preferences.fromHandle(this.nativeHandle) {
    _finalizer.attach(this, nativeHandle, detach: this);
  }

  /// Wraps a handle owned elsewhere; releasing it stays the owner's job.
  Preferences.borrowed(this.nativeHandle);

  /// The underlying handle-table entry.
  final int nativeHandle;

  static final Finalizer<int> _finalizer = Finalizer<int>(
    (handle) => _bindings.native_preferences_free(handle),
  );

  /// Releases the handle now instead of at collection.
  void dispose() {
    _finalizer.detach(this);
    _bindings.native_preferences_free(nativeHandle);
  }

  /// Creates a new `Preferences`; returns null if the native side failed.
  static Preferences? create() {
    final handle = _bindings.native_preferences_create();
    if (handle == 0) return null;
    return Preferences.fromHandle(handle);
  }

  /// Creates a new `Preferences`; returns null if the native side failed.
  static Preferences? createWithScope(String scope) {
    final scopeNative = scope.toNativeUtf8().cast<ffi.Char>();
    final handle = _bindings.native_preferences_create_with_scope(scopeNative);
    pkg_ffi.calloc.free(scopeNative);
    if (handle == 0) return null;
    return Preferences.fromHandle(handle);
  }

  bool set(String key, String value) {
    final keyNative = key.toNativeUtf8().cast<ffi.Char>();
    final valueNative = value.toNativeUtf8().cast<ffi.Char>();
    final result = _bindings.native_preferences_set(nativeHandle, keyNative, valueNative);
    pkg_ffi.calloc.free(keyNative);
    pkg_ffi.calloc.free(valueNative);
    return result;
  }

  String? get(String key, String defaultValue) {
    final keyNative = key.toNativeUtf8().cast<ffi.Char>();
    final defaultValueNative = defaultValue.toNativeUtf8().cast<ffi.Char>();
    final resultPointer = _bindings.native_preferences_get(nativeHandle, keyNative, defaultValueNative);
    pkg_ffi.calloc.free(keyNative);
    pkg_ffi.calloc.free(defaultValueNative);
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }

  bool remove(String key) {
    final keyNative = key.toNativeUtf8().cast<ffi.Char>();
    final result = _bindings.native_preferences_remove(nativeHandle, keyNative);
    pkg_ffi.calloc.free(keyNative);
    return result;
  }

  bool clear() {
    return _bindings.native_preferences_clear(nativeHandle);
  }

  bool contains(String key) {
    final keyNative = key.toNativeUtf8().cast<ffi.Char>();
    final result = _bindings.native_preferences_contains(nativeHandle, keyNative);
    pkg_ffi.calloc.free(keyNative);
    return result;
  }

  List<String> get keys {
    final list = _bindings.native_preferences_get_keys(nativeHandle);
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

  int get size {
    return _bindings.native_preferences_get_size(nativeHandle);
  }

  Map<String, String> get all {
    final raw = _bindings.native_preferences_get_all(nativeHandle);
    final entries = <String, String>{};
    for (var i = 0; i < raw.count; i++) {
      final key = raw.keys[i];
      if (key == ffi.nullptr) continue;
      final value = raw.values[i];
      entries[key.cast<pkg_ffi.Utf8>().toDartString()] = value == ffi.nullptr
          ? ''
          : value.cast<pkg_ffi.Utf8>().toDartString();
    }
    final rawPointer = pkg_ffi.calloc<c.native_string_map_t>();
    rawPointer.ref = raw;
    _bindings.native_string_map_free(rawPointer);
    pkg_ffi.calloc.free(rawPointer);
    return entries;
  }

  String? get scope {
    final resultPointer = _bindings.native_preferences_get_scope(nativeHandle);
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }

}

