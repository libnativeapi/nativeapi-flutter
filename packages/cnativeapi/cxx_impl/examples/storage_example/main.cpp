#include <nativeapi.h>
#include <iostream>

using namespace nativeapi;

void DemoPreferences() {
  std::cout << "=== Preferences Demo ===" << std::endl;

  // Create preferences with custom scope
  Preferences prefs("my_app");

  // Store some values
  prefs.Set("username", "john_doe");
  prefs.Set("theme", "dark");
  prefs.Set("font_size", "14");

  // Retrieve values
  std::cout << "Username: " << prefs.Get("username") << std::endl;
  std::cout << "Theme: " << prefs.Get("theme") << std::endl;
  std::cout << "Font size: " << prefs.Get("font_size") << std::endl;

  // Check if key exists
  if (prefs.Contains("language")) {
    std::cout << "Language: " << prefs.Get("language") << std::endl;
  } else {
    std::cout << "Language not set, using default: " << prefs.Get("language", "en") << std::endl;
  }

  // Get all keys
  auto keys = prefs.GetKeys();
  std::cout << "\nAll keys (" << prefs.GetSize() << "):" << std::endl;
  for (const auto& key : keys) {
    std::cout << "  - " << key << ": " << prefs.Get(key) << std::endl;
  }

  // Remove a key
  std::cout << "\nRemoving 'font_size'..." << std::endl;
  prefs.Remove("font_size");
  std::cout << "Size after removal: " << prefs.GetSize() << std::endl;

  std::cout << std::endl;
}

void DemoSecureStorage() {
  std::cout << "=== Secure Storage Demo ===" << std::endl;

  // Check if secure storage is available
  if (!SecureStorage::IsAvailable()) {
    std::cout << "Secure storage is not available on this platform" << std::endl;
    return;
  }

  // Create secure storage with custom scope
  SecureStorage storage("my_app_secure");

  // Store sensitive data
  storage.Set("api_token", "sk-1234567890abcdef");
  storage.Set("encryption_key", "very_secret_key_12345");
  storage.Set("password", "super_secret_password");

  // Retrieve sensitive data
  std::cout << "API Token: " << storage.Get("api_token") << std::endl;
  std::cout << "Password: " << storage.Get("password") << std::endl;

  // Get all keys (values are encrypted at rest)
  auto keys = storage.GetKeys();
  std::cout << "\nStored secure items (" << storage.GetSize() << "):" << std::endl;
  for (const auto& key : keys) {
    std::cout << "  - " << key << ": [encrypted]" << std::endl;
  }

  // Check existence
  if (storage.Contains("api_token")) {
    std::cout << "\nAPI token is securely stored" << std::endl;
  }

  // Remove sensitive data
  std::cout << "\nRemoving 'password'..." << std::endl;
  storage.Remove("password");
  std::cout << "Size after removal: " << storage.GetSize() << std::endl;

  // Clear all (for cleanup in this demo)
  // storage.Clear();

  std::cout << std::endl;
}

void DemoStorageInterface() {
  std::cout << "=== Storage Interface Demo ===" << std::endl;

  // Use Storage interface polymorphically
  Storage* storage = new Preferences("polymorphic_test");

  storage->Set("test_key", "test_value");
  std::cout << "Stored via Storage interface: " << storage->Get("test_key") << std::endl;

  delete storage;

  std::cout << std::endl;
}

int main() {
  std::cout << "Storage Example - Web Storage-like API for C++" << std::endl;
  std::cout << "================================================" << std::endl;
  std::cout << std::endl;

  try {
    // Demo Preferences (plain text storage)
    DemoPreferences();

    // Demo SecureStorage (encrypted storage)
    DemoSecureStorage();

    // Demo polymorphic usage
    DemoStorageInterface();

    std::cout << "Done! Check your system's storage locations:" << std::endl;
    std::cout << "  - macOS: NSUserDefaults & Keychain" << std::endl;
    std::cout << "  - Windows: Registry & DPAPI" << std::endl;
    std::cout << "  - Linux: ~/.config/nativeapi & ~/.local/share/nativeapi" << std::endl;

  } catch (const std::exception& e) {
    std::cerr << "Error: " << e.what() << std::endl;
    return 1;
  }

  return 0;
}
