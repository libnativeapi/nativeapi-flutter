#pragma once

#include <memory>
#include "storage.h"

namespace nativeapi {

/**
 * @brief General-purpose key-value storage for application preferences.
 *
 * Similar to Web Storage's localStorage, this provides persistent storage
 * for non-sensitive application data. Data is stored in plain text.
 *
 * Platform implementations:
 * - Windows: Registry (HKEY_CURRENT_USER) or INI files
 * - macOS: NSUserDefaults
 * - Linux: Configuration files (XDG Base Directory)
 *
 * @warning Do not store sensitive data (passwords, tokens) here.
 *          Use SecureStorage for sensitive data.
 */
class Preferences : public Storage {
 public:
  /**
   * @brief Create preferences storage with default scope.
   *
   * Uses application name as scope if available.
   */
  Preferences();

  /**
   * @brief Create preferences storage with custom scope.
   *
   * @param scope Scope for isolating preferences
   */
  explicit Preferences(const std::string& scope);

  virtual ~Preferences();

  // Storage interface implementation
  bool Set(const std::string& key, const std::string& value) override;
  std::string Get(const std::string& key, const std::string& default_value = "") const override;
  bool Remove(const std::string& key) override;
  bool Clear() override;
  bool Contains(const std::string& key) const override;
  std::vector<std::string> GetKeys() const override;
  size_t GetSize() const override;
  std::map<std::string, std::string> GetAll() const override;

  /**
   * @brief Get the scope.
   *
   * @return The scope used for this preferences instance
   */
  std::string GetScope() const;

  // Prevent copying and moving
  Preferences(const Preferences&) = delete;
  Preferences& operator=(const Preferences&) = delete;
  Preferences(Preferences&&) = delete;
  Preferences& operator=(Preferences&&) = delete;

 private:
  class Impl;
  std::unique_ptr<Impl> pimpl_;
};

}  // namespace nativeapi
