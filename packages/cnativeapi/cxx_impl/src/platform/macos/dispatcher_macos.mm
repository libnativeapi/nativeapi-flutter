#include "../../foundation/dispatcher_platform.h"

#import <Carbon/Carbon.h>
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
  // Two queues have to be serviced here, and only one call does both.
  //
  // The GCD main queue carries RunOnMainThread() work, and draining it means
  // running the main run loop. The Carbon event queue carries global hotkeys
  // (see shortcut_manager_macos.mm) and other OS events; a bare
  // CFRunLoopRunInMode() does *not* dispatch those, which is why a program
  // without a Cocoa run loop would register a shortcut successfully and then
  // never see it fire.
  //
  // ReceiveNextEvent() runs the main run loop internally — so it drains the
  // GCD main queue too — and additionally hands back the next OS event, which
  // we forward to the Carbon dispatcher. That is the same routing
  // `[NSApp sendEvent:]` performs in a Cocoa app; an app that has one keeps
  // using it and never calls this function.
  //
  // Must be called on the main thread: ReceiveNextEvent() drains the calling
  // thread's event queue, and OS events are only ever posted to the main one.
  if (!PlatformIsMainThread()) {
    return false;
  }

  EventRef event = nullptr;
  const EventTimeout timeout = timeout_ms / 1000.0 * kEventDurationSecond;
  OSStatus status = ReceiveNextEvent(0, nullptr, timeout, true, &event);
  if (status == noErr && event) {
    SendEventToEventTarget(event, GetEventDispatcherTarget());
    ReleaseEvent(event);
  }
  return true;
}

}  // namespace dispatcher_platform
}  // namespace nativeapi
