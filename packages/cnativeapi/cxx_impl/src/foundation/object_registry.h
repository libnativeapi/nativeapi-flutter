/**
 * @file object_registry.h
 * @brief Thread-safe registry for mapping IDs to shared objects.
 *
 * This utility provides a minimal, lock-guarded container that stores
 * `std::shared_ptr<TObject>` instances keyed by `TId`. It is intended for
 * simple, centralized tracking of live objects (e.g., windows, menus) and
 * supports lookup, enumeration, removal, and clearing operations.
 *
 * Thread-safety:
 * - All public methods take a mutex to protect internal state.
 * - Methods marked `const` still acquire the mutex (via a `mutable` mutex)
 *   to ensure safe concurrent access while preserving the const interface.
 *
 * Requirements:
 * - `TId` must be hashable and equality comparable (usable as an
 *   `unordered_map` key).
 * - Objects are stored as `std::shared_ptr<TObject>`. The registry does not
 *   impose ownership semantics beyond holding shared references.
 */
#pragma once
#include <memory>
#include <mutex>
#include <unordered_map>
#include <vector>

namespace nativeapi {

template <typename TObject, typename TId>
class ObjectRegistry {
 public:
  /**
   * @brief Add or replace an object for the given ID.
   *
   * If an entry for `id` already exists, it is replaced by `object`.
   * This operation is O(1) average-case.
   *
   * @param id The identifier used as key in the registry.
   * @param object The object to store; moved into the registry.
   */
  void Add(TId id, std::shared_ptr<TObject> object) {
    std::lock_guard<std::mutex> lock(mutex_);
    objects_[id] = std::move(object);
  }

  /**
   * @brief Get the object associated with an ID.
   *
   * This operation is O(1) average-case.
   *
   * @param id The identifier to look up.
   * @return std::shared_ptr<TObject> The stored object if present,
   *         otherwise `nullptr`.
   */
  std::shared_ptr<TObject> Get(TId id) const {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = objects_.find(id);
    return it == objects_.end() ? nullptr : it->second;
  }

  /**
   * @brief Check if an object exists for the given ID.
   *
   * This operation is O(1) average-case.
   *
   * @param id The identifier to check.
   * @return true If an entry exists for the given ID.
   * @return false If no entry exists for the given ID.
   */
  bool Contains(TId id) const {
    std::lock_guard<std::mutex> lock(mutex_);
    return objects_.find(id) != objects_.end();
  }

  /**
   * @brief Get a snapshot vector of all stored objects.
   *
   * The returned vector contains strong references to the objects as they
   * existed at the moment of the call. Subsequent mutations to the registry
   * are not reflected in the returned vector.
   *
   * Complexity: O(N) to allocate and copy shared pointers.
   *
   * @return std::vector<std::shared_ptr<TObject>> Snapshot of all objects.
   */
  std::vector<std::shared_ptr<TObject>> GetAll() const {
    std::lock_guard<std::mutex> lock(mutex_);
    std::vector<std::shared_ptr<TObject>> result;
    result.reserve(objects_.size());
    for (const auto& kv : objects_) {
      result.push_back(kv.second);
    }
    return result;
  }

  /**
   * @brief Remove an object by ID.
   *
   * This operation is O(1) average-case.
   *
   * @param id The identifier to remove.
   * @return true If an entry was found and removed.
   * @return false If no entry existed for the given ID.
   */
  bool Remove(TId id) {
    std::lock_guard<std::mutex> lock(mutex_);
    return objects_.erase(id) > 0;
  }

  /**
   * @brief Remove all entries from the registry.
   *
   * Complexity: O(N) to destroy or release stored shared pointers.
   */
  void Clear() {
    std::lock_guard<std::mutex> lock(mutex_);
    objects_.clear();
  }

 private:
  // Mutex is mutable to allow locking in logically-const operations.
  mutable std::mutex mutex_;
  std::unordered_map<TId, std::shared_ptr<TObject>> objects_;
};

}  // namespace nativeapi
