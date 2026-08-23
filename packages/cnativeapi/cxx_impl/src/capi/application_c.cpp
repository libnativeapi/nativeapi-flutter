// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "application_c.h"

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
#include "../menu.h"
#include "menu_c.h"
#include "../application.h"

int native_application_run(void) {
  try {
    return nativeapi::Application::GetInstance().Run();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_application_run");
    return 0;
  }
}

int native_application_run_with_window(native_window_t window) {
  try {
    auto window_cpp = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Window>(window);
    return nativeapi::Application::GetInstance().Run(window_cpp);
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_application_run_with_window");
    return 0;
  }
}

void native_application_quit(int exit_code) {
  try {
    nativeapi::Application::GetInstance().Quit(exit_code);
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_application_quit");
    return;
  }
}

bool native_application_is_running(void) {
  try {
    return nativeapi::Application::GetInstance().IsRunning();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_application_is_running");
    return false;
  }
}

bool native_application_is_single_instance(void) {
  try {
    return nativeapi::Application::GetInstance().IsSingleInstance();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_application_is_single_instance");
    return false;
  }
}

bool native_application_set_icon(const char* icon_path) {
  try {
    return nativeapi::Application::GetInstance().SetIcon(std::string(icon_path ? icon_path : ""));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_application_set_icon");
    return false;
  }
}

bool native_application_set_dock_icon_visible(bool visible) {
  try {
    return nativeapi::Application::GetInstance().SetDockIconVisible(visible);
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_application_set_dock_icon_visible");
    return false;
  }
}

bool native_application_set_menu_bar(native_menu_t menu) {
  try {
    auto menu_cpp = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Menu>(menu);
    return nativeapi::Application::GetInstance().SetMenuBar(menu_cpp);
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_application_set_menu_bar");
    return false;
  }
}

native_window_t native_application_get_primary_window(void) {
  try {
    return nativeapi::HandleTable::GetInstance().Insert(nativeapi::Application::GetInstance().GetPrimaryWindow());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_application_get_primary_window");
    return 0;
  }
}

void native_application_set_primary_window(native_window_t window) {
  try {
    auto window_cpp = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Window>(window);
    nativeapi::Application::GetInstance().SetPrimaryWindow(window_cpp);
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_application_set_primary_window");
    return;
  }
}

native_window_list_t native_application_get_all_windows(void) {
  try {
    const auto items = nativeapi::Application::GetInstance().GetAllWindows();
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
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_application_get_all_windows");
    native_window_list_t empty = {};
    return empty;
  }
}

native_listener_id_t native_application_add_listener(native_application_event_callback_t callback, void* user_data) {
  if (!callback) {
    return 0;
  }
  try {
    return static_cast<native_listener_id_t>(nativeapi::Application::GetInstance().AddListener<nativeapi::ApplicationEvent>(
        [callback, user_data](const nativeapi::ApplicationEvent& event) {
          native_application_event_t c_event = {};
          if (!to_c_application_event(event, &c_event)) {
            return;
          }
          callback(&c_event, user_data);
          free_c_application_event(&c_event);
        }));
  } catch (...) {
    return 0;
  }
}

bool native_application_remove_listener(native_listener_id_t listener_id) {
  try {
    return nativeapi::Application::GetInstance().RemoveListener(static_cast<size_t>(listener_id));
  } catch (...) {
    return false;
  }
}

bool to_c_application_event(const nativeapi::ApplicationEvent& event, native_application_event_t* out) {
  if (!out) {
    return false;
  }
  *out = native_application_event_t{};
  if (const auto* typed = dynamic_cast<const nativeapi::ApplicationStartedEvent*>(&event)) {
    out->type = NATIVE_APPLICATION_EVENT_TYPE_STARTED;
    (void)typed;
    return true;
  }
  if (const auto* typed = dynamic_cast<const nativeapi::ApplicationExitingEvent*>(&event)) {
    out->type = NATIVE_APPLICATION_EVENT_TYPE_EXITING;
    out->data.exiting.exit_code = typed->GetExitCode();
    return true;
  }
  if (const auto* typed = dynamic_cast<const nativeapi::ApplicationActivatedEvent*>(&event)) {
    out->type = NATIVE_APPLICATION_EVENT_TYPE_ACTIVATED;
    (void)typed;
    return true;
  }
  if (const auto* typed = dynamic_cast<const nativeapi::ApplicationDeactivatedEvent*>(&event)) {
    out->type = NATIVE_APPLICATION_EVENT_TYPE_DEACTIVATED;
    (void)typed;
    return true;
  }
  if (const auto* typed = dynamic_cast<const nativeapi::ApplicationQuitRequestedEvent*>(&event)) {
    out->type = NATIVE_APPLICATION_EVENT_TYPE_QUIT_REQUESTED;
    (void)typed;
    return true;
  }
  return false;
}

void free_c_application_event(native_application_event_t* value) {
  if (!value) {
    return;
  }
}

