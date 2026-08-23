#include "dispatcher.h"

#include "dispatcher_platform.h"

namespace nativeapi {

namespace {

// Embedder/test overrides. Documented as "install before other threads start
// dispatching", so these are plain globals rather than lock-protected state —
// adding a lock here would put a mutex on every event delivery to buy safety
// for a case the contract already excludes.
MainThreadDispatchFn g_dispatch_override;
MainThreadPredicateFn g_predicate_override;

}  // namespace

bool IsMainThread() {
  if (g_predicate_override) {
    return g_predicate_override();
  }
  return dispatcher_platform::PlatformIsMainThread();
}

void SetMainThread() {
  dispatcher_platform::PlatformSetMainThread();
}

bool IsMainThreadDispatchSupported() {
  if (g_dispatch_override) {
    return true;
  }
  return dispatcher_platform::PlatformIsMainThreadDispatchSupported();
}

bool RunOnMainThread(std::function<void()> fn) {
  if (!fn) {
    return true;
  }
  if (g_dispatch_override) {
    return g_dispatch_override(std::move(fn));
  }
  return dispatcher_platform::PlatformRunOnMainThread(std::move(fn));
}

bool RunMainThreadLoopFor(int timeout_ms) {
  if (g_dispatch_override) {
    // An embedder-supplied scheduler owns its own draining; we have no queue.
    return false;
  }
  return dispatcher_platform::PlatformRunMainThreadLoopFor(timeout_ms);
}

void SetMainThreadDispatcher(MainThreadDispatchFn dispatch, MainThreadPredicateFn predicate) {
  g_dispatch_override = std::move(dispatch);
  g_predicate_override = std::move(predicate);
}

}  // namespace nativeapi
