#include <string.h>
#include <iostream>

#include "display_manager.h"
#include "libnativeapi/include/nativeapi.h"

using namespace nativeapi;

struct NativeDisplay to_native_display(const Display& display) {
  NativeDisplay native_display;
  native_display.id = strdup(display.id.c_str());
  native_display.name = strdup(display.name.c_str());
  native_display.width = display.width;
  native_display.height = display.height;
  native_display.visiblePositionX = display.visiblePositionX;
  native_display.visiblePositionY = display.visiblePositionY;
  native_display.visibleSizeWidth = display.visibleSizeWidth;
  native_display.visibleSizeHeight = display.visibleSizeHeight;
  native_display.scaleFactor = display.scaleFactor;
  return native_display;
}

static DisplayAddedCallback g_display_added_callback = nullptr;
static DisplayRemovedCallback g_display_removed_callback = nullptr;

DisplayManager g_display_manager = DisplayManager();
DisplayEventHandler g_display_event_handler = DisplayEventHandler(
    [](const Display& display) {
      std::cout << "Display added: " << display.id << std::endl;
      if (g_display_added_callback) {
        g_display_added_callback(to_native_display(display));
      }
    },
    [](const Display& display) {
      std::cout << "Display removed: " << display.id << std::endl;
      if (g_display_removed_callback) {
        g_display_removed_callback(to_native_display(display));
      }
    });

FFI_PLUGIN_EXPORT
struct NativeDisplayList display_manager_get_all() {
  auto displays = g_display_manager.GetAll();
  NativeDisplayList native_display_list;
  native_display_list.count = displays.size();
  for (size_t i = 0; i < displays.size(); i++) {
    native_display_list.displays[i] = to_native_display(displays[i]);
  }
  return native_display_list;
}

FFI_PLUGIN_EXPORT
struct NativeDisplay display_manager_get_primary() {
  auto display = g_display_manager.GetPrimary();
  return to_native_display(display);
}

FFI_PLUGIN_EXPORT
struct NativePoint display_manager_get_cursor_position() {
  auto cursorPosition = g_display_manager.GetCursorPosition();
  NativePoint native_point;
  native_point.x = cursorPosition.x;
  native_point.y = cursorPosition.y;
  return native_point;
}

FFI_PLUGIN_EXPORT
void display_manager_start_listening() {
  g_display_manager.RemoveListener(&g_display_event_handler);
  g_display_manager.AddListener(&g_display_event_handler);
}

FFI_PLUGIN_EXPORT
void display_manager_stop_listening() {
  g_display_manager.RemoveListener(&g_display_event_handler);
}

FFI_PLUGIN_EXPORT
void display_manager_on_display_added(DisplayAddedCallback callback) {
  g_display_added_callback = callback;
}

FFI_PLUGIN_EXPORT
void display_manager_on_display_removed(DisplayRemovedCallback callback) {
  g_display_removed_callback = callback;
}
