// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "shortcut_manager_c.h"

#include <cstdio>
#include <memory>
#include <new>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "string_utils_c.h"
#include "../foundation/handle_table.h"
#include "../shortcut.h"
#include "shortcut_c.h"
#include "../shortcut_manager.h"

bool native_shortcut_manager_is_supported(void) {
  try {
    return nativeapi::ShortcutManager::GetInstance().IsSupported();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_shortcut_manager_is_supported");
    return false;
  }
}

native_shortcut_t native_shortcut_manager_register_with_accelerator_and_callback(const char* accelerator, native_shortcut_manager_register_callback_t callback, void* callback_user_data) {
  try {
    std::function<void()> callback_cpp;
    if (callback) {
      callback_cpp = [callback, callback_user_data]() { callback(callback_user_data); };
    }
    return nativeapi::HandleTable::GetInstance().Insert(nativeapi::ShortcutManager::GetInstance().Register(std::string(accelerator ? accelerator : ""), callback_cpp));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_shortcut_manager_register_with_accelerator_and_callback");
    return 0;
  }
}

native_shortcut_t native_shortcut_manager_register_with_options(native_shortcut_options_t options) {
  try {
    auto options_cpp = to_cpp_shortcut_options(options);
    return nativeapi::HandleTable::GetInstance().Insert(nativeapi::ShortcutManager::GetInstance().Register(options_cpp));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_shortcut_manager_register_with_options");
    return 0;
  }
}

bool native_shortcut_manager_unregister_with_id(native_shortcut_id_t id) {
  try {
    return nativeapi::ShortcutManager::GetInstance().Unregister(id);
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_shortcut_manager_unregister_with_id");
    return false;
  }
}

bool native_shortcut_manager_unregister_with_accelerator(const char* accelerator) {
  try {
    return nativeapi::ShortcutManager::GetInstance().Unregister(std::string(accelerator ? accelerator : ""));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_shortcut_manager_unregister_with_accelerator");
    return false;
  }
}

int native_shortcut_manager_unregister_all(void) {
  try {
    return nativeapi::ShortcutManager::GetInstance().UnregisterAll();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_shortcut_manager_unregister_all");
    return 0;
  }
}

native_shortcut_t native_shortcut_manager_get_with_id(native_shortcut_id_t id) {
  try {
    return nativeapi::HandleTable::GetInstance().Insert(nativeapi::ShortcutManager::GetInstance().Get(id));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_shortcut_manager_get_with_id");
    return 0;
  }
}

native_shortcut_t native_shortcut_manager_get_with_accelerator(const char* accelerator) {
  try {
    return nativeapi::HandleTable::GetInstance().Insert(nativeapi::ShortcutManager::GetInstance().Get(std::string(accelerator ? accelerator : "")));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_shortcut_manager_get_with_accelerator");
    return 0;
  }
}

native_shortcut_list_t native_shortcut_manager_get_all(void) {
  try {
    const auto items = nativeapi::ShortcutManager::GetInstance().GetAll();
    native_shortcut_list_t list = {};
    if (items.empty()) {
      return list;
    }
    list.shortcuts = new (std::nothrow) native_shortcut_t[items.size()];
    if (!list.shortcuts) {
      return list;
    }
    for (size_t i = 0; i < items.size(); ++i) {
      list.shortcuts[i] = nativeapi::HandleTable::GetInstance().Insert(items[i]);
    }
    list.count = static_cast<long>(items.size());
    return list;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_shortcut_manager_get_all");
    native_shortcut_list_t empty = {};
    return empty;
  }
}

native_shortcut_list_t native_shortcut_manager_get_by_scope(native_shortcut_scope_t scope) {
  try {
    const auto items = nativeapi::ShortcutManager::GetInstance().GetByScope(to_cpp_shortcut_scope(scope));
    native_shortcut_list_t list = {};
    if (items.empty()) {
      return list;
    }
    list.shortcuts = new (std::nothrow) native_shortcut_t[items.size()];
    if (!list.shortcuts) {
      return list;
    }
    for (size_t i = 0; i < items.size(); ++i) {
      list.shortcuts[i] = nativeapi::HandleTable::GetInstance().Insert(items[i]);
    }
    list.count = static_cast<long>(items.size());
    return list;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_shortcut_manager_get_by_scope");
    native_shortcut_list_t empty = {};
    return empty;
  }
}

bool native_shortcut_manager_is_available(const char* accelerator) {
  try {
    return nativeapi::ShortcutManager::GetInstance().IsAvailable(std::string(accelerator ? accelerator : ""));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_shortcut_manager_is_available");
    return false;
  }
}

bool native_shortcut_manager_is_valid_accelerator(const char* accelerator) {
  try {
    return nativeapi::ShortcutManager::GetInstance().IsValidAccelerator(std::string(accelerator ? accelerator : ""));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_shortcut_manager_is_valid_accelerator");
    return false;
  }
}

void native_shortcut_manager_set_enabled(bool enabled) {
  try {
    nativeapi::ShortcutManager::GetInstance().SetEnabled(enabled);
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_shortcut_manager_set_enabled");
    return;
  }
}

bool native_shortcut_manager_is_enabled(void) {
  try {
    return nativeapi::ShortcutManager::GetInstance().IsEnabled();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_shortcut_manager_is_enabled");
    return false;
  }
}

void native_shortcut_manager_emit_shortcut_activated(native_shortcut_id_t id, const char* accelerator) {
  try {
    nativeapi::ShortcutManager::GetInstance().EmitShortcutActivated(id, std::string(accelerator ? accelerator : ""));
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_shortcut_manager_emit_shortcut_activated");
    return;
  }
}

native_listener_id_t native_shortcut_manager_add_listener(native_shortcut_event_callback_t callback, void* user_data) {
  if (!callback) {
    return 0;
  }
  try {
    return static_cast<native_listener_id_t>(nativeapi::ShortcutManager::GetInstance().AddListener<nativeapi::ShortcutEvent>(
        [callback, user_data](const nativeapi::ShortcutEvent& event) {
          native_shortcut_event_t c_event = {};
          if (!to_c_shortcut_event(event, &c_event)) {
            return;
          }
          callback(&c_event, user_data);
          free_c_shortcut_event(&c_event);
        }));
  } catch (...) {
    return 0;
  }
}

bool native_shortcut_manager_remove_listener(native_listener_id_t listener_id) {
  try {
    return nativeapi::ShortcutManager::GetInstance().RemoveListener(static_cast<size_t>(listener_id));
  } catch (...) {
    return false;
  }
}

