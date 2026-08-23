#pragma once

#include <atomic>
#include <cstdint>
#include <utility>

namespace nativeapi {

/**
 * @brief Compile-time type tag baked into every allocated ID.
 *
 * Deliberately left undefined in the primary template: a type must opt in by
 * specializing this, and calling IdAllocator::Allocate<T>() for an unregistered
 * T is a compile error rather than a silent runtime surprise.
 *
 * These values are stable identifiers, not arbitrary numbers. They appear in
 * the high bits of every ID handed out, and the handle-table work described in
 * DESIGN_REVIEW §P0-4 will use them to reject type-confused handles crossing
 * the C ABI. Therefore:
 *
 *   - NEVER renumber an existing entry.
 *   - Only append new entries.
 *   - Valid range is [kMinTypeValue, kMaxTypeValue].
 *
 * (Before this existed, tags were handed out by a runtime counter on a
 * first-call-wins basis, so the same C++ type could get a different tag from
 * one run to the next — useless for validating anything.)
 */
template <typename T>
struct IdTypeTag;

// Forward declarations for the registry below; each type's real definition
// lives in its own header.
class Display;
class Image;
class KeyboardMonitor;
class LaunchAtLogin;
class Menu;
class MenuItem;
class MessageDialog;
class PositioningStrategy;
class Preferences;
class SecureStorage;
class Shortcut;
class TrayIcon;
class Window;

// ---------------------------------------------------------------------------
// Type tag registry — append only.
// ---------------------------------------------------------------------------
template <>
struct IdTypeTag<Window> {
  static constexpr uint32_t value = 1;
};
template <>
struct IdTypeTag<Menu> {
  static constexpr uint32_t value = 2;
};
template <>
struct IdTypeTag<MenuItem> {
  static constexpr uint32_t value = 3;
};
template <>
struct IdTypeTag<TrayIcon> {
  static constexpr uint32_t value = 4;
};
template <>
struct IdTypeTag<Display> {
  static constexpr uint32_t value = 5;
};
template <>
struct IdTypeTag<Shortcut> {
  static constexpr uint32_t value = 6;
};
// Tags 7+ exist for the handle table rather than for IdAllocator: these types
// never allocate an ID of their own, but every type that crosses the C ABI as a
// handle needs a tag so the table can reject type-confused handles.
template <>
struct IdTypeTag<Image> {
  static constexpr uint32_t value = 7;
};
template <>
struct IdTypeTag<Preferences> {
  static constexpr uint32_t value = 8;
};
template <>
struct IdTypeTag<SecureStorage> {
  static constexpr uint32_t value = 9;
};
template <>
struct IdTypeTag<LaunchAtLogin> {
  static constexpr uint32_t value = 10;
};
template <>
struct IdTypeTag<MessageDialog> {
  static constexpr uint32_t value = 11;
};
template <>
struct IdTypeTag<PositioningStrategy> {
  static constexpr uint32_t value = 12;
};
template <>
struct IdTypeTag<KeyboardMonitor> {
  static constexpr uint32_t value = 13;
};

/**
 * Thread-safe ID allocator with type information.
 *
 * Each ID is a 32-bit value: [Type:8 bits][Sequence:24 bits]
 * Provides unique IDs for different object types with thread-safe allocation.
 *
 * ID Structure (32 bits):
 * +------------+--------------------------+
 * |  Type (8)  |    Sequence (24)         |
 * +------------+--------------------------+
 * Bits: 31-24     23-0
 *
 * Field Details:
 * - Type: 8-bit type identifier (1-255, 0 reserved for invalid), taken from the
 *   compile-time IdTypeTag<T> registry above — stable across runs.
 * - Sequence: 24-bit sequence number (1-16777215, 0 reserved for invalid)
 * - Invalid ID: 0x00000000 (both type and sequence are 0)
 *
 * Example:
 * - Type 1, Sequence 1: 0x01000001
 * - Type 2, Sequence 100: 0x02000064
 * - Type 5, Sequence 1000: 0x050003E8
 *
 * Thread Safety:
 * - All allocation operations are thread-safe using atomic operations
 * - Each type has its own independent sequence counter
 * - Type values are compile-time constants, so there is no assignment to race on
 */
class IdAllocator {
 public:
  using IdType = uint32_t;
  static_assert(sizeof(IdType) == 4, "IdAllocator::IdType must be 32-bit");

  /// Invalid ID value returned on allocation failure
  static constexpr IdType kInvalidId = 0u;

