import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nativeapi/src/foundation/cnativeapi_bindings_mixin.dart';
import 'package:nativeapi/src/foundation/native_handle_wrapper.dart';
import 'package:nativeapi/src/foundation/storage.dart';

/// Platform-specific secure storage implementation.
///
/// Provides encrypted key-value storage using platform-native secure storage:
/// - Windows: Windows Credential Manager (DPAPI)
/// - macOS: Keychain Services
/// - Linux: Secret Service API (libsecret)
/// - Android: Android Keystore System
///
/// This class is designed for storing sensitive data like passwords, API tokens,
/// encryption keys, and other secrets. The data is encrypted at rest and protected
/// by the operating system's security mechanisms.
///
/// **Security Considerations:**
/// - Data is encrypted using platform-native encryption
/// - On macOS/iOS, data is stored in the Keychain
/// - On Windows, data is protected using DPAPI
/// - On Linux, data is stored using Secret Service (requires libsecret)
/// - On Android, data is encrypted using Android Keystore
///
/// Example:
/// ```dart
/// // Create secure storage with default scope
/// final storage = SecureStorage();
///
/// // Store sensitive data
/// storage.set('api_token', 'secret_token_abc123');
/// storage.set('password', 'user_password_here');
/// storage.set('encryption_key', 'base64_encoded_key');
///
/// // Retrieve sensitive data
/// final token = storage.get('api_token');
/// if (token.isNotEmpty) {
///   print('Token retrieved successfully');
/// }
///
/// // Check if secret exists
/// if (storage.contains('password')) {
///   final password = storage.get('password');
///   // Use password...
/// }
///
/// // Remove a secret
/// storage.remove('api_token');
///
/// // Clear all secrets (use with caution!)
/// storage.clear();
///
/// // Always dispose when done
/// storage.dispose();
/// ```
///
/// For scoped secure storage (e.g., per-user or per-service):
/// ```dart
/// final userStorage = SecureStorage.withScope('user_${userId}');
/// userStorage.set('refresh_token', 'token_xyz');
///
/// final apiStorage = SecureStorage.withScope('api_credentials');
/// apiStorage.set('client_secret', 'secret_123');
/// ```
///
/// **Important Notes:**
/// - Always call [dispose] when done to free native resources
/// - Do not store extremely large data (> 1KB) - secure storage is designed for small secrets
/// - Consider using [Preferences] for non-sensitive application settings
/// - On first use, the system may prompt the user for permission (especially on macOS)
class SecureStorage
    with CNativeApiBindingsMixin
    implements Storage, NativeHandleWrapper<native_secure_storage_t> {
  late final native_secure_storage_t _nativeHandle;

  /// Create a secure storage with default scope.
  SecureStorage() {
    _nativeHandle = bindings.native_secure_storage_create();
    if (_nativeHandle == nullptr) {
      throw Exception('Failed to create SecureStorage instance');
    }
  }

  /// Create a secure storage with custom scope.
  ///
  /// The [scope] parameter allows you to isolate secure storage for different
  /// purposes (e.g., different users, services, or security domains).
  ///
  /// On macOS, this corresponds to the Keychain service name.
  /// On Windows, this is part of the credential target name.
  /// On Linux, this is the Secret Service collection label.
  ///
  /// Example:
  /// ```dart
  /// final userStorage = SecureStorage.withScope('user_${userId}');
  /// final apiStorage = SecureStorage.withScope('api_service');
  /// ```
  SecureStorage.withScope(String scope) {
    final scopePtr = scope.toNativeUtf8().cast<Char>();
    _nativeHandle = bindings.native_secure_storage_create_with_scope(scopePtr);
    calloc.free(scopePtr);

    if (_nativeHandle == nullptr) {
      throw Exception(
        'Failed to create SecureStorage instance with scope: $scope',
      );
    }
  }

  @override
  native_secure_storage_t get nativeHandle => _nativeHandle;

  @override
  bool set(String key, String value) {
    final keyPtr = key.toNativeUtf8().cast<Char>();
    final valuePtr = value.toNativeUtf8().cast<Char>();

    final result = bindings.native_secure_storage_set(
      _nativeHandle,
      keyPtr,
      valuePtr,
    );

    calloc.free(keyPtr);
    calloc.free(valuePtr);

    return result;
  }

  @override
  String get(String key, [String defaultValue = '']) {
    final keyPtr = key.toNativeUtf8().cast<Char>();
    final defaultPtr = defaultValue.isNotEmpty
        ? defaultValue.toNativeUtf8().cast<Char>()
        : nullptr.cast<Char>();

    final resultPtr = bindings.native_secure_storage_get(
      _nativeHandle,
      keyPtr,
      defaultPtr,
    );

    calloc.free(keyPtr);
    if (defaultPtr != nullptr) {
      calloc.free(defaultPtr);
    }

    if (resultPtr == nullptr) {
      return defaultValue;
    }

    final result = resultPtr.cast<Utf8>().toDartString();
    bindings.native_secure_storage_free_string(resultPtr);

    return result;
  }

  @override
  bool remove(String key) {
    final keyPtr = key.toNativeUtf8().cast<Char>();
    final result = bindings.native_secure_storage_remove(_nativeHandle, keyPtr);
    calloc.free(keyPtr);
    return result;
  }

  @override
  bool clear() {
    return bindings.native_secure_storage_clear(_nativeHandle);
  }

  @override
  bool contains(String key) {
    final keyPtr = key.toNativeUtf8().cast<Char>();
    final result = bindings.native_secure_storage_contains(
      _nativeHandle,
      keyPtr,
    );
    calloc.free(keyPtr);
    return result;
  }

  @override
  List<String> get keys {
    final keysPtr = calloc<Pointer<Pointer<Char>>>();
    final countPtr = calloc<Size>();

    final success = bindings.native_secure_storage_get_keys(
      _nativeHandle,
      keysPtr,
      countPtr,
    );

    if (!success || keysPtr.value == nullptr) {
      calloc.free(keysPtr);
      calloc.free(countPtr);
      return [];
    }

    final count = countPtr.value;
    final List<String> result = [];

    for (int i = 0; i < count; i++) {
      final keyPtr = keysPtr.value.elementAt(i).value;
      if (keyPtr != nullptr) {
        result.add(keyPtr.cast<Utf8>().toDartString());
      }
    }

    bindings.native_secure_storage_free_string_array(keysPtr.value, count);
    calloc.free(keysPtr);
    calloc.free(countPtr);

    return result;
  }

  @override
  int get size {
    return bindings.native_secure_storage_get_size(_nativeHandle);
  }

  @override
  Map<String, String> getAll() {
    final keysPtr = calloc<Pointer<Pointer<Char>>>();
    final countPtr = calloc<Size>();

    final success = bindings.native_secure_storage_get_keys(
      _nativeHandle,
      keysPtr,
      countPtr,
    );

    if (!success || keysPtr.value == nullptr) {
      calloc.free(keysPtr);
      calloc.free(countPtr);
      return {};
    }

    final count = countPtr.value;
    final Map<String, String> result = {};

    for (int i = 0; i < count; i++) {
      final keyPtr = keysPtr.value.elementAt(i).value;
      if (keyPtr != nullptr) {
        final key = keyPtr.cast<Utf8>().toDartString();
        final value = get(key);
        result[key] = value;
      }
    }

    bindings.native_secure_storage_free_string_array(keysPtr.value, count);
    calloc.free(keysPtr);
    calloc.free(countPtr);

    return result;
  }

  @override
  void dispose() {
    if (_nativeHandle != nullptr) {
      bindings.native_secure_storage_destroy(_nativeHandle);
    }
  }
}
