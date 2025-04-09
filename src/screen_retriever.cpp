#include <string.h>
#include <iostream>

#include "libnativeapi/include/nativeapi.h"
#include "screen_retriever.h"

using namespace nativeapi;

static ScreenRetriever g_screen_retriever = ScreenRetriever();

FFI_PLUGIN_EXPORT
struct NativePoint screen_retriever_get_cursor_screen_point() {
  auto cursorPoint = g_screen_retriever.GetCursorScreenPoint();
  NativePoint native_point;
  native_point.x = cursorPoint.x;
  native_point.y = cursorPoint.y;
  return native_point;
}

FFI_PLUGIN_EXPORT
struct NativeDisplay screen_retriever_get_primary_display() {
  auto display = g_screen_retriever.GetPrimaryDisplay();
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
struct NativeDisplayList screen_retriever_get_all_displays() {
  auto displays = g_screen_retriever.GetAllDisplays();
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
