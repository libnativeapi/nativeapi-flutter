// Android and iOS have no loop for a plain Dart program to pump: the host app
// owns it.
#include "event_loop.h"

#include <cstdio>
#include <cstdlib>

bool cnativeapi_run_ui_thread(void (*entry)(void)) {
  return false;
}

void cnativeapi_start_event_loop(void) {}

int cnativeapi_pump_event_loop(int timeout_ms) {
  return 0;
}

void cnativeapi_exit(int exit_code) {
  fflush(nullptr);
  _Exit(exit_code);
}
