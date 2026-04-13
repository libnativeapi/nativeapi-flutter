// =============================================================================
// Auto-generated Dart wrapper for: src/url_opener.h
// Generated wrapper from C++ API. Calls existing ffigen bindings.
// =============================================================================
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart' as pkgffi;
import 'package:nativeapi/src/foundation/cnativeapi_bindings_mixin.dart';

class UrlOpenResult {
  const UrlOpenResult({
    required this.success,
    required this.errorCode,
    required this.errorMessage,
  });
  final bool success;
  final UrlOpenErrorCode errorCode;
  final String errorMessage;

  factory UrlOpenResult.fromNative(native_url_open_result_t native) {
    return UrlOpenResult(
      success: native.success,
      errorCode: UrlOpenErrorCode.fromNativeValue(native.error_code),
      errorMessage: native.error_message == ffi.nullptr
          ? ''
          : native.error_message.cast<pkgffi.Utf8>().toDartString(),
    );
  }
}

enum UrlOpenErrorCode {
  none(0),
  invalidUrlEmpty(1),
  invalidUrlMissingScheme(2),
  invalidUrlUnsupportedScheme(3),
  unsupportedPlatform(4),
  invocationFailed(5);

  const UrlOpenErrorCode(this.nativeValue);

  final int nativeValue;

  static UrlOpenErrorCode fromNativeValue(int value) => switch (value) {
    0 => UrlOpenErrorCode.none,
    1 => UrlOpenErrorCode.invalidUrlEmpty,
    2 => UrlOpenErrorCode.invalidUrlMissingScheme,
    3 => UrlOpenErrorCode.invalidUrlUnsupportedScheme,
    4 => UrlOpenErrorCode.unsupportedPlatform,
    5 => UrlOpenErrorCode.invocationFailed,
    _ => throw ArgumentError('Unknown value for UrlOpenErrorCode: $value'),
  };
}

class UrlOpener with CNativeApiBindingsMixin {
  static final UrlOpener instance = UrlOpener._();

  UrlOpener._();
  bool get isSupported {
    return bindings.native_url_opener_is_supported();
  }

  UrlOpenResult open(String url) {
    final urlNative = url.toNativeUtf8().cast<ffi.Char>();
    try {
      final nativeValue = bindings.native_url_opener_open(urlNative);
      try {
        return UrlOpenResult.fromNative(nativeValue);
      } finally {
        final nativeValuePtr = pkgffi.malloc<native_url_open_result_t>();
        nativeValuePtr.ref = nativeValue;
        bindings.native_url_open_result_free(nativeValuePtr);
        pkgffi.malloc.free(nativeValuePtr);
      }
    } finally {
      pkgffi.malloc.free(urlNative.cast());
    }
  }
}
