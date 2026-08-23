// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "keyboard_c.h"

#include <cstdio>
#include <memory>
#include <new>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "string_utils_c.h"
#include "../foundation/handle_table.h"
#include "../foundation/keyboard.h"

char* native_keyboard_accelerator_to_string(native_keyboard_accelerator_t keyboard_accelerator) {
  try {
    const auto self = to_cpp_keyboard_accelerator(keyboard_accelerator);
    return to_c_str(self.ToString());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_keyboard_accelerator_to_string");
    return nullptr;
  }
}

bool native_keyboard_accelerator_is_empty(native_keyboard_accelerator_t keyboard_accelerator) {
  try {
    const auto self = to_cpp_keyboard_accelerator(keyboard_accelerator);
    return self.IsEmpty();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_keyboard_accelerator_is_empty");
    return false;
  }
}

void native_keyboard_accelerator_free(native_keyboard_accelerator_t* value) {
  if (!value) {
    return;
  }
  free_c_str(value->key);
  value->key = nullptr;
}

bool to_c_keyboard_event(const nativeapi::KeyboardEvent& event, native_keyboard_event_t* out) {
  if (!out) {
    return false;
  }
  *out = native_keyboard_event_t{};
  out->keycode = event.GetKeycode();
  if (const auto* typed = dynamic_cast<const nativeapi::KeyPressedEvent*>(&event)) {
    out->type = NATIVE_KEYBOARD_EVENT_TYPE_KEY_PRESSED;
    (void)typed;
    return true;
  }
  if (const auto* typed = dynamic_cast<const nativeapi::KeyReleasedEvent*>(&event)) {
    out->type = NATIVE_KEYBOARD_EVENT_TYPE_KEY_RELEASED;
    (void)typed;
    return true;
  }
  if (const auto* typed = dynamic_cast<const nativeapi::ModifierKeysChangedEvent*>(&event)) {
    out->type = NATIVE_KEYBOARD_EVENT_TYPE_MODIFIER_KEYS_CHANGED;
    out->data.modifier_keys_changed.modifier_keys = typed->GetModifierKeys();
    return true;
  }
  return false;
}

void free_c_keyboard_event(native_keyboard_event_t* value) {
  if (!value) {
    return;
  }
}

