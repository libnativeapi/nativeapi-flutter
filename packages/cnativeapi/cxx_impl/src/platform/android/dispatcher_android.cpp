#include "../../foundation/dispatcher_platform.h"
#include "../../foundation/dispatcher_common.h"

#include <android/log.h>

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
  // TODO(android): implement via ALooper.
  //
  // Sketch: on the Java UI thread, ALooper_forThread() yields the main looper.
  // Create an eventfd (or pipe) and register it with ALooper_addFd(); posting
  // then means pushing the callable onto a mutex-guarded queue and writing one
  // byte to wake the looper, whose callback drains the queue.
  //
  // Reporting false is deliberate: silently dropping the callable would make
  // events vanish with no diagnostic, which is how the pre-existing "event
  // delivered on the wrong thread" bugs went unnoticed for so long.
  (void)fn;
  __android_log_print(ANDROID_LOG_WARN, "NativeApi",
                      "RunOnMainThread is not implemented on Android; work was not run.");
  return false;
}

bool PlatformRunMainThreadLoopFor(int timeout_ms) {
  // Nothing to service until PlatformRunOnMainThread() is implemented.
  (void)timeout_ms;
  return false;
}

}  // namespace dispatcher_platform
}  // namespace nativeapi
