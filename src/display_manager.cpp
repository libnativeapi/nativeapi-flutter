#include <string.h>
#include <iostream>

#include "display_manager.h"
#include "libnativeapi/include/nativeapi.h"

using namespace nativeapi;

static DisplayManager g_display_manager = DisplayManager();

FFI_PLUGIN_EXPORT
struct NativeDisplayList display_manager_get_all() {
  auto displays = g_display_manager.GetAll();
  NativeDisplayList native_display_list;
  native_display_list.count = displays.size();
  for (size_t i = 0; i < displays.size(); i++) {
    NativeDisplay native_display;
    native_display.id = strdup(displays[i].id.c_str());
    native_display.name = strdup(displays[i].name.c_str());
    native_display.width = displays[i].width;
    native_display.height = displays[i].height;
    native_display.visiblePositionX = displays[i].visiblePositionX;
    native_display.visiblePositionY = displays[i].visiblePositionY;
    native_display_list.displays[i] = native_display;
  }
  return native_display_list;
}

FFI_PLUGIN_EXPORT
struct NativeDisplay display_manager_get_primary() {
  auto display = g_display_manager.GetPrimary();
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

FFI_PLUGIN_EXPORT
struct NativePoint display_manager_get_cursor_position() {
  auto cursorPosition = g_display_manager.GetCursorPosition();
  NativePoint native_point;
  native_point.x = cursorPosition.x;
  native_point.y = cursorPosition.y;
  return native_point;
}
