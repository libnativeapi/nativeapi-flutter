struct NativeTrayIDList {
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
long tray_manager_create();

FFI_PLUGIN_EXPORT
struct NativeTrayIDList tray_manager_get_all();

FFI_PLUGIN_EXPORT
void tray_manager_start_listening();

FFI_PLUGIN_EXPORT
void tray_manager_stop_listening();

#ifdef __cplusplus
}
#endif
