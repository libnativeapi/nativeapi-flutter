// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "menu_c.h"

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
#include "../placement.h"
#include "placement_c.h"
#include "../image.h"
#include "image_c.h"
#include "../positioning_strategy.h"
#include "positioning_strategy_c.h"
#include "../menu.h"

native_menu_item_t native_menu_item_create_with_label_and_type(const char* label, native_menu_item_type_t type) {
  try {
    return nativeapi::HandleTable::GetInstance().Insert(
        std::make_shared<nativeapi::MenuItem>(std::string(label ? label : ""), to_cpp_menu_item_type(type)));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_item_create_with_label_and_type");
    return 0;
  }
}

native_menu_item_t native_menu_item_create_with_native_item(void* native_item) {
  try {
    return nativeapi::HandleTable::GetInstance().Insert(
        std::make_shared<nativeapi::MenuItem>(native_item));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_item_create_with_native_item");
    return 0;
  }
}

native_menu_item_id_t native_menu_item_get_id(native_menu_item_t menu_item) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MenuItem>(menu_item);
  if (!self) {
    return 0;
  }
  try {
    return self->GetId();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_item_get_id");
    return 0;
  }
}

native_menu_item_type_t native_menu_item_get_type(native_menu_item_t menu_item) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MenuItem>(menu_item);
  if (!self) {
    return (native_menu_item_type_t)NATIVE_MENU_ITEM_TYPE_NORMAL;
  }
  try {
    return to_c_menu_item_type(self->GetType());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_item_get_type");
    return (native_menu_item_type_t)NATIVE_MENU_ITEM_TYPE_NORMAL;
  }
}

void native_menu_item_set_label(native_menu_item_t menu_item, const char* label) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MenuItem>(menu_item);
  if (!self) {
    return;
  }
  try {
    std::optional<std::string> label_cpp;
    if (label) {
      label_cpp = std::string(label);
    }
    self->SetLabel(label_cpp);
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_item_set_label");
    return;
  }
}

char* native_menu_item_get_label(native_menu_item_t menu_item) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MenuItem>(menu_item);
  if (!self) {
    return nullptr;
  }
  try {
    const auto cpp_result = self->GetLabel();
    return cpp_result ? to_c_str(*cpp_result) : nullptr;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_item_get_label");
    return nullptr;
  }
}

void native_menu_item_set_icon(native_menu_item_t menu_item, native_image_t image) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MenuItem>(menu_item);
  if (!self) {
    return;
  }
  try {
    auto image_cpp = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Image>(image);
    self->SetIcon(image_cpp);
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_item_set_icon");
    return;
  }
}

native_image_t native_menu_item_get_icon(native_menu_item_t menu_item) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MenuItem>(menu_item);
  if (!self) {
    return 0;
  }
  try {
    return nativeapi::HandleTable::GetInstance().Insert(self->GetIcon());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_item_get_icon");
    return 0;
  }
}

void native_menu_item_set_tooltip(native_menu_item_t menu_item, const char* tooltip) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MenuItem>(menu_item);
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
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_item_set_tooltip");
    return;
  }
}

char* native_menu_item_get_tooltip(native_menu_item_t menu_item) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MenuItem>(menu_item);
  if (!self) {
    return nullptr;
  }
  try {
    const auto cpp_result = self->GetTooltip();
    return cpp_result ? to_c_str(*cpp_result) : nullptr;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_item_get_tooltip");
    return nullptr;
  }
}

void native_menu_item_set_accelerator(native_menu_item_t menu_item, const native_keyboard_accelerator_t* accelerator) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MenuItem>(menu_item);
  if (!self) {
    return;
  }
  try {
    std::optional<nativeapi::KeyboardAccelerator> accelerator_cpp;
    if (accelerator) {
      accelerator_cpp = to_cpp_keyboard_accelerator(*accelerator);
    }
    self->SetAccelerator(accelerator_cpp);
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_item_set_accelerator");
    return;
  }
}

native_keyboard_accelerator_t native_menu_item_get_accelerator(native_menu_item_t menu_item) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MenuItem>(menu_item);
  if (!self) {
    native_keyboard_accelerator_t result = {};
    return result;
  }
  try {
    const auto cpp_result = self->GetAccelerator();
    return to_c_keyboard_accelerator(cpp_result);
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_item_get_accelerator");
    native_keyboard_accelerator_t result = {};
    return result;
  }
}

