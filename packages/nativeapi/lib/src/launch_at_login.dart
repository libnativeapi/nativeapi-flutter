// =============================================================================
// Auto-generated Dart wrapper for: launch_at_login.h
// Generated wrapper from C++ API. Calls existing ffigen bindings.
// =============================================================================
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart' as pkgffi;
import 'package:cnativeapi/cnativeapi.dart' show cnativeApiBindings;
import 'package:nativeapi/src/foundation/cnativeapi_bindings_mixin.dart';
import 'package:nativeapi/src/foundation/native_handle_wrapper.dart';

class LaunchAtLogin
    with CNativeApiBindingsMixin
    implements NativeHandleWrapper<native_launch_at_login_t> {
  late final native_launch_at_login_t _nativeHandle;
  final bool _ownsHandle;
  LaunchAtLogin({
    String? id,
    String? displayName,
    native_launch_at_login_t? nativeHandle,
  }) : _ownsHandle = nativeHandle == null {
    if (nativeHandle != null) {
      _nativeHandle = nativeHandle;
      return;
    }

    if (id != null && displayName != null) {
      final idNative = id.toNativeUtf8().cast<ffi.Char>();
      final displayNameNative = displayName.toNativeUtf8().cast<ffi.Char>();
      try {
        _nativeHandle = bindings.native_launch_at_login_create_with_id_and_name(
          idNative,
          displayNameNative,
        );
      } finally {
        pkgffi.malloc.free(displayNameNative);
        pkgffi.malloc.free(idNative);
      }
      return;
    }

    if (id != null) {
      final idNative = id.toNativeUtf8().cast<ffi.Char>();
      try {
        _nativeHandle = bindings.native_launch_at_login_create_with_id(
          idNative,
        );
      } finally {
        pkgffi.malloc.free(idNative);
      }
      return;
    }

    _nativeHandle = bindings.native_launch_at_login_create();
  }

  @override
  native_launch_at_login_t get nativeHandle => _nativeHandle;
  static bool get isSupported {
    return cnativeApiBindings.native_launch_at_login_is_supported();
  }

  String get id {
    final cString = bindings.native_launch_at_login_get_id(_nativeHandle);
    if (cString == ffi.nullptr) return '';
    final value = cString.cast<pkgffi.Utf8>().toDartString();
    bindings.free_c_str(cString);
    return value;
  }

  String get displayName {
    final cString = bindings.native_launch_at_login_get_display_name(
      _nativeHandle,
    );
    if (cString == ffi.nullptr) return '';
    final value = cString.cast<pkgffi.Utf8>().toDartString();
    bindings.free_c_str(cString);
    return value;
  }

  bool setDisplayName(String displayName) {
    final displayNameNative = displayName.toNativeUtf8().cast<ffi.Char>();
    try {
      return bindings.native_launch_at_login_set_display_name(
        _nativeHandle,
        displayNameNative,
      );
    } finally {
      pkgffi.malloc.free(displayNameNative);
    }
  }

  bool setProgram(String executablePath, List<String> arguments) {
    final executablePathNative = executablePath.toNativeUtf8().cast<ffi.Char>();
    final argumentsNative = arguments.isEmpty
        ? ffi.nullptr.cast<ffi.Pointer<ffi.Char>>()
        : pkgffi.malloc<ffi.Pointer<ffi.Char>>(arguments.length);
    try {
      for (var i = 0; i < arguments.length; i++) {
        argumentsNative[i] = arguments[i].toNativeUtf8().cast<ffi.Char>();
      }
      return bindings.native_launch_at_login_set_program(
        _nativeHandle,
        executablePathNative,
        argumentsNative,
        arguments.length,
      );
    } finally {
      for (var i = 0; i < arguments.length; i++) {
        pkgffi.malloc.free(argumentsNative[i]);
      }
      if (arguments.isNotEmpty) {
        pkgffi.malloc.free(argumentsNative);
      }
      pkgffi.malloc.free(executablePathNative);
    }
  }

  String get executablePath {
    final cString = bindings.native_launch_at_login_get_executable_path(
      _nativeHandle,
    );
    if (cString == ffi.nullptr) return '';
    final value = cString.cast<pkgffi.Utf8>().toDartString();
    bindings.free_c_str(cString);
    return value;
  }

  List<String> get arguments {
    final outArguments = pkgffi.malloc<ffi.Pointer<ffi.Pointer<ffi.Char>>>();
    final outCount = pkgffi.malloc<ffi.Size>();
    try {
      final success = bindings.native_launch_at_login_get_arguments(
        _nativeHandle,
        outArguments,
        outCount,
      );
      if (!success || outArguments.value == ffi.nullptr) {
        return <String>[];
      }

      final count = outCount.value;
      final nativeArguments = outArguments.value;
      final result = <String>[];
      for (var i = 0; i < count; i++) {
        final nativeArgument = nativeArguments[i];
        result.add(
          nativeArgument == ffi.nullptr
              ? ''
              : nativeArgument.cast<pkgffi.Utf8>().toDartString(),
        );
      }

      for (var i = 0; i < count; i++) {
        final nativeArgument = nativeArguments[i];
        if (nativeArgument != ffi.nullptr) {
          bindings.free_c_str(nativeArgument);
        }
      }
      pkgffi.malloc.free(nativeArguments);
      return result;
    } finally {
      pkgffi.malloc.free(outCount);
      pkgffi.malloc.free(outArguments);
    }
  }

  bool enable() {
    return bindings.native_launch_at_login_enable(_nativeHandle);
  }

  bool disable() {
    return bindings.native_launch_at_login_disable(_nativeHandle);
  }

  bool get isEnabled {
    return bindings.native_launch_at_login_is_enabled(_nativeHandle);
  }

  @override
  void dispose() {
    if (_ownsHandle) {
      bindings.native_launch_at_login_destroy(_nativeHandle);
    }
  }
}
