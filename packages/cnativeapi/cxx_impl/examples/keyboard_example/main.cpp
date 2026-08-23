#include <signal.h>
#include <chrono>
#include <iostream>
#include <thread>

#include "../../src/capi/keyboard_c.h"
#include "../../src/capi/keyboard_monitor_c.h"

// Global monitor handle for cleanup
static native_keyboard_monitor_t g_monitor = NATIVE_INVALID_KEYBOARD_MONITOR;
static bool g_running = true;

// Signal handler for graceful shutdown
void signal_handler(int sig) {
  std::cout << "\nReceived signal " << sig << ", shutting down...\n";
  g_running = false;
  if (g_monitor != NATIVE_INVALID_KEYBOARD_MONITOR) {
    native_keyboard_monitor_stop(g_monitor);
    native_keyboard_monitor_free(g_monitor);
    g_monitor = NATIVE_INVALID_KEYBOARD_MONITOR;
  }
  exit(0);
}

// A KeyboardMonitor emits one KeyboardEvent stream, tagged by concrete type.
void on_keyboard_event(const native_keyboard_event_t* event, void* user_data) {
  (void)user_data;
  switch (event->type) {
    case NATIVE_KEYBOARD_EVENT_TYPE_KEY_PRESSED:
      std::cout << "Key pressed: " << event->keycode << std::endl;
      break;
    case NATIVE_KEYBOARD_EVENT_TYPE_KEY_RELEASED:
      std::cout << "Key released: " << event->keycode << std::endl;
      break;
    case NATIVE_KEYBOARD_EVENT_TYPE_MODIFIER_KEYS_CHANGED: {
      unsigned int modifier_keys = event->data.modifier_keys_changed.modifier_keys;
      std::cout << "Modifier keys changed: 0x" << std::hex << modifier_keys << std::dec;

      if (modifier_keys & NATIVE_MODIFIER_KEY_SHIFT)
        std::cout << " SHIFT";
      if (modifier_keys & NATIVE_MODIFIER_KEY_CTRL)
        std::cout << " CTRL";
      if (modifier_keys & NATIVE_MODIFIER_KEY_ALT)
        std::cout << " ALT";
      if (modifier_keys & NATIVE_MODIFIER_KEY_META)
        std::cout << " META";
      if (modifier_keys & NATIVE_MODIFIER_KEY_FN)
        std::cout << " FN";
      if (modifier_keys & NATIVE_MODIFIER_KEY_CAPS_LOCK)
        std::cout << " CAPS";
      if (modifier_keys & NATIVE_MODIFIER_KEY_NUM_LOCK)
        std::cout << " NUM";
      if (modifier_keys & NATIVE_MODIFIER_KEY_SCROLL_LOCK)
        std::cout << " SCROLL";

      std::cout << std::endl;
      break;
    }
  }
}

int main() {
  std::cout << "KeyboardMonitor C API Example\n";
  std::cout << "==============================\n";

  // Set up signal handlers
  signal(SIGINT, signal_handler);
  signal(SIGTERM, signal_handler);

  // Create keyboard monitor
  g_monitor = native_keyboard_monitor_create();
  if (g_monitor == NATIVE_INVALID_KEYBOARD_MONITOR) {
    std::cout << "Failed to create keyboard monitor\n";
    return 1;
  }
  std::cout << "Keyboard monitor created successfully\n";

  // Register the single event listener
  if (native_keyboard_monitor_add_listener(g_monitor, on_keyboard_event, nullptr) ==
      NATIVE_INVALID_LISTENER_ID) {
    std::cout << "Failed to add listener\n";
    native_keyboard_monitor_free(g_monitor);
    return 1;
  }
  std::cout << "Listener registered successfully\n";

  // Start monitoring
  native_keyboard_monitor_start(g_monitor);

  if (native_keyboard_monitor_is_monitoring(g_monitor)) {
    std::cout << "Keyboard monitoring is now active\n";
    std::cout << "\nThis example demonstrates the KeyboardMonitor C API:\n";
    std::cout << "• native_keyboard_monitor_create() - Creates a monitor instance\n";
    std::cout << "• native_keyboard_monitor_add_listener() - Registers the event listener\n";
    std::cout << "• native_keyboard_monitor_start() - Starts monitoring\n";
    std::cout << "• native_keyboard_monitor_is_monitoring() - Checks status\n";
    std::cout << "• native_keyboard_monitor_stop() - Stops monitoring\n";
    std::cout << "• native_keyboard_monitor_free() - Releases the handle\n";
    std::cout << "\nPress keys to see events. Press Ctrl+C to exit.\n\n";
  } else {
    std::cout << "Warning: Monitor created but not monitoring (may be due to "
                 "permissions or display server)\n";
    std::cout << "This is expected in headless environments or without proper "
                 "permissions.\n";
    std::cout << "On a desktop system with X11/Wayland, you would see keyboard "
                 "events.\n\n";
  }

  // Keep the main thread alive to receive events
  while (g_running) {
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
  }

  return 0;
}