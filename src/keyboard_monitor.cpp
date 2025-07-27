#include <iostream>

#include "keyboard_monitor.h"
#include "libnativeapi/include/nativeapi.h"

using namespace nativeapi;

static KeyPressedCallback g_key_pressed_callback = nullptr;
static KeyReleasedCallback g_key_released_callback = nullptr;
static uint32_t g_modifier_keys = static_cast<uint32_t>(ModifierKey::None);

KeyboardMonitor g_keyboard_monitor;
KeyboardEventHandler g_keyboard_event_handler(
    [](int keycode) {
      std::cout << "Key pressed: " << keycode << std::endl;
      if (g_key_pressed_callback) {
        g_key_pressed_callback(keycode);
      }
    },
    [](int keycode) {
      std::cout << "Key released: " << keycode << std::endl;
      if (g_key_released_callback) {
        g_key_released_callback(keycode);
      }
    },
    [](uint32_t modifier_keys) {
      std::cout << "Modifier keys changed: " << modifier_keys << std::endl;
      g_modifier_keys = modifier_keys;
    });

FFI_PLUGIN_EXPORT
void keyboard_monitor_start() {
  g_keyboard_monitor.SetEventHandler(&g_keyboard_event_handler);
  g_keyboard_monitor.Start();
}

FFI_PLUGIN_EXPORT
void keyboard_monitor_stop() {
  g_keyboard_monitor.Stop();
  g_keyboard_monitor.SetEventHandler(nullptr);
}

FFI_PLUGIN_EXPORT
bool keyboard_monitor_is_shift_pressed() {
  return g_modifier_keys & static_cast<uint32_t>(ModifierKey::Shift);
}

FFI_PLUGIN_EXPORT
bool keyboard_monitor_is_ctrl_pressed() {
  return g_modifier_keys & static_cast<uint32_t>(ModifierKey::Ctrl);
}

FFI_PLUGIN_EXPORT
bool keyboard_monitor_is_alt_pressed() {
  return g_modifier_keys & static_cast<uint32_t>(ModifierKey::Alt);
}

FFI_PLUGIN_EXPORT
bool keyboard_monitor_is_meta_pressed() {
  return g_modifier_keys & static_cast<uint32_t>(ModifierKey::Meta);
}

FFI_PLUGIN_EXPORT
bool keyboard_monitor_is_fn_pressed() {
  return g_modifier_keys & static_cast<uint32_t>(ModifierKey::Fn);
}

FFI_PLUGIN_EXPORT
void keyboard_monitor_on_key_pressed(KeyPressedCallback callback) {
  g_key_pressed_callback = callback;
}

FFI_PLUGIN_EXPORT
void keyboard_monitor_on_key_released(KeyReleasedCallback callback) {
  g_key_released_callback = callback;
}
