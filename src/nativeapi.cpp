#include "nativeapi.h"
#include "libnativeapi/include/nativeapi.h"

#include <iostream>
#include <string.h>

using namespace nativeapi;

// Global instance of ScreenRetriever
//static ScreenRetriever g_screen_retriever = ScreenRetriever();

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

FFI_PLUGIN_EXPORT void register_event_callback(EventCallback callback) {
  g_callback = callback;
//  g_screen_retriever.AddEventListener(
//      ScreenEventType::DisplayAdded, [](const void* data) {
//        if (g_callback) {
//          char eventData[256];
//          snprintf(eventData, sizeof(eventData), "display_added");
//          g_callback(1, eventData);
//        }
//      });
//
//  // 注册显示器移除事件监听器
//  g_screen_retriever.AddEventListener(
//      ScreenEventType::DisplayRemoved, [](const void* data) {
//        if (g_callback) {
//          char eventData[256];
//          snprintf(eventData, sizeof(eventData), "display_removed");
//          g_callback(2, eventData);
//        }
//      });
}
