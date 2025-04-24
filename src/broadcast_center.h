

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*BroadcastReceivedCallback)(const char* topic, const char* message);

FFI_PLUGIN_EXPORT
void broadcast_center_send_broadcast(const char* topic, const char* message);

FFI_PLUGIN_EXPORT
void broadcast_center_register_receiver(const char* topic);

FFI_PLUGIN_EXPORT
void broadcast_center_unregister_receiver(const char* topic);

FFI_PLUGIN_EXPORT
void broadcast_center_on_broadcast_received(BroadcastReceivedCallback callback);

#ifdef __cplusplus
}
#endif
