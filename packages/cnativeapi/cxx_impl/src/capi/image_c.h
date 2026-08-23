// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#pragma once

#include <stdbool.h>
#include <stdint.h>

#include "common_c.h"
#include "geometry_c.h"

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

/// Opaque Image handle.
///
/// A generational index into the library's handle table, NOT a pointer:
/// never dereference it, and compare it against NATIVE_INVALID_IMAGE rather than NULL.
/// Releasing a handle invalidates it; later calls fail safely instead of
/// touching freed memory.
typedef uint64_t native_image_t;

/// Never refers to a live Image.
#define NATIVE_INVALID_IMAGE ((native_image_t)0)

/// Caller owns the returned handle; release it with native_image_free().
FFI_PLUGIN_EXPORT
native_image_t native_image_from_file(const char* file_path);

/// Caller owns the returned handle; release it with native_image_free().
FFI_PLUGIN_EXPORT
native_image_t native_image_from_base64(const char* base64_data);

FFI_PLUGIN_EXPORT
native_size_t native_image_get_size(native_image_t image);

/// Caller owns the returned string; free it with free_c_str().
FFI_PLUGIN_EXPORT
char* native_image_get_format(native_image_t image);

/// Caller owns the returned string; free it with free_c_str().
FFI_PLUGIN_EXPORT
char* native_image_to_base64(native_image_t image);

FFI_PLUGIN_EXPORT
bool native_image_save_to_file(native_image_t image, const char* file_path);

/// Platform-specific native object (NSScreen*, HMONITOR, ...).
FFI_PLUGIN_EXPORT
void* native_image_get_native_object(native_image_t image);

/// Releases the caller's reference. Safe to call with an invalid or
/// already-released handle.
FFI_PLUGIN_EXPORT
void native_image_free(native_image_t image);

#ifdef __cplusplus
}
#endif
