// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#pragma once

#include <stdbool.h>
#include <stdint.h>

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

/// Identifies one registered event listener.
typedef uint64_t native_listener_id_t;

/// Returned by add_listener when registration failed.
#define NATIVE_INVALID_LISTENER_ID ((native_listener_id_t)0)

#ifdef __cplusplus
}
#endif