void native_menu_item_set_enabled(native_menu_item_t menu_item, bool enabled) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MenuItem>(menu_item);
  if (!self) {
    return;
  }
  try {
    self->SetEnabled(enabled);
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_item_set_enabled");
    return;
  }
}

bool native_menu_item_is_enabled(native_menu_item_t menu_item) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MenuItem>(menu_item);
  if (!self) {
    return false;
  }
  try {
    return self->IsEnabled();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_item_is_enabled");
    return false;
  }
}

void native_menu_item_set_state(native_menu_item_t menu_item, native_menu_item_state_t state) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MenuItem>(menu_item);
  if (!self) {
    return;
  }
  try {
    self->SetState(to_cpp_menu_item_state(state));
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_item_set_state");
    return;
  }
}

native_menu_item_state_t native_menu_item_get_state(native_menu_item_t menu_item) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MenuItem>(menu_item);
  if (!self) {
    return (native_menu_item_state_t)NATIVE_MENU_ITEM_STATE_UNCHECKED;
  }
  try {
    return to_c_menu_item_state(self->GetState());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_item_get_state");
    return (native_menu_item_state_t)NATIVE_MENU_ITEM_STATE_UNCHECKED;
  }
}

void native_menu_item_set_radio_group(native_menu_item_t menu_item, int group_id) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MenuItem>(menu_item);
  if (!self) {
    return;
  }
  try {
    self->SetRadioGroup(group_id);
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_item_set_radio_group");
    return;
  }
}

int native_menu_item_get_radio_group(native_menu_item_t menu_item) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MenuItem>(menu_item);
  if (!self) {
    return 0;
  }
  try {
    return self->GetRadioGroup();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_item_get_radio_group");
    return 0;
  }
}

void native_menu_item_set_submenu(native_menu_item_t menu_item, native_menu_t submenu) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MenuItem>(menu_item);
  if (!self) {
    return;
  }
  try {
    auto submenu_cpp = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Menu>(submenu);
    self->SetSubmenu(submenu_cpp);
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_item_set_submenu");
    return;
  }
}

native_menu_t native_menu_item_get_submenu(native_menu_item_t menu_item) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MenuItem>(menu_item);
  if (!self) {
    return 0;
  }
  try {
    return nativeapi::HandleTable::GetInstance().Insert(self->GetSubmenu());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_item_get_submenu");
    return 0;
  }
}

void* native_menu_item_get_native_object(native_menu_item_t menu_item) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MenuItem>(menu_item);
  if (!self) {
    return nullptr;
  }
  return self->GetNativeObject();
}

void native_menu_item_free(native_menu_item_t menu_item) {
  // The table invalidates the handle itself, so releasing an unknown or
  // already-released one is a no-op rather than a double free.
  nativeapi::HandleTable::GetInstance().Release(menu_item);
}

void native_menu_item_list_free(native_menu_item_list_t* list) {
  if (!list || !list->menu_items) {
    return;
  }
  for (long i = 0; i < list->count; ++i) {
    nativeapi::HandleTable::GetInstance().Release(list->menu_items[i]);
  }
  delete[] list->menu_items;
  list->menu_items = nullptr;
  list->count = 0;
}

void native_menu_item_list_release(native_menu_item_list_t* list) {
  if (!list) {
    return;
  }
  delete[] list->menu_items;
  list->menu_items = nullptr;
  list->count = 0;
}

native_listener_id_t native_menu_item_add_listener(native_menu_item_t menu_item, native_menu_event_callback_t callback, void* user_data) {
  if (!callback) {
    return 0;
  }
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MenuItem>(menu_item);
  if (!self) {
    return 0;
  }
  try {
    return static_cast<native_listener_id_t>(self->AddListener<nativeapi::MenuEvent>(
        [callback, user_data](const nativeapi::MenuEvent& event) {
          native_menu_event_t c_event = {};
          if (!to_c_menu_event(event, &c_event)) {
            return;
          }
          callback(&c_event, user_data);
          free_c_menu_event(&c_event);
        }));
  } catch (...) {
    return 0;
  }
}

