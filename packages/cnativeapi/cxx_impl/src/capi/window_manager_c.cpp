// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "window_manager_c.h"

#include <cstdio>
#include <memory>
#include <new>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "string_utils_c.h"
#include "../foundation/handle_table.h"
#include "../window.h"
#include "window_c.h"
#include "../window_manager.h"

native_window_t native_window_manager_get(native_window_id_t id) {
  try {
    return nativeapi::HandleTable::GetInstance().Insert(nativeapi::WindowManager::GetInstance().Get(id));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_window_manager_get");
    return 0;
  }
}

native_window_list_t native_window_manager_get_all(void) {
  try {
    const auto items = nativeapi::WindowManager::GetInstance().GetAll();
    native_window_list_t list = {};
    if (items.empty()) {
      return list;
    }
    list.windows = new (std::nothrow) native_window_t[items.size()];
    if (!list.windows) {
      return list;
    }
    for (size_t i = 0; i < items.size(); ++i) {
      list.windows[i] = nativeapi::HandleTable::GetInstance().Insert(items[i]);
    }
    list.count = static_cast<long>(items.size());
    return list;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_window_manager_get_all");
    native_window_list_t empty = {};
    return empty;
  }
}

native_window_t native_window_manager_get_current(void) {
  try {
    return nativeapi::HandleTable::GetInstance().Insert(nativeapi::WindowManager::GetInstance().GetCurrent());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_window_manager_get_current");
    return 0;
  }
}

void native_window_manager_set_will_show_hook(native_window_manager_set_will_show_hook_callback_t hook, void* hook_user_data) {
  try {
    std::optional<std::function<void(unsigned int)>> hook_cpp;
    if (hook) {
      hook_cpp = [hook, hook_user_data](unsigned int arg0) { hook(arg0, hook_user_data); };
    }
    nativeapi::WindowManager::GetInstance().SetWillShowHook(hook_cpp);
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_window_manager_set_will_show_hook");
    return;
  }
}

void native_window_manager_set_will_hide_hook(native_window_manager_set_will_hide_hook_callback_t hook, void* hook_user_data) {
  try {
    std::optional<std::function<void(unsigned int)>> hook_cpp;
    if (hook) {
      hook_cpp = [hook, hook_user_data](unsigned int arg0) { hook(arg0, hook_user_data); };
    }
    nativeapi::WindowManager::GetInstance().SetWillHideHook(hook_cpp);
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_window_manager_set_will_hide_hook");
    return;
  }
}

void native_window_manager_set_will_close_hook(native_window_manager_set_will_close_hook_callback_t hook, void* hook_user_data) {
  try {
    std::optional<std::function<void(unsigned int)>> hook_cpp;
    if (hook) {
      hook_cpp = [hook, hook_user_data](unsigned int arg0) { hook(arg0, hook_user_data); };
    }
    nativeapi::WindowManager::GetInstance().SetWillCloseHook(hook_cpp);
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_window_manager_set_will_close_hook");
    return;
  }
}

bool native_window_manager_has_will_show_hook(void) {
  try {
    return nativeapi::WindowManager::GetInstance().HasWillShowHook();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_window_manager_has_will_show_hook");
    return false;
  }
}

bool native_window_manager_has_will_hide_hook(void) {
  try {
    return nativeapi::WindowManager::GetInstance().HasWillHideHook();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_window_manager_has_will_hide_hook");
    return false;
  }
}

bool native_window_manager_has_will_close_hook(void) {
  try {
    return nativeapi::WindowManager::GetInstance().HasWillCloseHook();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_window_manager_has_will_close_hook");
    return false;
  }
}

void native_window_manager_handle_will_show(native_window_id_t id) {
  try {
    nativeapi::WindowManager::GetInstance().HandleWillShow(id);
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_window_manager_handle_will_show");
    return;
  }
}

void native_window_manager_handle_will_hide(native_window_id_t id) {
  try {
    nativeapi::WindowManager::GetInstance().HandleWillHide(id);
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_window_manager_handle_will_hide");
    return;
  }
}

void native_window_manager_handle_will_close(native_window_id_t id) {
  try {
    nativeapi::WindowManager::GetInstance().HandleWillClose(id);
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_window_manager_handle_will_close");
    return;
  }
}

bool native_window_manager_call_original_show(native_window_id_t id) {
  try {
    return nativeapi::WindowManager::GetInstance().CallOriginalShow(id);
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_window_manager_call_original_show");
    return false;
  }
}

bool native_window_manager_call_original_hide(native_window_id_t id) {
  try {
    return nativeapi::WindowManager::GetInstance().CallOriginalHide(id);
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_window_manager_call_original_hide");
    return false;
  }
}

bool native_window_manager_call_original_close(native_window_id_t id) {
  try {
    return nativeapi::WindowManager::GetInstance().CallOriginalClose(id);
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_window_manager_call_original_close");
    return false;
  }
}

native_listener_id_t native_window_manager_add_listener(native_window_event_callback_t callback, void* user_data) {
  if (!callback) {
    return 0;
  }
  try {
    return static_cast<native_listener_id_t>(nativeapi::WindowManager::GetInstance().AddListener<nativeapi::WindowEvent>(
        [callback, user_data](const nativeapi::WindowEvent& event) {
          native_window_event_t c_event = {};
          if (!to_c_window_event(event, &c_event)) {
            return;
          }
          callback(&c_event, user_data);
          free_c_window_event(&c_event);
        }));
  } catch (...) {
    return 0;
  }
}

bool native_window_manager_remove_listener(native_listener_id_t listener_id) {
  try {
    return nativeapi::WindowManager::GetInstance().RemoveListener(static_cast<size_t>(listener_id));
  } catch (...) {
    return false;
  }
}

