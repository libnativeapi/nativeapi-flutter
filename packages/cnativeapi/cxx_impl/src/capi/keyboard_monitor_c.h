// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#pragma once

#include <stdbool.h>
#include <stdint.h>

#include "common_c.h"
#include "keyboard_c.h"

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

/// Opaque KeyboardMonitor handle.
///
/// A generational index into the library's handle table, NOT a pointer:
/// never dereference it, and compare it against NATIVE_INVALID_KEYBOARD_MONITOR rather than NULL.
/// Releasing a handle invalidates it; later calls fail safely instead of
/// touching freed memory.
typedef uint64_t native_keyboard_monitor_t;

/// Never refers to a live KeyboardMonitor.
#define NATIVE_INVALID_KEYBOARD_MONITOR ((native_keyboard_monitor_t)0)

/// Creates a KeyboardMonitor instance; release it with native_keyboard_monitor_free().
FFI_PLUGIN_EXPORT
native_keyboard_monitor_t native_keyboard_monitor_create(void);

FFI_PLUGIN_EXPORT
void native_keyboard_monitor_start(native_keyboard_monitor_t keyboard_monitor);

FFI_PLUGIN_EXPORT
void native_keyboard_monitor_stop(native_keyboard_monitor_t keyboard_monitor);

FFI_PLUGIN_EXPORT
bool native_keyboard_monitor_is_monitoring(native_keyboard_monitor_t keyboard_monitor);

/// Releases the caller's reference. Safe to call with an invalid or
/// already-released handle.
FFI_PLUGIN_EXPORT
void native_keyboard_monitor_free(native_keyboard_monitor_t keyboard_monitor);

/// Registers @p callback for every KeyboardEvent this KeyboardMonitor emits.
/// @return the listener id, or NATIVE_INVALID_LISTENER_ID on failure.
FFI_PLUGIN_EXPORT
native_listener_id_t native_keyboard_monitor_add_listener(native_keyboard_monitor_t keyboard_monitor, native_keyboard_event_callback_t callback, void* user_data);

/// Unregisters a listener. Returns false if unknown.
FFI_PLUGIN_EXPORT
bool native_keyboard_monitor_remove_listener(native_keyboard_monitor_t keyboard_monitor, native_listener_id_t listener_id);

#ifdef __cplusplus
}
#endif