bool native_menu_item_remove_listener(native_menu_item_t menu_item, native_listener_id_t listener_id) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MenuItem>(menu_item);
  if (!self) {
    return false;
  }
  try {
    return self->RemoveListener(static_cast<size_t>(listener_id));
  } catch (...) {
    return false;
  }
}

native_menu_t native_menu_create(void) {
  try {
    return nativeapi::HandleTable::GetInstance().Insert(
        std::make_shared<nativeapi::Menu>());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_create");
    return 0;
  }
}

native_menu_t native_menu_create_with_native_menu(void* native_menu) {
  try {
    return nativeapi::HandleTable::GetInstance().Insert(
        std::make_shared<nativeapi::Menu>(native_menu));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_create_with_native_menu");
    return 0;
  }
}

native_menu_id_t native_menu_get_id(native_menu_t menu) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Menu>(menu);
  if (!self) {
    return 0;
  }
  try {
    return self->GetId();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_get_id");
    return 0;
  }
}

void native_menu_add_item(native_menu_t menu, native_menu_item_t item) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Menu>(menu);
  if (!self) {
    return;
  }
  try {
    auto item_cpp = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MenuItem>(item);
    self->AddItem(item_cpp);
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_add_item");
    return;
  }
}

void native_menu_insert_item(native_menu_t menu, unsigned long index, native_menu_item_t item) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Menu>(menu);
  if (!self) {
    return;
  }
  try {
    auto item_cpp = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MenuItem>(item);
    self->InsertItem(index, item_cpp);
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_insert_item");
    return;
  }
}

bool native_menu_remove_item(native_menu_t menu, native_menu_item_t item) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Menu>(menu);
  if (!self) {
    return false;
  }
  try {
    auto item_cpp = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MenuItem>(item);
    return self->RemoveItem(item_cpp);
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_remove_item");
    return false;
  }
}

bool native_menu_remove_item_by_id(native_menu_t menu, native_menu_item_id_t item_id) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Menu>(menu);
  if (!self) {
    return false;
  }
  try {
    return self->RemoveItemById(item_id);
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_remove_item_by_id");
    return false;
  }
}

bool native_menu_remove_item_at(native_menu_t menu, unsigned long index) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Menu>(menu);
  if (!self) {
    return false;
  }
  try {
    return self->RemoveItemAt(index);
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_remove_item_at");
    return false;
  }
}

void native_menu_clear(native_menu_t menu) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Menu>(menu);
  if (!self) {
    return;
  }
  try {
    self->Clear();
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_clear");
    return;
  }
}

void native_menu_add_separator(native_menu_t menu) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Menu>(menu);
  if (!self) {
    return;
  }
  try {
    self->AddSeparator();
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_add_separator");
    return;
  }
}

void native_menu_insert_separator(native_menu_t menu, unsigned long index) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Menu>(menu);
  if (!self) {
    return;
  }
  try {
    self->InsertSeparator(index);
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_insert_separator");
    return;
  }
}

unsigned long native_menu_get_item_count(native_menu_t menu) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Menu>(menu);
  if (!self) {
    return 0;
  }
  try {
    return self->GetItemCount();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_get_item_count");
    return 0;
  }
}

native_menu_item_t native_menu_get_item_at(native_menu_t menu, unsigned long index) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Menu>(menu);
  if (!self) {
    return 0;
  }
  try {
    return nativeapi::HandleTable::GetInstance().Insert(self->GetItemAt(index));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_get_item_at");
    return 0;
  }
}

native_menu_item_t native_menu_get_item_by_id(native_menu_t menu, native_menu_item_id_t item_id) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Menu>(menu);
  if (!self) {
    return 0;
  }
  try {
    return nativeapi::HandleTable::GetInstance().Insert(self->GetItemById(item_id));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_get_item_by_id");
    return 0;
  }
}

