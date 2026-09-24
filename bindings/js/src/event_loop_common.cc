#include "event_loop.h"

#include "capi/application_c.h"
#include "capi/window_c.h"
#include "foundation/dispatcher.h"

namespace nativeapi_js {

// Shared by every platform's StartEventLoop().
void ShowPrimaryWindow(uint64_t window) {
  if (window == 0) {
    return;
  }
  native_application_set_primary_window(window);
  native_window_show(window);
  native_window_focus(window);
}

bool IsPlatformMainThread() {
  return nativeapi::IsMainThread();
}

}  // namespace nativeapi_js
