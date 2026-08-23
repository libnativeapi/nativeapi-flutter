#pragma once

#include <cstdint>
#include <memory>
#include <mutex>
#include <vector>

#include "id_allocator.h"

namespace nativeapi {

/**
 * @file handle_table.h
 * @brief Generational handle table backing every C ABI object handle.
 *
 * The ownership rules this implements are specified in the libnativeapi
 * workspace repo (specs/handle-ownership.md).
 *
 * A handle is an opaque 64-bit integer, never a pointer:
 *
 *     [ generation : 32 | slot index : 32 ]
 *
 * Resolving one checks three things — that the slot exists, that its generation
 * still matches, and that its type tag is the type the caller expects. Releasing
 * a handle clears the slot and bumps its generation, which invalidates every
 * outstanding handle to that slot at once.
 *
 * Why this shape:
 *
 *  - Handles cross into Dart and Swift, where finalizers run at unpredictable
 *    times. With raw pointers, use-after-free and double-free are a matter of
 *    when, not if. Here a stale handle fails a comparison instead of
 *    dereferencing freed memory.
 *  - The type tag turns handle confusion (passing a menu handle to a window
 *    function) from undefined behaviour into a clean error.
 *  - The table owns a shared_ptr, so Resolve() can hand back a strong reference
 *    that keeps the object alive for the duration of the call. That is what
 *    finally lets std::shared_ptr-based APIs cross the C ABI at all — the single
 *    biggest blocker on codegen coverage.
 */

using HandleValue = uint64_t;

/// Never refers to a live object. Slot generations start at 1, so a zeroed
/// handle can never collide with a real one.
constexpr HandleValue kInvalidHandle = 0;

class HandleTable {
 public:
  /**
   * @brief Process-wide table.
   *
   * A singleton for now, matching how the C ABI is structured. It is a Meyer's
   * singleton like the rest of the library; the explicit-lifetime work in
   * DESIGN_REVIEW §4.2 will fold this into the same Context as the others.
   */
  static HandleTable& GetInstance();

  /**
   * @brief Store a strong reference and return a fresh handle for it.
   *
   * @return kInvalidHandle if @p object is null.
   */
  template <typename T>
  HandleValue Insert(std::shared_ptr<T> object) {
    if (!object) {
      return kInvalidHandle;
    }
    return InsertErased(std::static_pointer_cast<void>(std::move(object)),
                        IdTypeTag<T>::value);
  }

  /**
   * @brief Look up a handle, returning a strong reference.
   *
   * The returned shared_ptr keeps the object alive even if another thread
   * releases the handle concurrently — which is precisely the guarantee the old
   * raw-pointer handles could not make.
   *
   * @return nullptr if the handle is stale, unknown, or refers to a different
   *         type than @p T.
   */
  template <typename T>
  std::shared_ptr<T> Resolve(HandleValue handle) const {
    auto erased = ResolveErased(handle, IdTypeTag<T>::value);
    if (!erased) {
      return nullptr;
    }
    // Safe: the type tag check above proves this slot was filled by
    // Insert<T>(), so the stored pointer really is a T*.
    return std::static_pointer_cast<T>(std::move(erased));
  }

  /**
   * @brief Drop the table's reference and invalidate the handle.
   *
   * Idempotent by construction: releasing an already-released or bogus handle
   * returns false and does nothing. The object itself is destroyed only when the
   * last strong reference goes away, which may be later if a Resolve() result is
   * still in scope somewhere.
   *
   * @return true if this call released a live handle.
   */
  bool Release(HandleValue handle);

  /** @brief Whether @p handle currently resolves, ignoring type. */
  bool Contains(HandleValue handle) const;

  /** @brief Type tag stored for @p handle, or 0 if it does not resolve. */
  uint32_t GetTypeTag(HandleValue handle) const;

  /** @brief Number of live handles. Intended for tests and leak checks. */
  size_t LiveCount() const;

  // Handle encoding helpers, exposed for tests and diagnostics.
  static constexpr uint32_t SlotOf(HandleValue handle) {
    return static_cast<uint32_t>(handle & 0xFFFFFFFFull);
  }
  static constexpr uint32_t GenerationOf(HandleValue handle) {
    return static_cast<uint32_t>((handle >> 32) & 0xFFFFFFFFull);
  }
  static constexpr HandleValue Encode(uint32_t generation, uint32_t slot) {
    return (static_cast<HandleValue>(generation) << 32) | static_cast<HandleValue>(slot);
  }

 private:
  HandleTable() = default;
  HandleTable(const HandleTable&) = delete;
  HandleTable& operator=(const HandleTable&) = delete;

  struct Slot {
    /// Odd/even is not used; a slot is live iff `object` is non-null.
    /// Starts at 1 so that Encode(0, 0) == kInvalidHandle is unreachable.
    uint32_t generation = 1;
    uint32_t type_tag = 0;
    std::shared_ptr<void> object;
  };

  HandleValue InsertErased(std::shared_ptr<void> object, uint32_t type_tag);
  std::shared_ptr<void> ResolveErased(HandleValue handle, uint32_t type_tag) const;

  /// Caller must hold mutex_. Returns nullptr if the handle does not resolve.
  const Slot* FindLiveSlotLocked(HandleValue handle) const;

  mutable std::mutex mutex_;
  std::vector<Slot> slots_;
  std::vector<uint32_t> free_slots_;
};

}  // namespace nativeapi
