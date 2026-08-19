// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;
import 'dart:ui';

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

final _bindings = c.cnativeApiBindings;

enum UrlOpenErrorCode {
  none(0),
  invalidUrlEmpty(1),
  invalidUrlMissingScheme(2),
  invalidUrlUnsupportedScheme(3),
  unsupportedPlatform(4),
  invocationFailed(5);

  const UrlOpenErrorCode(this.value);
  final int value;

  static UrlOpenErrorCode fromValue(int value) => switch (value) {
    0 => UrlOpenErrorCode.none,
    1 => UrlOpenErrorCode.invalidUrlEmpty,
    2 => UrlOpenErrorCode.invalidUrlMissingScheme,
    3 => UrlOpenErrorCode.invalidUrlUnsupportedScheme,
    4 => UrlOpenErrorCode.unsupportedPlatform,
    5 => UrlOpenErrorCode.invocationFailed,
    _ => UrlOpenErrorCode.none,
  };

  c.native_url_open_error_code_t get raw => c.native_url_open_error_code_t.fromValue(value);
}

class UrlOpenResult {
  const UrlOpenResult({required this.success, required this.errorCode, required this.errorMessage, });

  final bool success;
  final UrlOpenErrorCode errorCode;
  final String? errorMessage;

  factory UrlOpenResult.fromNative(c.native_url_open_result_t raw) => UrlOpenResult(
    success: raw.success,
    errorCode: UrlOpenErrorCode.fromValue(raw.error_code),
    errorMessage: raw.error_message == ffi.nullptr ? null : raw.error_message.cast<pkg_ffi.Utf8>().toDartString(),
  );

  /// Allocates the C form; free it with [freeNative].
  ffi.Pointer<c.native_url_open_result_t> allocNative() {
    final pointer = pkg_ffi.calloc<c.native_url_open_result_t>();
    pointer.ref.success = success;
    pointer.ref.error_code = errorCode.value;
    pointer.ref.error_message = errorMessage == null
        ? ffi.nullptr
        : errorMessage!.toNativeUtf8().cast<ffi.Char>();
    return pointer;
  }

  static void freeNative(ffi.Pointer<c.native_url_open_result_t> pointer) {
    if (pointer.ref.error_message != ffi.nullptr) {
      pkg_ffi.calloc.free(pointer.ref.error_message);
    }
    pkg_ffi.calloc.free(pointer);
  }
}

class UrlOpener {
  const UrlOpener._();

  /// The shared instance backed by the native singleton.
  static const UrlOpener instance = UrlOpener._();

  bool isSupported() {
    return _bindings.native_url_opener_is_supported();
  }

  bool canOpen(String url) {
    final urlNative = url.toNativeUtf8().cast<ffi.Char>();
    final result = _bindings.native_url_opener_can_open(urlNative);
    pkg_ffi.calloc.free(urlNative);
    return result;
  }

  UrlOpenResult open(String url) {
    final urlNative = url.toNativeUtf8().cast<ffi.Char>();
    final raw = _bindings.native_url_opener_open(urlNative);
    pkg_ffi.calloc.free(urlNative);
    final result = UrlOpenResult.fromNative(raw);
    final rawPointer = pkg_ffi.calloc<c.native_url_open_result_t>();
    rawPointer.ref = raw;
    _bindings.native_url_open_result_free(rawPointer);
    pkg_ffi.calloc.free(rawPointer);
    return result;
  }

}

