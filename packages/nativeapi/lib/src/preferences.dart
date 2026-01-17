import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nativeapi/src/foundation/cnativeapi_bindings_mixin.dart';
import 'package:nativeapi/src/foundation/native_handle_wrapper.dart';
import 'package:nativeapi/src/foundation/storage.dart';

/// Platform-specific preferences storage implementation.
///
/// Provides persistent key-value storage using platform-native mechanisms:
/// - Windows: Registry or app settings
/// - macOS: NSUserDefaults
/// - Linux: GSettings or file-based storage
/// - Android: SharedPreferences
///
/// This class is suitable for storing non-sensitive application settings
/// and user preferences. For sensitive data like passwords or tokens,
/// use [SecureStorage] instead.
///
/// Example:
/// ```dart
/// // Create preferences with default scope
/// final prefs = Preferences();
///
/// // Store user preferences
/// prefs.set('theme', 'dark');
/// prefs.set('language', 'en');
/// prefs.set('notifications_enabled', 'true');
///
/// // Retrieve preferences
/// final theme = prefs.get('theme', 'light'); // Default to 'light'
/// print('Current theme: $theme');
///
/// // Check if preference exists
/// if (prefs.contains('language')) {
///   print('Language is set');
/// }
///
/// // Get all preferences
/// final allPrefs = prefs.getAll();
/// print('All preferences: $allPrefs');
///
/// // Remove a preference
/// prefs.remove('notifications_enabled');
///
/// // Clear all preferences
/// prefs.clear();
///
/// // Always dispose when done
/// prefs.dispose();
/// ```
///
/// For scoped preferences (e.g., per-user or per-feature):
/// ```dart
/// final userPrefs = Preferences.withScope('user_123');
/// userPrefs.set('last_login', DateTime.now().toIso8601String());
///
/// final featurePrefs = Preferences.withScope('feature_flags');
/// featurePrefs.set('new_ui_enabled', 'true');
/// ```
class Preferences
    with CNativeApiBindingsMixin
    implements Storage, NativeHandleWrapper<native_preferences_t> {
  late final native_preferences_t _nativeHandle;

  /// Create a preferences storage with default scope.
  Preferences() {
    _nativeHandle = bindings.native_preferences_create();
    if (_nativeHandle == nullptr) {
      throw Exception('Failed to create Preferences instance');
    }
  }

  /// Create a preferences storage with custom scope.
  ///
  /// The [scope] parameter allows you to isolate preferences for different
  /// purposes (e.g., different users, features, or modules).
  ///
  /// Example:
  /// ```dart
  /// final userPrefs = Preferences.withScope('user_${userId}');
  /// final appPrefs = Preferences.withScope('app_settings');
  /// ```
  Preferences.withScope(String scope) {
    final scopePtr = scope.toNativeUtf8().cast<Char>();
    _nativeHandle = bindings.native_preferences_create_with_scope(scopePtr);
    calloc.free(scopePtr);

    if (_nativeHandle == nullptr) {
      throw Exception(
        'Failed to create Preferences instance with scope: $scope',
      );
    }
  }

  @override
  native_preferences_t get nativeHandle => _nativeHandle;

  @override
  bool set(String key, String value) {
    final keyPtr = key.toNativeUtf8().cast<Char>();
    final valuePtr = value.toNativeUtf8().cast<Char>();

    final result = bindings.native_preferences_set(
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

    final resultPtr = bindings.native_preferences_get(
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
    bindings.native_preferences_free_string(resultPtr);

    return result;
  }

  @override
  bool remove(String key) {
    final keyPtr = key.toNativeUtf8().cast<Char>();
    final result = bindings.native_preferences_remove(_nativeHandle, keyPtr);
    calloc.free(keyPtr);
    return result;
  }

  @override
  bool clear() {
    return bindings.native_preferences_clear(_nativeHandle);
  }

  @override
  bool contains(String key) {
    final keyPtr = key.toNativeUtf8().cast<Char>();
    final result = bindings.native_preferences_contains(_nativeHandle, keyPtr);
    calloc.free(keyPtr);
    return result;
  }

  @override
  List<String> get keys {
    final keysPtr = calloc<Pointer<Pointer<Char>>>();
    final countPtr = calloc<Size>();

    final success = bindings.native_preferences_get_keys(
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

    bindings.native_preferences_free_string_array(keysPtr.value, count);
    calloc.free(keysPtr);
    calloc.free(countPtr);

    return result;
  }

  @override
  int get size {
    return bindings.native_preferences_get_size(_nativeHandle);
  }

  @override
  Map<String, String> getAll() {
    final keysPtr = calloc<Pointer<Pointer<Char>>>();
    final countPtr = calloc<Size>();

    final success = bindings.native_preferences_get_keys(
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

    bindings.native_preferences_free_string_array(keysPtr.value, count);
    calloc.free(keysPtr);
    calloc.free(countPtr);

    return result;
  }

  @override
  void dispose() {
    if (_nativeHandle != nullptr) {
      bindings.native_preferences_destroy(_nativeHandle);
    }
  }
}
