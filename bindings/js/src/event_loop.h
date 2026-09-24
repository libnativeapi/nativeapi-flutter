// Drives the platform event loop from the JavaScript event loop.
//
// Application::Run() blocks in the platform loop, which would stop timers,
// promises and I/O for the life of the app. Instead, lib/runtime.ts calls
// Pump() from a timer: each call dispatches whatever the platform has queued
// and returns immediately.
#pragma once

#include <cstdint>

namespace nativeapi_js {

// Prepares the platform loop (finishes launching on macOS). With a non-zero
// `window` handle, shows it and makes it the primary window, as
// Application::Run(window) does.
void StartEventLoop(uint64_t window);

// Dispatches pending platform events without blocking. Returns -1 while the
// loop should keep running, or the exit code once the platform asked to quit.
int PumpEventLoop();

// Whether the calling thread is the platform UI thread.
bool IsPlatformMainThread();

}  // namespace nativeapi_js
