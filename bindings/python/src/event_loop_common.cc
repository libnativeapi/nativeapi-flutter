#include "event_loop.h"

#include "capi/application_c.h"
#include "capi/window_c.h"
#include "foundation/dispatcher.h"

namespace nativeapi_py {

void ShowPrimaryWindow(uint64_t window) {
  if (window == 0) {
    return;
  }
  native_application_set_primary_window(window);
  native_window_show(window);
  native_window_focus(window);
}

}  // namespace nativeapi_py

bool nativeapi_py_is_main_thread(void) {
  return nativeapi::IsMainThread();
}
