// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "tray_icon_c.h"

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
#include "../image.h"
#include "image_c.h"
#include "../menu.h"
#include "menu_c.h"
#include "../tray_icon.h"

native_tray_icon_t native_tray_icon_create(void) {
  try {
    return nativeapi::HandleTable::GetInstance().Insert(
        std::make_shared<nativeapi::TrayIcon>());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_tray_icon_create");
    return 0;
  }
}

native_tray_icon_t native_tray_icon_create_with_tray(void* tray) {
  try {
    return nativeapi::HandleTable::GetInstance().Insert(
        std::make_shared<nativeapi::TrayIcon>(tray));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_tray_icon_create_with_tray");
    return 0;
  }
}

native_tray_icon_id_t native_tray_icon_get_id(native_tray_icon_t tray_icon) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::TrayIcon>(tray_icon);
  if (!self) {
    return 0;
  }
  try {
    return self->GetId();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_tray_icon_get_id");
    return 0;
  }
}

void native_tray_icon_set_icon(native_tray_icon_t tray_icon, native_image_t image) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::TrayIcon>(tray_icon);
  if (!self) {
    return;
  }
  try {
    auto image_cpp = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Image>(image);
    self->SetIcon(image_cpp);
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_tray_icon_set_icon");
    return;
  }
}

native_image_t native_tray_icon_get_icon(native_tray_icon_t tray_icon) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::TrayIcon>(tray_icon);
  if (!self) {
    return 0;
  }
  try {
    return nativeapi::HandleTable::GetInstance().Insert(self->GetIcon());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_tray_icon_get_icon");
    return 0;
  }
}

void native_tray_icon_set_title(native_tray_icon_t tray_icon, const char* title) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::TrayIcon>(tray_icon);
  if (!self) {
    return;
  }
  try {
    std::optional<std::string> title_cpp;
    if (title) {
      title_cpp = std::string(title);
    }
    self->SetTitle(title_cpp);
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_tray_icon_set_title");
    return;
  }
}

char* native_tray_icon_get_title(native_tray_icon_t tray_icon) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::TrayIcon>(tray_icon);
  if (!self) {
    return nullptr;
  }
  try {
    const auto cpp_result = self->GetTitle();
    return cpp_result ? to_c_str(*cpp_result) : nullptr;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_tray_icon_get_title");
    return nullptr;
  }
}

void native_tray_icon_set_tooltip(native_tray_icon_t tray_icon, const char* tooltip) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::TrayIcon>(tray_icon);
  if (!self) {
    return;
  }
  try {
    std::optional<std::string> tooltip_cpp;
    if (tooltip) {
      tooltip_cpp = std::string(tooltip);
    }
    self->SetTooltip(tooltip_cpp);
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_tray_icon_set_tooltip");
    return;
  }
}

char* native_tray_icon_get_tooltip(native_tray_icon_t tray_icon) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::TrayIcon>(tray_icon);
  if (!self) {
    return nullptr;
  }
  try {
    const auto cpp_result = self->GetTooltip();
    return cpp_result ? to_c_str(*cpp_result) : nullptr;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_tray_icon_get_tooltip");
    return nullptr;
  }
}

void native_tray_icon_set_context_menu(native_tray_icon_t tray_icon, native_menu_t menu) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::TrayIcon>(tray_icon);
  if (!self) {
    return;
  }
  try {
    auto menu_cpp = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Menu>(menu);
    self->SetContextMenu(menu_cpp);
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_tray_icon_set_context_menu");
    return;
  }
}

native_menu_t native_tray_icon_get_context_menu(native_tray_icon_t tray_icon) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::TrayIcon>(tray_icon);
  if (!self) {
    return 0;
  }
  try {
    return nativeapi::HandleTable::GetInstance().Insert(self->GetContextMenu());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_tray_icon_get_context_menu");
    return 0;
  }
}

void native_tray_icon_set_context_menu_trigger(native_tray_icon_t tray_icon, native_context_menu_trigger_t trigger) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::TrayIcon>(tray_icon);
  if (!self) {
    return;
  }
  try {
    self->SetContextMenuTrigger(to_cpp_context_menu_trigger(trigger));
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_tray_icon_set_context_menu_trigger");
    return;
  }
}

native_context_menu_trigger_t native_tray_icon_get_context_menu_trigger(native_tray_icon_t tray_icon) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::TrayIcon>(tray_icon);
  if (!self) {
    return (native_context_menu_trigger_t)NATIVE_CONTEXT_MENU_TRIGGER_NONE;
  }
  try {
    return to_c_context_menu_trigger(self->GetContextMenuTrigger());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_tray_icon_get_context_menu_trigger");
    return (native_context_menu_trigger_t)NATIVE_CONTEXT_MENU_TRIGGER_NONE;
  }
}

