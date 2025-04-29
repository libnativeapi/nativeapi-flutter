#include <iostream>

#include "keyboard_monitor.h"
#include "libnativeapi/include/nativeapi.h"

using namespace nativeapi;

static KeyPressedCallback g_key_pressed_callback = nullptr;
static KeyReleasedCallback g_key_released_callback = nullptr;

KeyboardMonitor g_keyboard_monitor = KeyboardMonitor();
KeyboardEventHandler g_keyboard_event_handler = KeyboardEventHandler(
    [](const std::string& key) {
      std::cout << "Key pressed: " << key << std::endl;
      if (g_key_pressed_callback) {
        char* key_cstr = strdup(key.c_str());
        g_key_pressed_callback(key_cstr);
      }
    },
    [](const std::string& key) {
      std::cout << "Key released: " << key << std::endl;
      if (g_key_released_callback) {
        char* key_cstr = strdup(key.c_str());
        g_key_released_callback(key_cstr);
      }
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
void keyboard_monitor_on_key_pressed(KeyPressedCallback callback) {
  g_key_pressed_callback = callback;
}

FFI_PLUGIN_EXPORT
void keyboard_monitor_on_key_released(KeyReleasedCallback callback) {
  g_key_released_callback = callback;
}
