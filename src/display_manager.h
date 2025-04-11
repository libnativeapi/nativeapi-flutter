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

typedef void (*DisplayAddedCallback)(struct NativeDisplay display);
typedef void (*DisplayRemovedCallback)(struct NativeDisplay display);

FFI_PLUGIN_EXPORT
struct NativeDisplayList display_manager_get_all();

FFI_PLUGIN_EXPORT
struct NativeDisplay display_manager_get_primary();

FFI_PLUGIN_EXPORT
struct NativePoint display_manager_get_cursor_position();

FFI_PLUGIN_EXPORT
void display_manager_start_listening();

FFI_PLUGIN_EXPORT
void display_manager_stop_listening();

FFI_PLUGIN_EXPORT
void display_manager_on_display_added(DisplayAddedCallback callback);

FFI_PLUGIN_EXPORT
void display_manager_on_display_removed(DisplayRemovedCallback callback);

#ifdef __cplusplus
}
#endif
