#include <stdbool.h>

#include "point.h"
#include "rectangle.h"
#include "size.h"

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

FFI_PLUGIN_EXPORT
void tray_set_icon(long tray_id, const char* icon);

FFI_PLUGIN_EXPORT
void tray_set_title(long tray_id, const char* title);

FFI_PLUGIN_EXPORT
const char* tray_get_title(long tray_id);

FFI_PLUGIN_EXPORT
void tray_set_tooltip(long tray_id, const char* tooltip);

FFI_PLUGIN_EXPORT
const char* tray_get_tooltip(long tray_id);

FFI_PLUGIN_EXPORT
void tray_start_listening(long tray_id);

FFI_PLUGIN_EXPORT
void tray_stop_listening(long tray_id);

#ifdef __cplusplus
}
#endif
