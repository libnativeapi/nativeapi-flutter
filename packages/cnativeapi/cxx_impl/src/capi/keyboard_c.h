// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#pragma once

#include <stdbool.h>
#include <stdint.h>

#include "common_c.h"

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
  NATIVE_MODIFIER_KEY_NONE = 0,
  NATIVE_MODIFIER_KEY_SHIFT = 1,
  NATIVE_MODIFIER_KEY_CTRL = 2,
  NATIVE_MODIFIER_KEY_ALT = 4,
  NATIVE_MODIFIER_KEY_META = 8,
  NATIVE_MODIFIER_KEY_FN = 16,
  NATIVE_MODIFIER_KEY_CAPS_LOCK = 32,
  NATIVE_MODIFIER_KEY_NUM_LOCK = 64,
  NATIVE_MODIFIER_KEY_SCROLL_LOCK = 128,
} native_modifier_key_t;

typedef struct {
  native_modifier_key_t modifiers;
  char* key;
} native_keyboard_accelerator_t;

/// Which concrete KeyboardEvent arrived.
typedef enum {
  NATIVE_KEYBOARD_EVENT_TYPE_KEY_PRESSED = 0,
  NATIVE_KEYBOARD_EVENT_TYPE_KEY_RELEASED = 1,
  NATIVE_KEYBOARD_EVENT_TYPE_MODIFIER_KEYS_CHANGED = 2,
} native_keyboard_event_type_t;

/// One KeyboardEvent, tagged by its concrete type.
///
/// Valid only for the duration of the callback: anything it points at
/// is released as soon as the callback returns. Copy what you need.
typedef struct {
  native_keyboard_event_type_t type;
  int keycode;
  union {
    struct {
      unsigned int modifier_keys;
    } modifier_keys_changed;
  } data;
} native_keyboard_event_t;

typedef void (*native_keyboard_event_callback_t)(const native_keyboard_event_t* event, void* user_data);

/// Caller owns the returned string; free it with free_c_str().
FFI_PLUGIN_EXPORT
char* native_keyboard_accelerator_to_string(native_keyboard_accelerator_t keyboard_accelerator);

FFI_PLUGIN_EXPORT
bool native_keyboard_accelerator_is_empty(native_keyboard_accelerator_t keyboard_accelerator);

/// Frees everything the struct owns.
FFI_PLUGIN_EXPORT
void native_keyboard_accelerator_free(native_keyboard_accelerator_t* value);

#ifdef __cplusplus
}
#endif

#ifdef __cplusplus
namespace nativeapi {
class KeyboardEvent;
}  // namespace nativeapi

/// Fills @p out from @p event. Returns false when the event is not one
/// of the concrete types the C ABI knows about.
bool to_c_keyboard_event(const nativeapi::KeyboardEvent& event, native_keyboard_event_t* out);
/// Releases everything to_c_keyboard_event() allocated.
void free_c_keyboard_event(native_keyboard_event_t* value);

#endif

#ifdef __cplusplus
#include "../foundation/keyboard.h"
#include "string_utils_c.h"

// Conversion helpers between these C types and their C++ originals.

inline native_modifier_key_t to_c_modifier_key(nativeapi::ModifierKey value);
inline nativeapi::ModifierKey to_cpp_modifier_key(native_modifier_key_t value);
inline native_keyboard_accelerator_t to_c_keyboard_accelerator(const nativeapi::KeyboardAccelerator& value);
inline nativeapi::KeyboardAccelerator to_cpp_keyboard_accelerator(const native_keyboard_accelerator_t& value);

inline native_modifier_key_t to_c_modifier_key(nativeapi::ModifierKey value) {
  switch (value) {
    case nativeapi::ModifierKey::None:
      return NATIVE_MODIFIER_KEY_NONE;
    case nativeapi::ModifierKey::Shift:
      return NATIVE_MODIFIER_KEY_SHIFT;
    case nativeapi::ModifierKey::Ctrl:
      return NATIVE_MODIFIER_KEY_CTRL;
    case nativeapi::ModifierKey::Alt:
      return NATIVE_MODIFIER_KEY_ALT;
    case nativeapi::ModifierKey::Meta:
      return NATIVE_MODIFIER_KEY_META;
    case nativeapi::ModifierKey::Fn:
      return NATIVE_MODIFIER_KEY_FN;
    case nativeapi::ModifierKey::CapsLock:
      return NATIVE_MODIFIER_KEY_CAPS_LOCK;
    case nativeapi::ModifierKey::NumLock:
      return NATIVE_MODIFIER_KEY_NUM_LOCK;
    case nativeapi::ModifierKey::ScrollLock:
      return NATIVE_MODIFIER_KEY_SCROLL_LOCK;
    default:
      return NATIVE_MODIFIER_KEY_NONE;
  }
}

inline nativeapi::ModifierKey to_cpp_modifier_key(native_modifier_key_t value) {
  switch (value) {
    case NATIVE_MODIFIER_KEY_NONE:
      return nativeapi::ModifierKey::None;
    case NATIVE_MODIFIER_KEY_SHIFT:
      return nativeapi::ModifierKey::Shift;
    case NATIVE_MODIFIER_KEY_CTRL:
      return nativeapi::ModifierKey::Ctrl;
    case NATIVE_MODIFIER_KEY_ALT:
      return nativeapi::ModifierKey::Alt;
    case NATIVE_MODIFIER_KEY_META:
      return nativeapi::ModifierKey::Meta;
    case NATIVE_MODIFIER_KEY_FN:
      return nativeapi::ModifierKey::Fn;
    case NATIVE_MODIFIER_KEY_CAPS_LOCK:
      return nativeapi::ModifierKey::CapsLock;
    case NATIVE_MODIFIER_KEY_NUM_LOCK:
      return nativeapi::ModifierKey::NumLock;
    case NATIVE_MODIFIER_KEY_SCROLL_LOCK:
      return nativeapi::ModifierKey::ScrollLock;
    default:
      return nativeapi::ModifierKey::None;
  }
}

inline native_keyboard_accelerator_t to_c_keyboard_accelerator(const nativeapi::KeyboardAccelerator& value) {
  native_keyboard_accelerator_t result = {};
  result.modifiers = to_c_modifier_key(value.modifiers);
  result.key = to_c_str(value.key);
  return result;
}

inline nativeapi::KeyboardAccelerator to_cpp_keyboard_accelerator(const native_keyboard_accelerator_t& value) {
  nativeapi::KeyboardAccelerator result = {};
  result.modifiers = to_cpp_modifier_key(value.modifiers);
  result.key = value.key ? value.key : "";
  return result;
}

#endif  // __cplusplus
