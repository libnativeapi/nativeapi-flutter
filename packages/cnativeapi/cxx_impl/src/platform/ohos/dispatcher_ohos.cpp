#include "../../foundation/dispatcher_platform.h"
#include "../../foundation/dispatcher_common.h"

namespace nativeapi {
namespace dispatcher_platform {

bool PlatformIsMainThread() {
  return dispatcher_internal::IsMainThreadByCapturedId();
}

void PlatformSetMainThread() {
  dispatcher_internal::CaptureCallerAsMainThread();
}

bool PlatformIsMainThreadDispatchSupported() {
  return false;
}

bool PlatformRunOnMainThread(std::function<void()> fn) {
  // TODO(ohos): implement via the ArkUI event handler / OH_Napi thread-safe
  // function, whichever the surrounding app model provides.
  //
  // Returning false rather than dropping silently — see the Android note.
  (void)fn;
  return false;
}

bool PlatformRunMainThreadLoopFor(int timeout_ms) {
  (void)timeout_ms;
  return false;
}

}  // namespace dispatcher_platform
}  // namespace nativeapi
