#include "../../foundation/dispatcher_platform.h"

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#include <dispatch/dispatch.h>

namespace nativeapi {
namespace dispatcher_platform {

bool PlatformIsMainThread() {
  return [NSThread isMainThread];
}

void PlatformSetMainThread() {
  // No-op: on Apple platforms the OS is authoritative about which thread is the
  // main thread, so there is nothing for the caller to correct.
}

bool PlatformIsMainThreadDispatchSupported() {
  return true;
}

bool PlatformRunOnMainThread(std::function<void()> fn) {
  if (!fn) {
    return true;
  }

  // Heap-allocate rather than capturing the std::function in a __block variable:
  // block capture of non-trivial C++ types differs between ARC and non-ARC
  // translation units, and this file is compiled into both configurations.
  auto* work = new std::function<void()>(std::move(fn));
  dispatch_async(dispatch_get_main_queue(), ^{
    (*work)();
    delete work;
  });
  return true;
}

bool PlatformRunMainThreadLoopFor(int timeout_ms) {
  CFRunLoopRunInMode(kCFRunLoopDefaultMode, timeout_ms / 1000.0, false);
  return true;
}

}  // namespace dispatcher_platform
}  // namespace nativeapi
