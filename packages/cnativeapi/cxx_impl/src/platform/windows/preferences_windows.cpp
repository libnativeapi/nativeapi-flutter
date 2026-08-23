#include <shlobj.h>
#include <windows.h>
#include <fstream>
#include <sstream>
#include "../../preferences.h"

namespace nativeapi {

class Preferences::Impl {
 public:
  explicit Impl(const std::string& scope) : scope_(scope) {
    // Create registry key path
    registry_path_ = "Software\\NativeAPI\\Preferences\\" + scope;
  }

  ~Impl() = default;

  bool Set(const std::string& key, const std::string& value) {
    HKEY hkey;
    LONG result = RegCreateKeyExA(HKEY_CURRENT_USER, registry_path_.c_str(), 0, NULL,
                                  REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, &hkey, NULL);

    if (result != ERROR_SUCCESS) {
      return false;
    }

    result =
        RegSetValueExA(hkey, key.c_str(), 0, REG_SZ, reinterpret_cast<const BYTE*>(value.c_str()),
                       static_cast<DWORD>(value.length() + 1));

    RegCloseKey(hkey);
    return result == ERROR_SUCCESS;
  }

  std::string Get(const std::string& key, const std::string& default_value) const {
    HKEY hkey;
    LONG result = RegOpenKeyExA(HKEY_CURRENT_USER, registry_path_.c_str(), 0, KEY_READ, &hkey);

    if (result != ERROR_SUCCESS) {
      return default_value;
    }

    char buffer[4096];
    DWORD buffer_size = sizeof(buffer);
    DWORD type;

    result = RegQueryValueExA(hkey, key.c_str(), NULL, &type, reinterpret_cast<BYTE*>(buffer),
                              &buffer_size);

    RegCloseKey(hkey);

    if (result == ERROR_SUCCESS && type == REG_SZ) {
      return std::string(buffer);
    }

    return default_value;
  }

  bool Remove(const std::string& key) {
    HKEY hkey;
    LONG result = RegOpenKeyExA(HKEY_CURRENT_USER, registry_path_.c_str(), 0, KEY_WRITE, &hkey);

    if (result != ERROR_SUCCESS) {
      return false;
    }

    result = RegDeleteValueA(hkey, key.c_str());
    RegCloseKey(hkey);

    return result == ERROR_SUCCESS;
  }

  bool Clear() {
    // Delete the entire registry key
    LONG result = RegDeleteTreeA(HKEY_CURRENT_USER, registry_path_.c_str());

    // Recreate empty key
    if (result == ERROR_SUCCESS) {
      HKEY hkey;
      RegCreateKeyExA(HKEY_CURRENT_USER, registry_path_.c_str(), 0, NULL, REG_OPTION_NON_VOLATILE,
                      KEY_WRITE, NULL, &hkey, NULL);
      RegCloseKey(hkey);
    }

    return result == ERROR_SUCCESS || result == ERROR_FILE_NOT_FOUND;
  }

  bool Contains(const std::string& key) const {
    HKEY hkey;
    LONG result = RegOpenKeyExA(HKEY_CURRENT_USER, registry_path_.c_str(), 0, KEY_READ, &hkey);

    if (result != ERROR_SUCCESS) {
      return false;
    }

    result = RegQueryValueExA(hkey, key.c_str(), NULL, NULL, NULL, NULL);
    RegCloseKey(hkey);

    return result == ERROR_SUCCESS;
  }

  std::vector<std::string> GetKeys() const {
    std::vector<std::string> keys;

    HKEY hkey;
    LONG result = RegOpenKeyExA(HKEY_CURRENT_USER, registry_path_.c_str(), 0, KEY_READ, &hkey);

    if (result != ERROR_SUCCESS) {
      return keys;
    }

    DWORD index = 0;
    char value_name[256];
    DWORD value_name_size;

    while (true) {
      value_name_size = sizeof(value_name);
      result = RegEnumValueA(hkey, index, value_name, &value_name_size, NULL, NULL, NULL, NULL);

      if (result == ERROR_NO_MORE_ITEMS) {
        break;
      }

      if (result == ERROR_SUCCESS) {
        keys.push_back(std::string(value_name));
      }

      index++;
    }

    RegCloseKey(hkey);
    return keys;
  }

  size_t GetSize() const { return GetKeys().size(); }

  std::map<std::string, std::string> GetAll() const {
    std::map<std::string, std::string> result;
    auto keys = GetKeys();

    for (const auto& key : keys) {
      result[key] = Get(key, "");
    }

    return result;
  }

  const std::string& GetScope() const { return scope_; }

 private:
  std::string scope_;
  std::string registry_path_;
};

// Constructor implementations
Preferences::Preferences() : Preferences("default") {}

Preferences::Preferences(const std::string& scope) : pimpl_(std::make_unique<Impl>(scope)) {}

Preferences::~Preferences() = default;

// Interface implementation
bool Preferences::Set(const std::string& key, const std::string& value) {
  return pimpl_->Set(key, value);
}

std::string Preferences::Get(const std::string& key, const std::string& default_value) const {
  return pimpl_->Get(key, default_value);
}

bool Preferences::Remove(const std::string& key) {
  return pimpl_->Remove(key);
}

bool Preferences::Clear() {
  return pimpl_->Clear();
}

bool Preferences::Contains(const std::string& key) const {
  return pimpl_->Contains(key);
}

std::vector<std::string> Preferences::GetKeys() const {
  return pimpl_->GetKeys();
}

size_t Preferences::GetSize() const {
  return pimpl_->GetSize();
}

std::map<std::string, std::string> Preferences::GetAll() const {
  return pimpl_->GetAll();
}

std::string Preferences::GetScope() const {
  return pimpl_->GetScope();
}

}  // namespace nativeapi
