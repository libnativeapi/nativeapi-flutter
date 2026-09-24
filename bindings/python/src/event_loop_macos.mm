#include "event_loop.h"

#import <Cocoa/Cocoa.h>

#include "capi/application_c.h"

void nativeapi_py_start_event_loop(uint64_t window) {
  // Creating the Application singleton installs its NSApplication delegate.
  (void)native_application_is_running();
  static bool launched = false;
  if (!launched) {
    launched = true;
    // What -[NSApplication run] does before its first event; posts
    // applicationDidFinishLaunching: (the "started" event).
    [NSApp finishLaunching];
  }
  // A process started from a terminal is not frontmost; bring it forward the
  // way launching an app bundle would.
  [NSApp activateIgnoringOtherApps:YES];
  nativeapi_py::ShowPrimaryWindow(window);
}

int nativeapi_py_pump_event_loop(void) {
  @autoreleasepool {
    // Running the loop for each event also drains the main dispatch queue,
    // which carries RunOnMainThread() work and EmitAsync() events.
    for (;;) {
      NSEvent* event = [NSApp nextEventMatchingMask:NSEventMaskAny
                                          untilDate:[NSDate distantPast]
                                             inMode:NSDefaultRunLoopMode
                                            dequeue:YES];
      if (event == nil) {
        break;
      }
      [NSApp sendEvent:event];
    }
    [NSApp updateWindows];
  }
  return -1;
}
