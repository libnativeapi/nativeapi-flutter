#include "nativeapi.h"
#include "libnativeapi/include/nativeapi.h"

#include <iostream>

using namespace nativeapi;

// Global instance of ScreenRetriever
static ScreenRetriever g_screen_retriever = ScreenRetriever();

// 声明一个全局的回调函数指针
static EventCallback g_callback = nullptr;

// A very short-lived native function.
//
// For very short-lived functions, it is fine to call them on the main isolate.
// They will block the Dart execution while running the native function, so
// only do this for native functions which are guaranteed to be short-lived.
FFI_PLUGIN_EXPORT int sum(int a, int b) {
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

FFI_PLUGIN_EXPORT void register_event_callback(EventCallback callback) {
  g_callback = callback;
  g_screen_retriever.AddEventListener(
      ScreenEventType::DisplayAdded, [](const void* data) {
        if (g_callback) {
          char eventData[256];
          snprintf(eventData, sizeof(eventData), "display_added");
          g_callback(1, eventData);
        }
      });

  // 注册显示器移除事件监听器
  g_screen_retriever.AddEventListener(
      ScreenEventType::DisplayRemoved, [](const void* data) {
        if (g_callback) {
          char eventData[256];
          snprintf(eventData, sizeof(eventData), "display_removed");
          g_callback(2, eventData);
        }
      });
}
