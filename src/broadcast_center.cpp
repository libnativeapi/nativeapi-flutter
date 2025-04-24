#include <string.h>
#include <iostream>

#include "broadcast_center.h"
#include "libnativeapi/include/nativeapi.h"

using namespace nativeapi;

static BroadcastReceivedCallback g_broadcast_received_callback = nullptr;

BroadcastCenter g_broadcast_center = BroadcastCenter();
BroadcastEventHandler g_broadcast_event_handler =
    BroadcastEventHandler([](const std::string& message) {
      std::cout << "Broadcast received: " << message << std::endl;
      if (g_broadcast_received_callback) {
        g_broadcast_received_callback(message.c_str());
      }
    });

FFI_PLUGIN_EXPORT
void broadcast_center_start_listening() {
  g_broadcast_center.RegisterReceiver("com.example.myNotification",
                                      &g_broadcast_event_handler);
}

FFI_PLUGIN_EXPORT
void broadcast_center_stop_listening() {
  g_broadcast_center.UnregisterReceiver("com.example.myNotification",
                                        &g_broadcast_event_handler);
}

FFI_PLUGIN_EXPORT
void broadcast_center_on_broadcast_received(
    BroadcastReceivedCallback callback) {
  g_broadcast_received_callback = callback;
}
