// =============================================================================
// Auto-generated Dart wrapper for: src/url_opener.h
// Generated wrapper from C++ API. Calls existing ffigen bindings.
// =============================================================================

import 'dart:ffi' as ffi;
import 'dart:ui' as ui;
import 'package:ffi/ffi.dart' as pkgffi;
import 'package:cnativeapi/cnativeapi.dart';
import 'package:cnativeapi/src/bindings_generated.dart';
import 'package:nativeapi/src/foundation/cnativeapi_bindings_mixin.dart';
import 'package:nativeapi/src/foundation/native_handle_wrapper.dart';

class UrlOpenResult {
  const UrlOpenResult({
    required this.success,
    required this.errorCode,
    required this.errorMessage,
  });
  final bool success;
  final dynamic errorCode;
  final dynamic errorMessage;
}

enum UrlOpenErrorCode {
  none,
  invalidUrlEmpty,
  invalidUrlMissingScheme,
  invalidUrlUnsupportedScheme,
  unsupportedPlatform,
  invocationFailed,
}

class UrlOpener
    with CNativeApiBindingsMixin
    implements NativeHandleWrapper<native_url_opener_t> {
  late final native_url_opener_t _nativeHandle;

  UrlOpener([native_url_opener_t? nativeHandle]) {
    _nativeHandle = nativeHandle ?? bindings.native_url_opener_create();
  }

  @override
  native_url_opener_t get nativeHandle => _nativeHandle;
  bool get isSupported {
    return bindings.native_url_opener_is_supported(_nativeHandle);
  }

  dynamic open(dynamic url) {
    return bindings.native_url_opener_open(_nativeHandle, url);
  }

  @override
  void dispose() {
    // Generated wrappers are non-owning by default.
  }
}
