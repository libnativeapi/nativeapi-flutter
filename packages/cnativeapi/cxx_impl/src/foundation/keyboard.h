#pragma once

#include <cstdint>
#include <string>
#include "event.h"

namespace nativeapi {

/**
 * @brief Enumeration of keyboard modifier keys.
 *
 * Defines the various modifier keys that can be combined with regular keys
 * to create keyboard shortcuts and accelerators. Modifiers can be combined
 * using bitwise OR operations.
 */
enum class ModifierKey : uint32_t {
  /**
   * No modifier keys pressed.
   */
  None = 0,

  /**
   * Shift key modifier.
   */
  Shift = 1 << 0,

  /**
   * Control key modifier (Ctrl on Windows/Linux).
   */
  Ctrl = 1 << 1,

  /**
   * Alt key modifier (Option on macOS).
   */
  Alt = 1 << 2,

  /**
   * Meta key modifier (Windows key on Windows, Command key on macOS, Super on Linux).
   */
  Meta = 1 << 3,

  /**
   * Function key modifier (Fn key, typically on laptops).
   */
  Fn = 1 << 4,

  /**
   * Caps Lock state indicator.
   */
  CapsLock = 1 << 5,

  /**
   * Num Lock state indicator.
   */
  NumLock = 1 << 6,

  /**
   * Scroll Lock state indicator.
   */
  ScrollLock = 1 << 7
};

/**
 * @brief Bitwise OR operator for combining ModifierKey values.
 *
 * Allows combining multiple modifier keys using the | operator.
 *
 * @param a First modifier key
 * @param b Second modifier key
 * @return Combined modifier keys
 *
 * @example
 * ```cpp
 * auto modifiers = ModifierKey::Ctrl | ModifierKey::Shift;
 * ```
 */
inline ModifierKey operator|(ModifierKey a, ModifierKey b) {
  return static_cast<ModifierKey>(static_cast<uint32_t>(a) | static_cast<uint32_t>(b));
}

/**
 * @brief Bitwise AND operator for checking ModifierKey values.
 *
 * Allows checking if specific modifier keys are present using the & operator.
 *
 * @param a First modifier key
 * @param b Second modifier key
 * @return Intersection of modifier keys
 *
 * @example
 * ```cpp
 * if ((modifiers & ModifierKey::Ctrl) != ModifierKey::None) {
 *     // Ctrl is pressed
 * }
 * ```
 */
inline ModifierKey operator&(ModifierKey a, ModifierKey b) {
  return static_cast<ModifierKey>(static_cast<uint32_t>(a) & static_cast<uint32_t>(b));
}

/**
 * @brief Bitwise OR assignment operator for ModifierKey values.
 *
 * Allows accumulating modifier keys using the |= operator.
 *
 * @param a Modifier key to modify
 * @param b Modifier key to add
 * @return Reference to the modified modifier key
 *
 * @example
 * ```cpp
 * ModifierKey modifiers = ModifierKey::Ctrl;
 * modifiers |= ModifierKey::Shift;
 * ```
 */
inline ModifierKey& operator|=(ModifierKey& a, ModifierKey b) {
  a = a | b;
  return a;
}

/**
 * @brief Keyboard accelerator for menu items and shortcuts.
 *
 * Represents a keyboard shortcut that can trigger a menu item or action.
 * Supports modifier keys and regular keys in a platform-independent way.
 */
struct KeyboardAccelerator {
  /**
   * Combination of modifier flags.
   */
  ModifierKey modifiers = ModifierKey::None;

  /**
   * The main key code (e.g., 'A', 'F1', etc.).
   */
  std::string key;

  /**
   * Constructor for creating keyboard accelerators.
   *
   * @param key The main key (e.g., "A", "F1", "Enter")
   * @param modifiers Combination of modifier flags
   *
   * @example
   * ```cpp
   * // Ctrl+S
   * KeyboardAccelerator save_accel("S", ModifierKey::Ctrl);
   *
   * // Ctrl+Shift+N
   * KeyboardAccelerator new_accel("N",
   *     ModifierKey::Ctrl | ModifierKey::Shift);
   * ```
   */
  KeyboardAccelerator(const std::string& key = "", ModifierKey modifiers = ModifierKey::None)
      : key(key), modifiers(modifiers) {}

  /**
   * Get a human-readable string representation of the accelerator.
   *
   * @return String representation like "Ctrl+S" or "Alt+F4"
   */
  std::string ToString() const;

  /**
   * Check if this accelerator is empty (no key specified).
   *
   * @return true if no key is specified, false otherwise
   */
  bool IsEmpty() const { return key.empty(); }

  /**
   * Equality comparison operator.
   *
   * @param other The other accelerator to compare with
   * @return true if both accelerators are equal, false otherwise
   */
  bool operator==(const KeyboardAccelerator& other) const {
    return modifiers == other.modifiers && key == other.key;
  }

  /**
   * Inequality comparison operator.
   *
   * @param other The other accelerator to compare with
   * @return true if accelerators are different, false otherwise
   */
  bool operator!=(const KeyboardAccelerator& other) const { return !(*this == other); }
};

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

/**
 * Base class for all keyboard-related events
 *
 * This class provides common functionality for keyboard events,
 * including access to the keycode that triggered the event.
 */
class KeyboardEvent : public Event {
 public:
  /**
   * Constructor for KeyboardEvent
   * @param keycode The keycode associated with this event
   */
  explicit KeyboardEvent(int keycode) : keycode_(keycode) {}

  /**
   * Virtual destructor
   */
  virtual ~KeyboardEvent() = default;

  /**
   * Get the keycode associated with this event
   * @return The keycode value
   */
  int GetKeycode() const { return keycode_; }

  /**
   * Get a string representation of the event type (for debugging)
   * Default implementation returns "KeyboardEvent"
   */
  std::string GetTypeName() const override { return "KeyboardEvent"; }

 private:
  int keycode_;
};

/**
 * Event class for key press
 *
 * This event is emitted when a key is pressed down.
 */
class KeyPressedEvent : public KeyboardEvent {
 public:
  explicit KeyPressedEvent(int keycode) : KeyboardEvent(keycode) {}

  /**
   * Get a string representation of the event type
   */
  std::string GetTypeName() const override { return "KeyPressedEvent"; }

  /**
   * Get the static type index for this event type
   */
};

/**
 * Event class for key release
 *
 * This event is emitted when a key is released.
 */
class KeyReleasedEvent : public KeyboardEvent {
 public:
  explicit KeyReleasedEvent(int keycode) : KeyboardEvent(keycode) {}

  /**
   * Get a string representation of the event type
   */
  std::string GetTypeName() const override { return "KeyReleasedEvent"; }

  /**
   * Get the static type index for this event type
   */
};

/**
 * Event class for modifier keys change
 *
 * This event is emitted when modifier keys (Ctrl, Alt, Shift, etc.) change state.
 */
class ModifierKeysChangedEvent : public KeyboardEvent {
 public:
  explicit ModifierKeysChangedEvent(uint32_t modifier_keys)
      : KeyboardEvent(0), modifier_keys_(modifier_keys) {}

  /**
   * Get the modifier keys state
   * @return The modifier keys bitmask
   */
  uint32_t GetModifierKeys() const { return modifier_keys_; }

  /**
   * Get a string representation of the event type
   */
  std::string GetTypeName() const override { return "ModifierKeysChangedEvent"; }

  /**
   * Get the static type index for this event type
   */

 private:
  uint32_t modifier_keys_;
};

}  // namespace nativeapi
