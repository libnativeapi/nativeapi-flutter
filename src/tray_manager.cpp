#include <string.h>
#include <iostream>

#include "libnativeapi/include/nativeapi.h"
#include "tray_manager.h"

using namespace nativeapi;

TrayManager g_tray_manager = TrayManager();

FFI_PLUGIN_EXPORT
struct NativeTrayIDList tray_manager_get_all() {
  auto trays = g_tray_manager.GetAll();
  NativeTrayIDList native_tray_id_list;
  native_tray_id_list.count = trays.size();
  for (size_t i = 0; i < trays.size(); i++) {
    native_tray_id_list.ids[i] = trays[i]->id;
  }
  return native_tray_id_list;
}

FFI_PLUGIN_EXPORT
long tray_manager_create() {
  auto tray = g_tray_manager.Create();
  return tray->id;
}

FFI_PLUGIN_EXPORT
void tray_manager_start_listening() {
  // TODO: Implement
}

FFI_PLUGIN_EXPORT
void tray_manager_stop_listening() {
  // TODO: Implement
}
