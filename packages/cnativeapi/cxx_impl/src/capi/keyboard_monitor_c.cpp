// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "keyboard_monitor_c.h"

#include <cstdio>
#include <memory>
#include <new>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "string_utils_c.h"
#include "../foundation/handle_table.h"
#include "../foundation/keyboard.h"
#include "keyboard_c.h"
#include "../keyboard_monitor.h"

native_keyboard_monitor_t native_keyboard_monitor_create(void) {
  try {
    return nativeapi::HandleTable::GetInstance().Insert(
        std::make_shared<nativeapi::KeyboardMonitor>());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_keyboard_monitor_create");
    return 0;
  }
}

void native_keyboard_monitor_start(native_keyboard_monitor_t keyboard_monitor) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::KeyboardMonitor>(keyboard_monitor);
  if (!self) {
    return;
  }
  try {
    self->Start();
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_keyboard_monitor_start");
    return;
  }
}

void native_keyboard_monitor_stop(native_keyboard_monitor_t keyboard_monitor) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::KeyboardMonitor>(keyboard_monitor);
  if (!self) {
    return;
  }
  try {
    self->Stop();
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_keyboard_monitor_stop");
    return;
  }
}

bool native_keyboard_monitor_is_monitoring(native_keyboard_monitor_t keyboard_monitor) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::KeyboardMonitor>(keyboard_monitor);
  if (!self) {
    return false;
  }
  try {
    return self->IsMonitoring();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_keyboard_monitor_is_monitoring");
    return false;
  }
}

void native_keyboard_monitor_free(native_keyboard_monitor_t keyboard_monitor) {
  // The table invalidates the handle itself, so releasing an unknown or
  // already-released one is a no-op rather than a double free.
  nativeapi::HandleTable::GetInstance().Release(keyboard_monitor);
}

native_listener_id_t native_keyboard_monitor_add_listener(native_keyboard_monitor_t keyboard_monitor, native_keyboard_event_callback_t callback, void* user_data) {
  if (!callback) {
    return 0;
  }
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::KeyboardMonitor>(keyboard_monitor);
  if (!self) {
    return 0;
  }
  try {
    return static_cast<native_listener_id_t>(self->AddListener<nativeapi::KeyboardEvent>(
        [callback, user_data](const nativeapi::KeyboardEvent& event) {
          native_keyboard_event_t c_event = {};
          if (!to_c_keyboard_event(event, &c_event)) {
            return;
          }
          callback(&c_event, user_data);
          free_c_keyboard_event(&c_event);
        }));
  } catch (...) {
    return 0;
  }
}

bool native_keyboard_monitor_remove_listener(native_keyboard_monitor_t keyboard_monitor, native_listener_id_t listener_id) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::KeyboardMonitor>(keyboard_monitor);
  if (!self) {
    return false;
  }
  try {
    return self->RemoveListener(static_cast<size_t>(listener_id));
  } catch (...) {
    return false;
  }
}

