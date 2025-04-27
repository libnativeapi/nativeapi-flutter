#include <stdbool.h>

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

FFI_PLUGIN_EXPORT
void accessibility_manager_enable();

FFI_PLUGIN_EXPORT
bool accessibility_manager_is_enabled();

#ifdef __cplusplus
}
#endif
