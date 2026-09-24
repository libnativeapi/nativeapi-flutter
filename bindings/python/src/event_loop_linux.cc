#include "event_loop.h"

#include <glib.h>

void nativeapi_py_start_event_loop(uint64_t window) {
  nativeapi_py::ShowPrimaryWindow(window);
}

int nativeapi_py_pump_event_loop(void) {
  // GTK dispatches everything, including RunOnMainThread() work, through the
  // default main context.
  while (g_main_context_iteration(nullptr, FALSE)) {
  }
  return -1;
}
