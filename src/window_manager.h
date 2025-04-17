struct NativeWindowIDList {
  long* ids;
  long count;
};

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

FFI_PLUGIN_EXPORT
struct NativeWindowIDList window_manager_get_all();

FFI_PLUGIN_EXPORT
long window_manager_get_current();

FFI_PLUGIN_EXPORT
void window_manager_start_listening();

FFI_PLUGIN_EXPORT
void window_manager_stop_listening();

#ifdef __cplusplus
}
#endif
