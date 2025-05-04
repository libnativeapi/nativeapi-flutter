#include <string.h>
#include <iostream>

#include "libnativeapi/include/nativeapi.h"
#include "window_manager.h"

using namespace nativeapi;

WindowManager g_window_manager = WindowManager();

FFI_PLUGIN_EXPORT
struct NativeWindowIDList window_manager_get_all() {
  auto windows = g_window_manager.GetAll();
  NativeWindowIDList window_id_list;
  window_id_list.count = windows.size();
  window_id_list.ids = (long*)malloc(sizeof(long) * window_id_list.count);
  for (size_t i = 0; i < window_id_list.count; i++) {
    window_id_list.ids[i] = windows[i]->id;
  }
  return window_id_list;
}

FFI_PLUGIN_EXPORT
long window_manager_get_current() {
  auto window = g_window_manager.GetCurrent();
  return window->id;
}

FFI_PLUGIN_EXPORT
void window_manager_start_listening() {
  // TODO: Implement
}

FFI_PLUGIN_EXPORT
void window_manager_stop_listening() {
  // TODO: Implement
}
