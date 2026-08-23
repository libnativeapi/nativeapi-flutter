// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "display_manager_c.h"

#include <cstdio>
#include <memory>
#include <new>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "string_utils_c.h"
#include "../foundation/handle_table.h"
#include "../foundation/geometry.h"
#include "geometry_c.h"
#include "../display.h"
#include "display_c.h"
#include "../display_manager.h"

native_display_list_t native_display_manager_get_all(void) {
  try {
    const auto items = nativeapi::DisplayManager::GetInstance().GetAll();
    native_display_list_t list = {};
    if (items.empty()) {
      return list;
    }
    list.displays = new (std::nothrow) native_display_t[items.size()];
    if (!list.displays) {
      return list;
    }
    for (size_t i = 0; i < items.size(); ++i) {
      list.displays[i] = nativeapi::HandleTable::GetInstance().Insert(items[i]);
    }
    list.count = static_cast<long>(items.size());
    return list;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_display_manager_get_all");
    native_display_list_t empty = {};
    return empty;
  }
}

native_display_t native_display_manager_get_primary(void) {
  try {
    return nativeapi::HandleTable::GetInstance().Insert(nativeapi::DisplayManager::GetInstance().GetPrimary());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_display_manager_get_primary");
    return 0;
  }
}

native_point_t native_display_manager_get_cursor_position(void) {
  try {
    const auto cpp_result = nativeapi::DisplayManager::GetInstance().GetCursorPosition();
    return to_c_point(cpp_result);
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_display_manager_get_cursor_position");
    native_point_t result = {};
    return result;
  }
}

native_listener_id_t native_display_manager_add_listener(native_display_event_callback_t callback, void* user_data) {
  if (!callback) {
    return 0;
  }
  try {
    return static_cast<native_listener_id_t>(nativeapi::DisplayManager::GetInstance().AddListener<nativeapi::DisplayEvent>(
        [callback, user_data](const nativeapi::DisplayEvent& event) {
          native_display_event_t c_event = {};
          if (!to_c_display_event(event, &c_event)) {
            return;
          }
          callback(&c_event, user_data);
          free_c_display_event(&c_event);
        }));
  } catch (...) {
    return 0;
  }
}

bool native_display_manager_remove_listener(native_listener_id_t listener_id) {
  try {
    return nativeapi::DisplayManager::GetInstance().RemoveListener(static_cast<size_t>(listener_id));
  } catch (...) {
    return false;
  }
}

