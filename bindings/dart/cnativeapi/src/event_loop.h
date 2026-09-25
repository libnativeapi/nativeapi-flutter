// Lets a plain Dart program (no Flutter) drive the platform event loop.
//
// Application::Run() blocks inside the platform loop, which would stall every
// Dart timer, future and stream for the life of the app. Instead, runNativeApp()
// in package:nativeapi calls cnativeapi_pump_event_loop() from a Dart timer:
// each call dispatches what the platform has queued, waits a few milliseconds
// for more, and returns, so the Dart event loop keeps turning in between.
//
// All of it runs in an isolate of its own on a thread of its own, because the
// platform's UI objects belong to one thread and the Dart VM moves an isolate
// between its worker threads as it pleases. cnativeapi_run_ui_thread() provides
// that thread.
#pragma once

#include <stdbool.h>
#include <stdint.h>

#if _WIN32
#define CNATIVEAPI_EXPORT __declspec(dllexport)
#else
#define CNATIVEAPI_EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

// Calls `entry` on the thread that becomes the UI thread, outside any isolate,
// so `entry` must be a NativeCallable.isolateGroupBound. The process ends when
// `entry` returns. Returns false, calling nothing, if the thread could not be
// had, or on a second call.
//
// - macOS: AppKit only works on the process's first thread, which the
//   standalone Dart VM keeps parked in Dart_RunLoop() while main() runs on a
//   worker. That thread is interrupted with a signal and `entry` runs from the
//   handler, which never returns; the thread holds no lock at that point.
//   Refused when called on the main thread already (a Flutter app).
// - Windows, Linux: a new thread, declared the main thread to the core's
//   dispatcher before `entry` runs. Nothing may have used nativeapi before.
// - Android, iOS: always refused; the host app owns the UI thread.
CNATIVEAPI_EXPORT bool cnativeapi_run_ui_thread(void (*entry)(void));

// Prepares the platform loop: finishes launching and activates the app on
// macOS. Call once, on the main thread, before the first pump.
CNATIVEAPI_EXPORT void cnativeapi_start_event_loop(void);

// Ends the process with `exit_code` after flushing stdio, without running
// atexit handlers or static destructors: those race the Dart VM's threads,
// which are still running. What the core would tear down (windows, tray icons)
// goes with the process.
CNATIVEAPI_EXPORT void cnativeapi_exit(int exit_code);

// Dispatches every pending platform event; when there was none, first waits
// up to `timeout_ms` for one. Returns -1 while the loop should keep running,
// or the exit code once the platform asked to quit (WM_QUIT on Windows).
CNATIVEAPI_EXPORT int cnativeapi_pump_event_loop(int timeout_ms);

#ifdef __cplusplus
}
#endif
