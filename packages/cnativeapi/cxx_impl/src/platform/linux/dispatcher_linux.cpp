#include "../../foundation/dispatcher_platform.h"
#include "../../foundation/dispatcher_common.h"

#include <glib.h>

namespace nativeapi {
namespace dispatcher_platform {

namespace {

gboolean InvokeDispatchedWork(gpointer data) {
  auto* work = static_cast<std::function<void()>*>(data);
  if (work) {
    (*work)();
    delete work;
  }
  return G_SOURCE_REMOVE;
}

}  // namespace

bool PlatformIsMainThread() {
  return dispatcher_internal::IsMainThreadByCapturedId();
}

void PlatformSetMainThread() {
  dispatcher_internal::CaptureCallerAsMainThread();
}

bool PlatformIsMainThreadDispatchSupported() {
  return true;
}

bool PlatformRunOnMainThread(std::function<void()> fn) {
  if (!fn) {
    return true;
  }

  // g_idle_add() is thread-safe and attaches the source to the default main
  // context, which is the context the GTK main loop runs on the main thread.
  g_idle_add(InvokeDispatchedWork, new std::function<void()>(std::move(fn)));
  return true;
}

bool PlatformRunMainThreadLoopFor(int timeout_ms) {
  GMainContext* context = g_main_context_default();
  const gint64 deadline = g_get_monotonic_time() + (gint64)timeout_ms * 1000;
  do {
    // may_block=FALSE so an empty queue does not stall for the whole budget.
    while (g_main_context_iteration(context, FALSE)) {
    }
    if (timeout_ms <= 0) {
      break;
    }
    g_usleep(1000);
  } while (g_get_monotonic_time() < deadline);
  return true;
}

}  // namespace dispatcher_platform
}  // namespace nativeapi
