// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#pragma once

#include <stdbool.h>
#include <stdint.h>

#include "common_c.h"
#include "display_c.h"
#include "geometry_c.h"

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

FFI_PLUGIN_EXPORT
native_display_list_t native_display_manager_get_all(void);

/// Caller owns the returned handle; release it with native_display_free().
FFI_PLUGIN_EXPORT
native_display_t native_display_manager_get_primary(void);

FFI_PLUGIN_EXPORT
native_point_t native_display_manager_get_cursor_position(void);

/// Registers @p callback for every DisplayEvent this DisplayManager emits.
/// @return the listener id, or NATIVE_INVALID_LISTENER_ID on failure.
FFI_PLUGIN_EXPORT
native_listener_id_t native_display_manager_add_listener(native_display_event_callback_t callback, void* user_data);

/// Unregisters a listener. Returns false if unknown.
FFI_PLUGIN_EXPORT
bool native_display_manager_remove_listener(native_listener_id_t listener_id);

#ifdef __cplusplus
}
#endif
