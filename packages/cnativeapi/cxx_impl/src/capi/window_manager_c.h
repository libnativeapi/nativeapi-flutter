// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#pragma once

#include <stdbool.h>
#include <stdint.h>

#include "common_c.h"
#include "window_c.h"

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*native_window_manager_set_will_show_hook_callback_t)(unsigned int arg0, void* user_data);

typedef void (*native_window_manager_set_will_hide_hook_callback_t)(unsigned int arg0, void* user_data);

typedef void (*native_window_manager_set_will_close_hook_callback_t)(unsigned int arg0, void* user_data);

/// Caller owns the returned handle; release it with native_window_free().
FFI_PLUGIN_EXPORT
native_window_t native_window_manager_get(native_window_id_t id);

FFI_PLUGIN_EXPORT
native_window_list_t native_window_manager_get_all(void);

/// Caller owns the returned handle; release it with native_window_free().
FFI_PLUGIN_EXPORT
native_window_t native_window_manager_get_current(void);

FFI_PLUGIN_EXPORT
void native_window_manager_set_will_show_hook(native_window_manager_set_will_show_hook_callback_t hook, void* hook_user_data);

FFI_PLUGIN_EXPORT
void native_window_manager_set_will_hide_hook(native_window_manager_set_will_hide_hook_callback_t hook, void* hook_user_data);

FFI_PLUGIN_EXPORT
void native_window_manager_set_will_close_hook(native_window_manager_set_will_close_hook_callback_t hook, void* hook_user_data);

FFI_PLUGIN_EXPORT
bool native_window_manager_has_will_show_hook(void);

FFI_PLUGIN_EXPORT
bool native_window_manager_has_will_hide_hook(void);

FFI_PLUGIN_EXPORT
bool native_window_manager_has_will_close_hook(void);

FFI_PLUGIN_EXPORT
void native_window_manager_handle_will_show(native_window_id_t id);

FFI_PLUGIN_EXPORT
void native_window_manager_handle_will_hide(native_window_id_t id);

FFI_PLUGIN_EXPORT
void native_window_manager_handle_will_close(native_window_id_t id);

FFI_PLUGIN_EXPORT
bool native_window_manager_call_original_show(native_window_id_t id);

FFI_PLUGIN_EXPORT
bool native_window_manager_call_original_hide(native_window_id_t id);

FFI_PLUGIN_EXPORT
bool native_window_manager_call_original_close(native_window_id_t id);

/// Registers @p callback for every WindowEvent this WindowManager emits.
/// @return the listener id, or NATIVE_INVALID_LISTENER_ID on failure.
FFI_PLUGIN_EXPORT
native_listener_id_t native_window_manager_add_listener(native_window_event_callback_t callback, void* user_data);

/// Unregisters a listener. Returns false if unknown.
FFI_PLUGIN_EXPORT
bool native_window_manager_remove_listener(native_listener_id_t listener_id);

#ifdef __cplusplus
}
#endif
