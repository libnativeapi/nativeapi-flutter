#include "event_loop.h"

#include <atomic>
#include <cstdio>
#include <cstdlib>
#include <thread>

#include <glib.h>

#include "capi/application_c.h"
#include "foundation/dispatcher.h"

bool cnativeapi_run_ui_thread(void (*entry)(void)) {
  static std::atomic<bool> started{false};
  if (entry == nullptr || started.exchange(true)) {
    return false;
  }
  // GTK belongs to the thread that initialises it: any thread can be the UI
  // thread, as long as it stays the same one.
  std::thread([entry] {
    nativeapi::SetMainThread();
    entry();
    cnativeapi_exit(0);
  }).detach();
  return true;
}

void cnativeapi_start_event_loop(void) {
  (void)native_application_is_running();
}

namespace {
gboolean WakeUp(gpointer fired) {
  *static_cast<bool*>(fired) = true;
  return G_SOURCE_REMOVE;
}
}  // namespace

int cnativeapi_pump_event_loop(int timeout_ms) {
  // GTK dispatches everything, including RunOnMainThread() work, through the
  // default main context.
  if (!g_main_context_pending(nullptr)) {
    bool fired = false;
    guint timeout = g_timeout_add(static_cast<guint>(timeout_ms), WakeUp, &fired);
    g_main_context_iteration(nullptr, TRUE);
    if (!fired) {
      g_source_remove(timeout);
    }
  }
  while (g_main_context_iteration(nullptr, FALSE)) {
  }
  // Application::Quit() ends the process when the loop is not Run()'s own.
  return -1;
}

void cnativeapi_exit(int exit_code) {
  fflush(nullptr);
  _Exit(exit_code);
}
