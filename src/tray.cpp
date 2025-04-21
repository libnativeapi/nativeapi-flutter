#include <string.h>
#include <iostream>

#include "libnativeapi/include/nativeapi.h"
#include "tray.h"

using namespace nativeapi;

extern TrayManager g_tray_manager;

Tray* __tray(long tray_id) {
  std::shared_ptr<Tray> tray_ptr = g_tray_manager.Get(tray_id);
  if (tray_ptr != nullptr) {
    return tray_ptr.get();
  }
  return nullptr;
}

FFI_PLUGIN_EXPORT
void tray_set_icon(long tray_id, const char* icon) {
  __tray(tray_id)->SetIcon(icon);
}

FFI_PLUGIN_EXPORT
void tray_set_title(long tray_id, const char* title) {
  __tray(tray_id)->SetTitle(title);
}

FFI_PLUGIN_EXPORT
const char* tray_get_title(long tray_id) {
  static std::string title_storage = __tray(tray_id)->GetTitle();
  return title_storage.c_str();
}

FFI_PLUGIN_EXPORT
void tray_set_tooltip(long tray_id, const char* tooltip) {
  __tray(tray_id)->SetTooltip(tooltip);
}

FFI_PLUGIN_EXPORT
const char* tray_get_tooltip(long tray_id) {
  static std::string tooltip_storage = __tray(tray_id)->GetTooltip();
  return tooltip_storage.c_str();
}

FFI_PLUGIN_EXPORT
void tray_start_listening(long tray_id) {
  // TODO: Implement
}

FFI_PLUGIN_EXPORT
void tray_stop_listening(long tray_id) {
  // TODO: Implement
}
