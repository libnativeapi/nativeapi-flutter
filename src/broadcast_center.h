

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*BroadcastReceivedCallback)(const char* message);

FFI_PLUGIN_EXPORT
void broadcast_center_start_listening();

FFI_PLUGIN_EXPORT
void broadcast_center_stop_listening();

FFI_PLUGIN_EXPORT
void broadcast_center_on_broadcast_received(BroadcastReceivedCallback callback);

#ifdef __cplusplus
}
#endif