native_rectangle_t native_tray_icon_get_bounds(native_tray_icon_t tray_icon) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::TrayIcon>(tray_icon);
  if (!self) {
    native_rectangle_t result = {};
    return result;
  }
  try {
    const auto cpp_result = self->GetBounds();
    return to_c_rectangle(cpp_result);
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_tray_icon_get_bounds");
    native_rectangle_t result = {};
    return result;
  }
}

bool native_tray_icon_set_visible(native_tray_icon_t tray_icon, bool visible) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::TrayIcon>(tray_icon);
  if (!self) {
    return false;
  }
  try {
    return self->SetVisible(visible);
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_tray_icon_set_visible");
    return false;
  }
}

bool native_tray_icon_is_visible(native_tray_icon_t tray_icon) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::TrayIcon>(tray_icon);
  if (!self) {
    return false;
  }
  try {
    return self->IsVisible();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_tray_icon_is_visible");
    return false;
  }
}

bool native_tray_icon_open_context_menu(native_tray_icon_t tray_icon) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::TrayIcon>(tray_icon);
  if (!self) {
    return false;
  }
  try {
    return self->OpenContextMenu();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_tray_icon_open_context_menu");
    return false;
  }
}

bool native_tray_icon_close_context_menu(native_tray_icon_t tray_icon) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::TrayIcon>(tray_icon);
  if (!self) {
    return false;
  }
  try {
    return self->CloseContextMenu();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_tray_icon_close_context_menu");
    return false;
  }
}

void* native_tray_icon_get_native_object(native_tray_icon_t tray_icon) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::TrayIcon>(tray_icon);
  if (!self) {
    return nullptr;
  }
  return self->GetNativeObject();
}

void native_tray_icon_free(native_tray_icon_t tray_icon) {
  // The table invalidates the handle itself, so releasing an unknown or
  // already-released one is a no-op rather than a double free.
  nativeapi::HandleTable::GetInstance().Release(tray_icon);
}

void native_tray_icon_list_free(native_tray_icon_list_t* list) {
  if (!list || !list->tray_icons) {
    return;
  }
  for (long i = 0; i < list->count; ++i) {
    nativeapi::HandleTable::GetInstance().Release(list->tray_icons[i]);
  }
  delete[] list->tray_icons;
  list->tray_icons = nullptr;
  list->count = 0;
}

void native_tray_icon_list_release(native_tray_icon_list_t* list) {
  if (!list) {
    return;
  }
  delete[] list->tray_icons;
  list->tray_icons = nullptr;
  list->count = 0;
}

native_listener_id_t native_tray_icon_add_listener(native_tray_icon_t tray_icon, native_tray_icon_event_callback_t callback, void* user_data) {
  if (!callback) {
    return 0;
  }
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::TrayIcon>(tray_icon);
  if (!self) {
    return 0;
  }
  try {
    return static_cast<native_listener_id_t>(self->AddListener<nativeapi::TrayIconEvent>(
        [callback, user_data](const nativeapi::TrayIconEvent& event) {
          native_tray_icon_event_t c_event = {};
          if (!to_c_tray_icon_event(event, &c_event)) {
            return;
          }
          callback(&c_event, user_data);
          free_c_tray_icon_event(&c_event);
        }));
  } catch (...) {
    return 0;
  }
}

bool native_tray_icon_remove_listener(native_tray_icon_t tray_icon, native_listener_id_t listener_id) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::TrayIcon>(tray_icon);
  if (!self) {
    return false;
  }
  try {
    return self->RemoveListener(static_cast<size_t>(listener_id));
  } catch (...) {
    return false;
  }
}

bool to_c_tray_icon_event(const nativeapi::TrayIconEvent& event, native_tray_icon_event_t* out) {
  if (!out) {
    return false;
  }
  *out = native_tray_icon_event_t{};
  if (const auto* typed = dynamic_cast<const nativeapi::TrayIconClickedEvent*>(&event)) {
    out->type = NATIVE_TRAY_ICON_EVENT_TYPE_CLICKED;
    out->data.clicked.tray_icon_id = typed->GetTrayIconId();
    return true;
  }
  if (const auto* typed = dynamic_cast<const nativeapi::TrayIconRightClickedEvent*>(&event)) {
    out->type = NATIVE_TRAY_ICON_EVENT_TYPE_RIGHT_CLICKED;
    out->data.right_clicked.tray_icon_id = typed->GetTrayIconId();
    return true;
  }
  if (const auto* typed = dynamic_cast<const nativeapi::TrayIconDoubleClickedEvent*>(&event)) {
    out->type = NATIVE_TRAY_ICON_EVENT_TYPE_DOUBLE_CLICKED;
    out->data.double_clicked.tray_icon_id = typed->GetTrayIconId();
    return true;
  }
  return false;
}

void free_c_tray_icon_event(native_tray_icon_event_t* value) {
  if (!value) {
    return;
  }
}

