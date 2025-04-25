#include <string.h>
#include <iostream>

#include "broadcast_center.h"
#include "libnativeapi/include/nativeapi.h"

using namespace nativeapi;

static BroadcastCenter g_broadcast_center = BroadcastCenter();
static std::map<std::string, std::unique_ptr<BroadcastEventHandler>>
    g_broadcast_event_handlers;
static BroadcastReceivedCallback g_broadcast_received_callback = nullptr;

FFI_PLUGIN_EXPORT
void broadcast_center_send_broadcast(const char* topic, const char* message) {
  g_broadcast_center.SendBroadcast(topic, message);
}

FFI_PLUGIN_EXPORT
void broadcast_center_register_receiver(const char* topic) {
  std::unique_ptr<BroadcastEventHandler> broadcast_event_handler =
      std::make_unique<BroadcastEventHandler>(
          [](const std::string& topic, const std::string& message) {
            if (g_broadcast_received_callback) {
              char* topic_cstr = strdup(topic.c_str());
              char* message_cstr = strdup(message.c_str());
              g_broadcast_received_callback(topic_cstr, message_cstr);
            }
          });
  g_broadcast_event_handlers[topic] = std::move(broadcast_event_handler);
  g_broadcast_center.RegisterReceiver(topic,
                                      g_broadcast_event_handlers[topic].get());
}

FFI_PLUGIN_EXPORT
void broadcast_center_unregister_receiver(const char* topic) {
  g_broadcast_center.UnregisterReceiver(
      topic, g_broadcast_event_handlers[topic].get());
  g_broadcast_event_handlers.erase(topic);
}

FFI_PLUGIN_EXPORT
void broadcast_center_on_broadcast_received(
    BroadcastReceivedCallback callback) {
  g_broadcast_received_callback = callback;
}
