#include "event_loop.h"

#include <glib.h>

namespace nativeapi_js {

void ShowPrimaryWindow(uint64_t window);

void StartEventLoop(uint64_t window) {
  ShowPrimaryWindow(window);
}

int PumpEventLoop() {
  // GTK dispatches everything, including RunOnMainThread() work, through the
  // default main context.
  while (g_main_context_iteration(nullptr, FALSE)) {
  }
  return -1;
}

}  // namespace nativeapi_js
