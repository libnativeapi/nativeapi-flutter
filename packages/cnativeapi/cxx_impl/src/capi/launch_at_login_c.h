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

/// Opaque LaunchAtLogin handle.
///
/// A generational index into the library's handle table, NOT a pointer:
/// never dereference it, and compare it against NATIVE_INVALID_LAUNCH_AT_LOGIN rather than NULL.
/// Releasing a handle invalidates it; later calls fail safely instead of
/// touching freed memory.
typedef uint64_t native_launch_at_login_t;

/// Never refers to a live LaunchAtLogin.
#define NATIVE_INVALID_LAUNCH_AT_LOGIN ((native_launch_at_login_t)0)

/// Creates a LaunchAtLogin instance; release it with native_launch_at_login_free().
FFI_PLUGIN_EXPORT
native_launch_at_login_t native_launch_at_login_create(void);

/// Creates a LaunchAtLogin instance; release it with native_launch_at_login_free().
FFI_PLUGIN_EXPORT
native_launch_at_login_t native_launch_at_login_create_with_id(const char* id);

/// Creates a LaunchAtLogin instance; release it with native_launch_at_login_free().
FFI_PLUGIN_EXPORT
native_launch_at_login_t native_launch_at_login_create_with_id_and_display_name(const char* id, const char* display_name);

FFI_PLUGIN_EXPORT
bool native_launch_at_login_is_supported(void);

/// Caller owns the returned string; free it with free_c_str().
FFI_PLUGIN_EXPORT
char* native_launch_at_login_get_id(native_launch_at_login_t launch_at_login);

/// Caller owns the returned string; free it with free_c_str().
FFI_PLUGIN_EXPORT
char* native_launch_at_login_get_display_name(native_launch_at_login_t launch_at_login);

FFI_PLUGIN_EXPORT
bool native_launch_at_login_set_display_name(native_launch_at_login_t launch_at_login, const char* display_name);

FFI_PLUGIN_EXPORT
bool native_launch_at_login_set_program(native_launch_at_login_t launch_at_login, const char* executable_path, native_string_list_t arguments);

/// Caller owns the returned string; free it with free_c_str().
FFI_PLUGIN_EXPORT
char* native_launch_at_login_get_executable_path(native_launch_at_login_t launch_at_login);

FFI_PLUGIN_EXPORT
native_string_list_t native_launch_at_login_get_arguments(native_launch_at_login_t launch_at_login);

FFI_PLUGIN_EXPORT
bool native_launch_at_login_enable(native_launch_at_login_t launch_at_login);

FFI_PLUGIN_EXPORT
bool native_launch_at_login_disable(native_launch_at_login_t launch_at_login);

FFI_PLUGIN_EXPORT
bool native_launch_at_login_is_enabled(native_launch_at_login_t launch_at_login);

/// Releases the caller's reference. Safe to call with an invalid or
/// already-released handle.
FFI_PLUGIN_EXPORT
void native_launch_at_login_free(native_launch_at_login_t launch_at_login);

#ifdef __cplusplus
}
#endif
