// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#pragma once

#include <stdbool.h>
#include <stdint.h>

#include "common_c.h"
#include "dialog_c.h"

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

/// Opaque MessageDialog handle.
///
/// A generational index into the library's handle table, NOT a pointer:
/// never dereference it, and compare it against NATIVE_INVALID_MESSAGE_DIALOG rather than NULL.
/// Releasing a handle invalidates it; later calls fail safely instead of
/// touching freed memory.
typedef uint64_t native_message_dialog_t;

/// Never refers to a live MessageDialog.
#define NATIVE_INVALID_MESSAGE_DIALOG ((native_message_dialog_t)0)

/// Creates a MessageDialog instance; release it with native_message_dialog_free().
FFI_PLUGIN_EXPORT
native_message_dialog_t native_message_dialog_create(const char* title, const char* message);

FFI_PLUGIN_EXPORT
void native_message_dialog_set_title(native_message_dialog_t message_dialog, const char* title);

/// Caller owns the returned string; free it with free_c_str().
FFI_PLUGIN_EXPORT
char* native_message_dialog_get_title(native_message_dialog_t message_dialog);

FFI_PLUGIN_EXPORT
void native_message_dialog_set_message(native_message_dialog_t message_dialog, const char* message);

/// Caller owns the returned string; free it with free_c_str().
FFI_PLUGIN_EXPORT
char* native_message_dialog_get_message(native_message_dialog_t message_dialog);

FFI_PLUGIN_EXPORT
native_dialog_modality_t native_message_dialog_get_modality(native_message_dialog_t message_dialog);

FFI_PLUGIN_EXPORT
void native_message_dialog_set_modality(native_message_dialog_t message_dialog, native_dialog_modality_t modality);

FFI_PLUGIN_EXPORT
bool native_message_dialog_open(native_message_dialog_t message_dialog);

FFI_PLUGIN_EXPORT
bool native_message_dialog_close(native_message_dialog_t message_dialog);

/// Releases the caller's reference. Safe to call with an invalid or
/// already-released handle.
FFI_PLUGIN_EXPORT
void native_message_dialog_free(native_message_dialog_t message_dialog);

#ifdef __cplusplus
}
#endif
