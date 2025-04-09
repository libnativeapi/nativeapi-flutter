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
struct NativePoint screen_retriever_get_cursor_screen_point();

FFI_PLUGIN_EXPORT
struct NativeDisplay screen_retriever_get_primary_display();

FFI_PLUGIN_EXPORT
struct NativeDisplayList screen_retriever_get_all_displays();

#ifdef __cplusplus
}
#endif
