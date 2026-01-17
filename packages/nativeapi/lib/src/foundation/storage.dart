/// Abstract interface for key-value storage, similar to Web Storage API.
///
/// This interface provides a simple key-value storage mechanism with support
/// for string keys and values. Implementations can provide different storage
/// backends (preferences, secure storage, etc.).
///
/// Example usage:
/// ```dart
/// // Using preferences
/// final storage = Preferences();
/// await storage.set('username', 'john_doe');
/// final username = storage.get('username');
/// print('Username: $username');
///
/// // Using secure storage
/// final secureStorage = SecureStorage();
/// await secureStorage.set('api_token', 'secret_token_123');
/// final token = secureStorage.get('api_token');
/// print('Token: $token');
///
/// // Check if key exists
/// if (storage.contains('username')) {
///   await storage.remove('username');
/// }
///
/// // Get all keys
/// final keys = storage.keys;
/// print('All keys: $keys');
///
/// // Clear all data
/// await storage.clear();
/// ```
abstract interface class Storage {
  /// Set a key-value pair.
  ///
  /// Parameters:
  /// - [key]: The key to set
  /// - [value]: The value to store
  ///
  /// Returns `true` if successful, `false` otherwise.
  bool set(String key, String value);

  /// Get the value for a given key.
  ///
  /// Parameters:
  /// - [key]: The key to retrieve
  /// - [defaultValue]: Default value if key doesn't exist (defaults to empty string)
  ///
  /// Returns the stored value or [defaultValue] if not found.
  String get(String key, [String defaultValue = '']);

  /// Remove a key-value pair.
  ///
  /// Parameters:
  /// - [key]: The key to remove
  ///
  /// Returns `true` if successful, `false` if key doesn't exist.
  bool remove(String key);

  /// Clear all key-value pairs.
  ///
  /// Returns `true` if successful, `false` otherwise.
  bool clear();

  /// Check if a key exists.
  ///
  /// Parameters:
  /// - [key]: The key to check
  ///
  /// Returns `true` if key exists, `false` otherwise.
  bool contains(String key);

  /// Get all keys.
  ///
  /// Returns a list of all keys in storage.
  List<String> get keys;

  /// Get the number of stored items.
  ///
  /// Returns the number of key-value pairs.
  int get size;

  /// Get all key-value pairs.
  ///
  /// Returns a map of all key-value pairs.
  Map<String, String> getAll();

  /// Dispose of resources associated with this storage instance.
  void dispose();
}
