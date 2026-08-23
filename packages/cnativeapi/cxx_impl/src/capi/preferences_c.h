// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#pragma once

#include <stdbool.h>
#include <stdint.h>

#include "common_c.h"
#include "string_utils_c.h"

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

/// Opaque Preferences handle.
///
/// A generational index into the library's handle table, NOT a pointer:
/// never dereference it, and compare it against NATIVE_INVALID_PREFERENCES rather than NULL.
/// Releasing a handle invalidates it; later calls fail safely instead of
/// touching freed memory.
typedef uint64_t native_preferences_t;

/// Never refers to a live Preferences.
#define NATIVE_INVALID_PREFERENCES ((native_preferences_t)0)

/// Creates a Preferences instance; release it with native_preferences_free().
FFI_PLUGIN_EXPORT
native_preferences_t native_preferences_create(void);

/// Creates a Preferences instance; release it with native_preferences_free().
FFI_PLUGIN_EXPORT
native_preferences_t native_preferences_create_with_scope(const char* scope);

FFI_PLUGIN_EXPORT
bool native_preferences_set(native_preferences_t preferences, const char* key, const char* value);

/// Caller owns the returned string; free it with free_c_str().
FFI_PLUGIN_EXPORT
char* native_preferences_get(native_preferences_t preferences, const char* key, const char* default_value);

FFI_PLUGIN_EXPORT
bool native_preferences_remove(native_preferences_t preferences, const char* key);

FFI_PLUGIN_EXPORT
bool native_preferences_clear(native_preferences_t preferences);

FFI_PLUGIN_EXPORT
bool native_preferences_contains(native_preferences_t preferences, const char* key);

FFI_PLUGIN_EXPORT
native_string_list_t native_preferences_get_keys(native_preferences_t preferences);

FFI_PLUGIN_EXPORT
unsigned long native_preferences_get_size(native_preferences_t preferences);

FFI_PLUGIN_EXPORT
native_string_map_t native_preferences_get_all(native_preferences_t preferences);

/// Caller owns the returned string; free it with free_c_str().
FFI_PLUGIN_EXPORT
char* native_preferences_get_scope(native_preferences_t preferences);

/// Releases the caller's reference. Safe to call with an invalid or
/// already-released handle.
FFI_PLUGIN_EXPORT
void native_preferences_free(native_preferences_t preferences);

#ifdef __cplusplus
}
#endif
