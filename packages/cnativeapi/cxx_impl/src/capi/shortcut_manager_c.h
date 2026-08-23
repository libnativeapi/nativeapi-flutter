// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#pragma once

#include <stdbool.h>
#include <stdint.h>

#include "common_c.h"
#include "shortcut_c.h"

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*native_shortcut_manager_register_callback_t)(void* user_data);

FFI_PLUGIN_EXPORT
bool native_shortcut_manager_is_supported(void);

/// Caller owns the returned handle; release it with native_shortcut_free().
FFI_PLUGIN_EXPORT
native_shortcut_t native_shortcut_manager_register_with_accelerator_and_callback(const char* accelerator, native_shortcut_manager_register_callback_t callback, void* callback_user_data);

/// Caller owns the returned handle; release it with native_shortcut_free().
FFI_PLUGIN_EXPORT
native_shortcut_t native_shortcut_manager_register_with_options(native_shortcut_options_t options);

FFI_PLUGIN_EXPORT
bool native_shortcut_manager_unregister_with_id(native_shortcut_id_t id);

FFI_PLUGIN_EXPORT
bool native_shortcut_manager_unregister_with_accelerator(const char* accelerator);

FFI_PLUGIN_EXPORT
int native_shortcut_manager_unregister_all(void);

/// Caller owns the returned handle; release it with native_shortcut_free().
FFI_PLUGIN_EXPORT
native_shortcut_t native_shortcut_manager_get_with_id(native_shortcut_id_t id);

/// Caller owns the returned handle; release it with native_shortcut_free().
FFI_PLUGIN_EXPORT
native_shortcut_t native_shortcut_manager_get_with_accelerator(const char* accelerator);

FFI_PLUGIN_EXPORT
native_shortcut_list_t native_shortcut_manager_get_all(void);

FFI_PLUGIN_EXPORT
native_shortcut_list_t native_shortcut_manager_get_by_scope(native_shortcut_scope_t scope);

FFI_PLUGIN_EXPORT
bool native_shortcut_manager_is_available(const char* accelerator);

FFI_PLUGIN_EXPORT
bool native_shortcut_manager_is_valid_accelerator(const char* accelerator);

FFI_PLUGIN_EXPORT
void native_shortcut_manager_set_enabled(bool enabled);

FFI_PLUGIN_EXPORT
bool native_shortcut_manager_is_enabled(void);

FFI_PLUGIN_EXPORT
void native_shortcut_manager_emit_shortcut_activated(native_shortcut_id_t id, const char* accelerator);

/// Registers @p callback for every ShortcutEvent this ShortcutManager emits.
/// @return the listener id, or NATIVE_INVALID_LISTENER_ID on failure.
FFI_PLUGIN_EXPORT
native_listener_id_t native_shortcut_manager_add_listener(native_shortcut_event_callback_t callback, void* user_data);

/// Unregisters a listener. Returns false if unknown.
FFI_PLUGIN_EXPORT
bool native_shortcut_manager_remove_listener(native_listener_id_t listener_id);

#ifdef __cplusplus
}
#endif
