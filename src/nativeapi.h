#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "libnativeapi/src/screen_retriever.h"

#if _WIN32
#include <windows.h>
#else
#include <pthread.h>
#include <unistd.h>
#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

// A very short-lived native function.
//
// For very short-lived functions, it is fine to call them on the main isolate.
// They will block the Dart execution while running the native function, so
// only do this for native functions which are guaranteed to be short-lived.
FFI_PLUGIN_EXPORT int sum(int a, int b);

// A longer lived native function, which occupies the thread calling it.
//
// Do not call these kind of native functions in the main isolate. They will
// block Dart execution. This will cause dropped frames in Flutter applications.
// Instead, call these native functions on a separate isolate.
FFI_PLUGIN_EXPORT int sum_long_running(int a, int b);

// Get primary display
FFI_PLUGIN_EXPORT struct Display get_primary_display();

// Get all displays
FFI_PLUGIN_EXPORT struct DisplayList get_all_displays();

// Get the current cursor position
FFI_PLUGIN_EXPORT int get_cursor_screen_point();

#ifdef __cplusplus
}
#endif