native_menu_item_list_t native_menu_get_all_items(native_menu_t menu) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Menu>(menu);
  if (!self) {
    native_menu_item_list_t empty = {};
    return empty;
  }
  try {
    const auto items = self->GetAllItems();
    native_menu_item_list_t list = {};
    if (items.empty()) {
      return list;
    }
    list.menu_items = new (std::nothrow) native_menu_item_t[items.size()];
    if (!list.menu_items) {
      return list;
    }
    for (size_t i = 0; i < items.size(); ++i) {
      list.menu_items[i] = nativeapi::HandleTable::GetInstance().Insert(items[i]);
    }
    list.count = static_cast<long>(items.size());
    return list;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_get_all_items");
    native_menu_item_list_t empty = {};
    return empty;
  }
}

bool native_menu_open(native_menu_t menu, native_positioning_strategy_t strategy, native_placement_t placement) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Menu>(menu);
  if (!self) {
    return false;
  }
  try {
    auto strategy_cpp = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::PositioningStrategy>(strategy);
    if (!strategy_cpp) {
      return false;
    }
    return self->Open(*strategy_cpp, to_cpp_placement(placement));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_open");
    return false;
  }
}

bool native_menu_close(native_menu_t menu) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Menu>(menu);
  if (!self) {
    return false;
  }
  try {
    return self->Close();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_menu_close");
    return false;
  }
}

void* native_menu_get_native_object(native_menu_t menu) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Menu>(menu);
  if (!self) {
    return nullptr;
  }
  return self->GetNativeObject();
}

void native_menu_free(native_menu_t menu) {
  // The table invalidates the handle itself, so releasing an unknown or
  // already-released one is a no-op rather than a double free.
  nativeapi::HandleTable::GetInstance().Release(menu);
}

native_listener_id_t native_menu_add_listener(native_menu_t menu, native_menu_event_callback_t callback, void* user_data) {
  if (!callback) {
    return 0;
  }
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Menu>(menu);
  if (!self) {
    return 0;
  }
  try {
    return static_cast<native_listener_id_t>(self->AddListener<nativeapi::MenuEvent>(
        [callback, user_data](const nativeapi::MenuEvent& event) {
          native_menu_event_t c_event = {};
          if (!to_c_menu_event(event, &c_event)) {
            return;
          }
          callback(&c_event, user_data);
          free_c_menu_event(&c_event);
        }));
  } catch (...) {
    return 0;
  }
}

bool native_menu_remove_listener(native_menu_t menu, native_listener_id_t listener_id) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Menu>(menu);
  if (!self) {
    return false;
  }
  try {
    return self->RemoveListener(static_cast<size_t>(listener_id));
  } catch (...) {
    return false;
  }
}

bool to_c_menu_event(const nativeapi::MenuEvent& event, native_menu_event_t* out) {
  if (!out) {
    return false;
  }
  *out = native_menu_event_t{};
  if (const auto* typed = dynamic_cast<const nativeapi::MenuOpenedEvent*>(&event)) {
    out->type = NATIVE_MENU_EVENT_TYPE_OPENED;
    out->data.opened.menu_id = typed->GetMenuId();
    return true;
  }
  if (const auto* typed = dynamic_cast<const nativeapi::MenuClosedEvent*>(&event)) {
    out->type = NATIVE_MENU_EVENT_TYPE_CLOSED;
    out->data.closed.menu_id = typed->GetMenuId();
    return true;
  }
  if (const auto* typed = dynamic_cast<const nativeapi::MenuItemClickedEvent*>(&event)) {
    out->type = NATIVE_MENU_EVENT_TYPE_ITEM_CLICKED;
    out->data.item_clicked.item_id = typed->GetItemId();
    return true;
  }
  if (const auto* typed = dynamic_cast<const nativeapi::MenuItemSubmenuOpenedEvent*>(&event)) {
    out->type = NATIVE_MENU_EVENT_TYPE_ITEM_SUBMENU_OPENED;
    out->data.item_submenu_opened.item_id = typed->GetItemId();
    return true;
  }
  if (const auto* typed = dynamic_cast<const nativeapi::MenuItemSubmenuClosedEvent*>(&event)) {
    out->type = NATIVE_MENU_EVENT_TYPE_ITEM_SUBMENU_CLOSED;
    out->data.item_submenu_closed.item_id = typed->GetItemId();
    return true;
  }
  return false;
}

void free_c_menu_event(native_menu_event_t* value) {
  if (!value) {
    return;
  }
}

