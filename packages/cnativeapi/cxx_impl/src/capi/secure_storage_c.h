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

/// Opaque SecureStorage handle.
///
/// A generational index into the library's handle table, NOT a pointer:
/// never dereference it, and compare it against NATIVE_INVALID_SECURE_STORAGE rather than NULL.
/// Releasing a handle invalidates it; later calls fail safely instead of
/// touching freed memory.
typedef uint64_t native_secure_storage_t;

/// Never refers to a live SecureStorage.
#define NATIVE_INVALID_SECURE_STORAGE ((native_secure_storage_t)0)

/// Creates a SecureStorage instance; release it with native_secure_storage_free().
FFI_PLUGIN_EXPORT
native_secure_storage_t native_secure_storage_create(void);

/// Creates a SecureStorage instance; release it with native_secure_storage_free().
FFI_PLUGIN_EXPORT
native_secure_storage_t native_secure_storage_create_with_scope(const char* scope);

FFI_PLUGIN_EXPORT
bool native_secure_storage_set(native_secure_storage_t secure_storage, const char* key, const char* value);

/// Caller owns the returned string; free it with free_c_str().
FFI_PLUGIN_EXPORT
char* native_secure_storage_get(native_secure_storage_t secure_storage, const char* key, const char* default_value);

FFI_PLUGIN_EXPORT
bool native_secure_storage_remove(native_secure_storage_t secure_storage, const char* key);

FFI_PLUGIN_EXPORT
bool native_secure_storage_clear(native_secure_storage_t secure_storage);

FFI_PLUGIN_EXPORT
bool native_secure_storage_contains(native_secure_storage_t secure_storage, const char* key);

FFI_PLUGIN_EXPORT
native_string_list_t native_secure_storage_get_keys(native_secure_storage_t secure_storage);

FFI_PLUGIN_EXPORT
unsigned long native_secure_storage_get_size(native_secure_storage_t secure_storage);

FFI_PLUGIN_EXPORT
native_string_map_t native_secure_storage_get_all(native_secure_storage_t secure_storage);

/// Caller owns the returned string; free it with free_c_str().
FFI_PLUGIN_EXPORT
char* native_secure_storage_get_scope(native_secure_storage_t secure_storage);

FFI_PLUGIN_EXPORT
bool native_secure_storage_is_available(void);

/// Releases the caller's reference. Safe to call with an invalid or
/// already-released handle.
FFI_PLUGIN_EXPORT
void native_secure_storage_free(native_secure_storage_t secure_storage);

#ifdef __cplusplus
}
#endif
