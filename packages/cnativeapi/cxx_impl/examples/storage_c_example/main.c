#include <nativeapi.h>
#include <stdio.h>
#include <stdlib.h>

void demo_preferences() {
  printf("=== Preferences C API Demo ===\n");

  // Create preferences with custom scope
  native_preferences_t prefs = native_preferences_create_with_scope("my_c_app");
  if (!prefs) {
    printf("Failed to create preferences\n");
    return;
  }

  // Store some values
  native_preferences_set(prefs, "username", "alice");
  native_preferences_set(prefs, "theme", "light");
  native_preferences_set(prefs, "font_size", "12");

  // Retrieve values
  char* username = native_preferences_get(prefs, "username", "");
  char* theme = native_preferences_get(prefs, "theme", "");
  char* font_size = native_preferences_get(prefs, "font_size", "");

  printf("Username: %s\n", username);
  printf("Theme: %s\n", theme);
  printf("Font size: %s\n", font_size);

  free_c_str(username);
  free_c_str(theme);
  free_c_str(font_size);

  // Check if key exists
  if (native_preferences_contains(prefs, "language")) {
    char* language = native_preferences_get(prefs, "language", "");
    printf("Language: %s\n", language);
    free_c_str(language);
  } else {
    char* default_lang = native_preferences_get(prefs, "language", "en");
    printf("Language not set, using default: %s\n", default_lang);
    free_c_str(default_lang);
  }

  // Get all keys
  native_string_list_t keys = native_preferences_get_keys(prefs);
  printf("\nAll keys (%ld):\n", keys.count);
  for (long i = 0; i < keys.count; i++) {
    char* value = native_preferences_get(prefs, keys.items[i], "");
    printf("  - %s: %s\n", keys.items[i], value);
    free_c_str(value);
  }
  native_string_list_free(&keys);

  // Get every entry in one call
  native_string_map_t all = native_preferences_get_all(prefs);
  printf("\nAll entries (%ld):\n", all.count);
  for (long i = 0; i < all.count; i++) {
    printf("  - %s = %s\n", all.keys[i], all.values[i]);
  }
  native_string_map_free(&all);

  // Get size
  unsigned long size = native_preferences_get_size(prefs);
  printf("Total items: %lu\n", size);

  // Remove a key
  printf("\nRemoving 'font_size'...\n");
  native_preferences_remove(prefs, "font_size");
  printf("Size after removal: %lu\n", native_preferences_get_size(prefs));

  // Get scope
  char* scope = native_preferences_get_scope(prefs);
  printf("Scope: %s\n", scope);
  free_c_str(scope);

  // Clean up
  native_preferences_free(prefs);

  printf("\n");
}

void demo_secure_storage() {
  printf("=== Secure Storage C API Demo ===\n");

  // Check if secure storage is available
  if (!native_secure_storage_is_available()) {
    printf("Secure storage is not available on this platform\n");
    return;
  }

  // Create secure storage with custom scope
  native_secure_storage_t storage = native_secure_storage_create_with_scope("my_c_app_secure");
  if (!storage) {
    printf("Failed to create secure storage\n");
    return;
  }

  // Store sensitive data
  native_secure_storage_set(storage, "api_key", "sk-c-api-1234567890");
  native_secure_storage_set(storage, "secret", "my_secret_value");
  native_secure_storage_set(storage, "token", "bearer_token_xyz");

  // Retrieve sensitive data
  char* api_key = native_secure_storage_get(storage, "api_key", "");
  char* secret = native_secure_storage_get(storage, "secret", "");

  printf("API Key: %s\n", api_key);
  printf("Secret: %s\n", secret);

  free_c_str(api_key);
  free_c_str(secret);

  // Get all keys
  native_string_list_t keys = native_secure_storage_get_keys(storage);
  printf("\nStored secure items (%ld):\n", keys.count);
  for (long i = 0; i < keys.count; i++) {
    printf("  - %s: [encrypted]\n", keys.items[i]);
  }
  native_string_list_free(&keys);

  // Check existence
  if (native_secure_storage_contains(storage, "api_key")) {
    printf("\nAPI key is securely stored\n");
  }

  // Get size
  unsigned long size = native_secure_storage_get_size(storage);
  printf("Total secure items: %lu\n", size);

  // Remove sensitive data
  printf("\nRemoving 'token'...\n");
  native_secure_storage_remove(storage, "token");
  printf("Size after removal: %lu\n", native_secure_storage_get_size(storage));

  // Get scope
  char* storage_scope = native_secure_storage_get_scope(storage);
  printf("Scope: %s\n", storage_scope);
  free_c_str(storage_scope);

  // Clean up (optional: clear all for this demo)
  // native_secure_storage_clear(storage);

  native_secure_storage_free(storage);

  printf("\n");
}

int main() {
  printf("Storage C API Example\n");
  printf("=====================\n\n");

  // Demo Preferences (plain text storage)
  demo_preferences();

  // Demo SecureStorage (encrypted storage)
  demo_secure_storage();

  printf("Done! Check your system's storage locations:\n");
  printf("  - macOS: NSUserDefaults & Keychain\n");
  printf("  - Windows: Registry & DPAPI\n");
  printf("  - Linux: ~/.config/nativeapi & ~/.local/share/nativeapi\n");

  return 0;
}
