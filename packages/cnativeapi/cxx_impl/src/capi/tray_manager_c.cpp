// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "tray_manager_c.h"

#include <cstdio>
#include <memory>
#include <new>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "string_utils_c.h"
#include "../foundation/handle_table.h"
#include "../tray_icon.h"
#include "tray_icon_c.h"
#include "../tray_manager.h"

bool native_tray_manager_is_supported(void) {
  try {
    return nativeapi::TrayManager::GetInstance().IsSupported();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_tray_manager_is_supported");
    return false;
  }
}

native_tray_icon_t native_tray_manager_get(native_tray_icon_id_t id) {
  try {
    return nativeapi::HandleTable::GetInstance().Insert(nativeapi::TrayManager::GetInstance().Get(id));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_tray_manager_get");
    return 0;
  }
}

native_tray_icon_list_t native_tray_manager_get_all(void) {
  try {
    const auto items = nativeapi::TrayManager::GetInstance().GetAll();
    native_tray_icon_list_t list = {};
    if (items.empty()) {
      return list;
    }
    list.tray_icons = new (std::nothrow) native_tray_icon_t[items.size()];
    if (!list.tray_icons) {
      return list;
    }
    for (size_t i = 0; i < items.size(); ++i) {
      list.tray_icons[i] = nativeapi::HandleTable::GetInstance().Insert(items[i]);
    }
    list.count = static_cast<long>(items.size());
    return list;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_tray_manager_get_all");
    native_tray_icon_list_t empty = {};
    return empty;
  }
}

