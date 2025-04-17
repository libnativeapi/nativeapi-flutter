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
struct NativeSize window_get_size(int id);

FFI_PLUGIN_EXPORT
void window_start_listening();

FFI_PLUGIN_EXPORT
void window_stop_listening();

#ifdef __cplusplus
}
#endif
