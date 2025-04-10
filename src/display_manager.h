#include "display.h"
#include "point.h"

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

FFI_PLUGIN_EXPORT
struct NativeDisplayList display_manager_get_all();

FFI_PLUGIN_EXPORT
struct NativeDisplay display_manager_get_primary();

FFI_PLUGIN_EXPORT
struct NativePoint display_manager_get_cursor_position();

#ifdef __cplusplus
}
#endif
