#include <string.h>
#include <iostream>

#include "libnativeapi/include/nativeapi.h"
#include "window.h"

using namespace nativeapi;

extern WindowManager g_window_manager;

FFI_PLUGIN_EXPORT
struct NativeSize window_get_size(int id) {
  auto window = g_window_manager.Get(id);
  auto size = window.GetSize();
  NativeSize native_size = {size.width, size.height};
  return native_size;
}

FFI_PLUGIN_EXPORT
void window_start_listening() {
  // TODO: Implement
}

FFI_PLUGIN_EXPORT
void window_stop_listening() {
  // TODO: Implement
}
