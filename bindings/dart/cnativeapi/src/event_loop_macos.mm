#include "event_loop.h"

#include <cstdio>
#include <cstdlib>

#import <Cocoa/Cocoa.h>
#include <mach/mach.h>
#include <pthread.h>
#include <signal.h>
#include <unistd.h>

#include "capi/application_c.h"

// The autorelease pool API behind @autoreleasepool, for a pool that spans
// calls.
extern "C" void* objc_autoreleasePoolPush(void);
extern "C" void objc_autoreleasePoolPop(void* pool);

namespace {

// SIGUSR2 is borrowed for one delivery; the previous action is put back
// before `entry` runs.
constexpr int kTakeoverSignal = SIGUSR2;
void (*g_entry)(void) = nullptr;
struct sigaction g_previous_action;

// Open between two pumps, around whatever Dart runs in between: objects the
// core autoreleases there would otherwise pile up, since no AppKit run loop
// iteration surrounds that code.
void* g_dart_turn_pool = nullptr;

void OnTakeoverSignal(int signal_number) {
  sigaction(signal_number, &g_previous_action, nullptr);
  // The handler runs with the signal blocked, and it never returns.
  sigset_t mask;
  sigemptyset(&mask);
  sigaddset(&mask, signal_number);
  pthread_sigmask(SIG_UNBLOCK, &mask, nullptr);

  g_entry();
  // There is no Dart_RunLoop() left to go back to.
  cnativeapi_exit(0);
}

// The first thread of the task is the one dyld started main() on.
pthread_t FindMainThread() {
  thread_act_array_t threads = nullptr;
  mach_msg_type_number_t count = 0;
  if (task_threads(mach_task_self(), &threads, &count) != KERN_SUCCESS || count == 0) {
    return nullptr;
  }
  pthread_t main_thread = pthread_from_mach_thread_np(threads[0]);
  for (mach_msg_type_number_t i = 0; i < count; i++) {
    mach_port_deallocate(mach_task_self(), threads[i]);
  }
  vm_deallocate(mach_task_self(), reinterpret_cast<vm_address_t>(threads),
                count * sizeof(thread_act_t));
  return main_thread;
}

}  // namespace

bool cnativeapi_run_ui_thread(void (*entry)(void)) {
  if (entry == nullptr || g_entry != nullptr || pthread_main_np() != 0) {
    return false;
  }
  pthread_t main_thread = FindMainThread();
  if (main_thread == nullptr) {
    return false;
  }
  g_entry = entry;
  struct sigaction action = {};
  action.sa_handler = OnTakeoverSignal;
  sigemptyset(&action.sa_mask);
  if (sigaction(kTakeoverSignal, &action, &g_previous_action) != 0) {
    g_entry = nullptr;
    return false;
  }
  if (pthread_kill(main_thread, kTakeoverSignal) != 0) {
    sigaction(kTakeoverSignal, &g_previous_action, nullptr);
    g_entry = nullptr;
    return false;
  }
  return true;
}

void cnativeapi_start_event_loop(void) {
  // Creating the Application singleton sets up NSApp and its delegate.
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
  if (g_dart_turn_pool == nullptr) {
    g_dart_turn_pool = objc_autoreleasePoolPush();
  }
}

int cnativeapi_pump_event_loop(int timeout_ms) {
  if (g_dart_turn_pool != nullptr) {
    objc_autoreleasePoolPop(g_dart_turn_pool);
  }
  @autoreleasepool {
    // Running the loop for each event also drains the main dispatch queue,
    // which carries RunOnMainThread() work and EmitAsync() events.
    NSDate* until = [NSDate dateWithTimeIntervalSinceNow:timeout_ms / 1000.0];
    for (;;) {
      NSEvent* event = [NSApp nextEventMatchingMask:NSEventMaskAny
                                          untilDate:until
                                             inMode:NSDefaultRunLoopMode
                                            dequeue:YES];
      if (event == nil) {
        break;
      }
      [NSApp sendEvent:event];
      until = [NSDate distantPast];
    }
    [NSApp updateWindows];
  }
  g_dart_turn_pool = objc_autoreleasePoolPush();
  // Application::Quit() ends the process through -terminate: when the loop is
  // not Run()'s own, so there is no exit code to hand back here.
  return -1;
}

void cnativeapi_exit(int exit_code) {
  fflush(nullptr);
  _Exit(exit_code);
}
