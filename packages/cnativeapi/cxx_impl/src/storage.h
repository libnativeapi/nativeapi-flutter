#pragma once

#include <map>
#include <string>
#include <vector>

namespace nativeapi {

/**
 * @brief Abstract interface for key-value storage, similar to Web Storage API.
 *
 * This interface provides a simple key-value storage mechanism with support
 * for string keys and values. Implementations can provide different storage
 * backends (preferences, secure storage, etc.).
 */
class Storage {
 public:
  virtual ~Storage() = default;

  /**
   * @brief Set a key-value pair.
   *
   * @param key The key to set
   * @param value The value to store
   * @return true if successful, false otherwise
   */
  virtual bool Set(const std::string& key, const std::string& value) = 0;

  /**
   * @brief Get the value for a given key.
   *
   * @param key The key to retrieve
   * @param default_value Default value if key doesn't exist
   * @return The stored value or default_value if not found
   */
  virtual std::string Get(const std::string& key, const std::string& default_value = "") const = 0;

  /**
   * @brief Remove a key-value pair.
   *
   * @param key The key to remove
   * @return true if successful, false if key doesn't exist
   */
  virtual bool Remove(const std::string& key) = 0;

  /**
   * @brief Clear all key-value pairs.
   *
   * @return true if successful, false otherwise
   */
  virtual bool Clear() = 0;

  /**
   * @brief Check if a key exists.
   *
   * @param key The key to check
   * @return true if key exists, false otherwise
   */
  virtual bool Contains(const std::string& key) const = 0;

  /**
   * @brief Get all keys.
   *
   * @return Vector of all keys in storage
   */
  virtual std::vector<std::string> GetKeys() const = 0;

  /**
   * @brief Get the number of stored items.
   *
   * @return Number of key-value pairs
   */
  virtual size_t GetSize() const = 0;

  /**
   * @brief Get all key-value pairs.
   *
   * @return Map of all key-value pairs
   */
  virtual std::map<std::string, std::string> GetAll() const = 0;
};

}  // namespace nativeapi