  /// Bit layout specification: [ type:8 | sequence:24 ]
  /// High 8 bits store the type identifier, low 24 bits store the sequence
  /// number
  static constexpr uint32_t kTypeBits = 8;       ///< Number of bits allocated for type information
  static constexpr uint32_t kSequenceBits = 24;  ///< Number of bits allocated for sequence numbers
  static constexpr uint32_t kTypeShift = 24;     ///< Bit shift amount to extract type from ID
  static constexpr uint32_t kTypeMask =
      0xFF000000u;  ///< Bit mask to extract type bits (high 8 bits)
  static constexpr uint32_t kSequenceMask =
      0x00FFFFFFu;  ///< Bit mask to extract sequence bits (low 24 bits)

  /// Valid type value range [1, 255] — the full width of the 8-bit type field.
  /// Type value 0 is reserved for invalid IDs (kInvalidId).
  ///
  /// This used to be capped at 10 for no structural reason, and exceeding it
  /// failed silently by returning kInvalidId. The field always had room for
  /// 255; the cap is simply gone now. Widening IdType itself was considered and
  /// rejected — it would ripple into native_*_id_t across the C ABI and all
  /// three language bindings to buy headroom nothing is close to needing.
  static constexpr uint32_t kMinTypeValue = 1u;    ///< Minimum valid type value
  static constexpr uint32_t kMaxTypeValue = 255u;  ///< Maximum valid type value

  /// Maximum number of unique IDs per type (2^24 - 1 = 16,777,215)
  /// Sequence 0 is reserved for invalid IDs, so maximum is kSequenceMask
  static constexpr uint32_t kMaxIdsPerType = kSequenceMask;

 private:
  /**
   * Gets the sequence counter for template type T.
   */
  template <typename T>
  static std::atomic<uint32_t>& GetCounter() {
    static std::atomic<uint32_t> counter{0};
    return counter;
  }

  /**
   * Gets the stable type value for template type T.
   *
   * Resolved entirely at compile time from the IdTypeTag<T> registry, so the
   * same type always yields the same value — across threads, across call
   * orders, and across runs.
   */
  template <typename T>
  static constexpr uint32_t GetTypeValue() {
    static_assert(IsValidType(IdTypeTag<T>::value),
                  "IdTypeTag<T>::value is outside [kMinTypeValue, kMaxTypeValue]. "
                  "Register the type in the tag registry in id_allocator.h.");
    return IdTypeTag<T>::value;
  }

 public:
  /**
   * Allocates a new unique ID for type T.
   * @return A unique ID, or kInvalidId if allocation failed.
   */
  template <typename T>
  static IdType Allocate() {
    // Stable, compile-time type value from the IdTypeTag<T> registry.
    // An unregistered type fails to compile rather than returning kInvalidId.
    constexpr uint32_t type_value = GetTypeValue<T>();

    // Atomically increment the sequence counter for this type and skip 0.
    // Using relaxed memory ordering is safe here because we only need
    // atomicity, not ordering guarantees between different operations. This
    // provides optimal performance while maintaining thread safety.
    uint32_t sequence = GetCounter<T>().fetch_add(1, std::memory_order_relaxed) + 1u;

    // Check for overflow: if sequence wraps around to 0 in the low 24 bits,
    // treat as allocation failure to avoid returning kInvalidId
    if ((sequence & kSequenceMask) == 0u) {
      // Sequence counter overflowed - this happens after 2^24 allocations
      // Return kInvalidId to indicate allocation failure
      return kInvalidId;
    }

    // Encode the ID: high 8 bits = type, low 24 bits = sequence
    // This creates a unique ID that encodes both type and sequence information
    return (type_value << kTypeShift) | (sequence & kSequenceMask);
  }

  /**
   * Attempts to allocate an ID, returning kInvalidId on failure.
   */
  template <typename T>
  static IdType TryAllocate() {
    return Allocate<T>();
  }

  // ID Query Methods

  /**
   * Extracts the type from an ID.
   */
  static uint32_t GetType(IdType id);

  /**
   * Extracts the sequence number from an ID.
   */
  static uint32_t GetSequence(IdType id);

  /**
   * Checks if an ID is valid.
   */
  static bool IsValid(IdType id);

  /**
   * Extracts both type and sequence from an ID.
   */
  static std::pair<uint32_t, uint32_t> Decompose(IdType id);

  // Counter Management

  /**
   * Gets the current sequence counter for type T.
   */
  template <typename T>
  static uint32_t GetCurrentCount() {
    return GetCounter<T>().load(std::memory_order_relaxed);
  }

  /**
   * Resets the sequence counter for type T.
   */
  template <typename T>
  static void Reset() {
    GetCounter<T>().store(0, std::memory_order_relaxed);
  }

  /**
   * Validates if a type value is within the valid range.
   */
  static constexpr bool IsValidType(uint32_t type_value) {
    return type_value >= kMinTypeValue && type_value <= kMaxTypeValue;
  }
};

}  // namespace nativeapi
