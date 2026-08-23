// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#pragma once

#include <stdbool.h>
#include <stdint.h>

#include "common_c.h"
#include "tray_icon_c.h"

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

FFI_PLUGIN_EXPORT
bool native_tray_manager_is_supported(void);

/// Caller owns the returned handle; release it with native_tray_icon_free().
FFI_PLUGIN_EXPORT
native_tray_icon_t native_tray_manager_get(native_tray_icon_id_t id);

FFI_PLUGIN_EXPORT
native_tray_icon_list_t native_tray_manager_get_all(void);

#ifdef __cplusplus
}
#endif
