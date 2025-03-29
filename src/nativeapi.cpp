#include "nativeapi.h"
#include "libnativeapi/src/libnativeapi.h"

#include <iostream>

// Global instance of ScreenRetriever
static nativeapi::ScreenRetriever& g_screen_retriever = nativeapi::ScreenRetriever::GetInstance();

// A very short-lived native function.
//
// For very short-lived functions, it is fine to call them on the main isolate.
// They will block the Dart execution while running the native function, so
// only do this for native functions which are guaranteed to be short-lived.
FFI_PLUGIN_EXPORT int sum(int a, int b) {
  g_screen_retriever.AddEventListener(nativeapi::ScreenEventType::kDisplayAdded,
      [](const void* data) {
          const auto* display = static_cast<const nativeapi::Display*>(data);
          std::cout << "\nNew display connected!" << std::endl;
          std::cout << "Display: " << display->name 
                    << " (" << display->width << "x" << display->height << ")" 
                    << std::endl;
          std::cout << "Position: (" << display->visiblePositionX 
                    << ", " << display->visiblePositionY << ")" << std::endl;
      });

  g_screen_retriever.AddEventListener(nativeapi::ScreenEventType::kDisplayRemoved,
      [](const void* data) {
          const auto* display = static_cast<const nativeapi::Display*>(data);
          std::cout << "\nDisplay disconnected!" << std::endl;
          std::cout << "Display: " << display->name << std::endl;
      });
  return a + b;
}

// A longer-lived native function, which occupies the thread calling it.
//
// Do not call these kind of native functions in the main isolate. They will
// block Dart execution. This will cause dropped frames in Flutter applications.
// Instead, call these native functions on a separate isolate.
FFI_PLUGIN_EXPORT int sum_long_running(int a, int b) {
  // Simulate work.
#if _WIN32
  Sleep(5000);
#else
  usleep(5000 * 1000);
#endif
  return a + b;
}

FFI_PLUGIN_EXPORT struct NativeDisplay get_primary_display() {
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

FFI_PLUGIN_EXPORT struct NativeDisplayList get_all_displays() {
  // Get all displays information
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

// Get the current cursor position
FFI_PLUGIN_EXPORT struct NativePoint get_cursor_screen_point() {
  // Get cursor position
  auto cursorPoint = g_screen_retriever.GetCursorScreenPoint();
  NativePoint native_point;
  native_point.x = cursorPoint.x;
  native_point.y = cursorPoint.y;
  return native_point;
}
