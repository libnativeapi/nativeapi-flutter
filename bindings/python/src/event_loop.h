// Lets asyncio drive the platform event loop.
//
// Application::Run() blocks in the platform loop, which would stall every
// asyncio task for the life of the app. Instead, Application.run_async() in
// nativeapi/_runtime.py calls nativeapi_py_pump_event_loop() from a timer:
// each call dispatches whatever the platform has queued and returns
// immediately.
#pragma once

#include <stdbool.h>
#include <stdint.h>

#if _WIN32
#define NATIVEAPI_PY_EXPORT __declspec(dllexport)
#else
#define NATIVEAPI_PY_EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

// Prepares the platform loop (finishes launching on macOS). With a non-zero
// `window` handle, shows it and makes it the primary window, as
// Application::Run(window) does.
NATIVEAPI_PY_EXPORT void nativeapi_py_start_event_loop(uint64_t window);

// Dispatches pending platform events without blocking. Returns -1 while the
// loop should keep running, or the exit code once the platform asked to quit.
NATIVEAPI_PY_EXPORT int nativeapi_py_pump_event_loop(void);

// Whether the calling thread is the platform UI thread.
NATIVEAPI_PY_EXPORT bool nativeapi_py_is_main_thread(void);

#ifdef __cplusplus
}
#endif

namespace nativeapi_py {

// Shared by every platform's nativeapi_py_start_event_loop().
void ShowPrimaryWindow(uint64_t window);

}  // namespace nativeapi_py
