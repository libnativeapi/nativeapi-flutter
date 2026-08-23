// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "shortcut_c.h"

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

void native_shortcut_options_free(native_shortcut_options_t* value) {
  if (!value) {
    return;
  }
  free_c_str(value->accelerator);
  value->accelerator = nullptr;
  free_c_str(value->description);
  value->description = nullptr;
}

native_shortcut_t native_shortcut_create_with_id_and_options(native_shortcut_id_t id, native_shortcut_options_t options) {
  try {
    auto options_cpp = to_cpp_shortcut_options(options);
    return nativeapi::HandleTable::GetInstance().Insert(
        std::make_shared<nativeapi::Shortcut>(id, options_cpp));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_shortcut_create_with_id_and_options");
    return 0;
  }
}

native_shortcut_t native_shortcut_create_with_id_and_accelerator_and_callback(native_shortcut_id_t id, const char* accelerator, native_shortcut_create_with_id_and_accelerator_and_callback_t callback, void* callback_user_data) {
  try {
    std::function<void()> callback_cpp;
    if (callback) {
      callback_cpp = [callback, callback_user_data]() { callback(callback_user_data); };
    }
    return nativeapi::HandleTable::GetInstance().Insert(
        std::make_shared<nativeapi::Shortcut>(id, std::string(accelerator ? accelerator : ""), callback_cpp));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_shortcut_create_with_id_and_accelerator_and_callback");
    return 0;
  }
}

native_shortcut_id_t native_shortcut_get_id(native_shortcut_t shortcut) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Shortcut>(shortcut);
  if (!self) {
    return 0;
  }
  try {
    return self->GetId();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_shortcut_get_id");
    return 0;
  }
}

char* native_shortcut_get_accelerator(native_shortcut_t shortcut) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Shortcut>(shortcut);
  if (!self) {
    return nullptr;
  }
  try {
    return to_c_str(self->GetAccelerator());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_shortcut_get_accelerator");
    return nullptr;
  }
}

char* native_shortcut_get_description(native_shortcut_t shortcut) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Shortcut>(shortcut);
  if (!self) {
    return nullptr;
  }
  try {
    return to_c_str(self->GetDescription());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_shortcut_get_description");
    return nullptr;
  }
}

void native_shortcut_set_description(native_shortcut_t shortcut, const char* description) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Shortcut>(shortcut);
  if (!self) {
    return;
  }
  try {
    self->SetDescription(std::string(description ? description : ""));
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_shortcut_set_description");
    return;
  }
}

native_shortcut_scope_t native_shortcut_get_scope(native_shortcut_t shortcut) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Shortcut>(shortcut);
  if (!self) {
    return (native_shortcut_scope_t)NATIVE_SHORTCUT_SCOPE_GLOBAL;
  }
  try {
    return to_c_shortcut_scope(self->GetScope());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_shortcut_get_scope");
    return (native_shortcut_scope_t)NATIVE_SHORTCUT_SCOPE_GLOBAL;
  }
}

void native_shortcut_set_enabled(native_shortcut_t shortcut, bool enabled) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Shortcut>(shortcut);
  if (!self) {
    return;
  }
  try {
    self->SetEnabled(enabled);
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_shortcut_set_enabled");
    return;
  }
}

bool native_shortcut_is_enabled(native_shortcut_t shortcut) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Shortcut>(shortcut);
  if (!self) {
    return false;
  }
  try {
    return self->IsEnabled();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_shortcut_is_enabled");
    return false;
  }
}

void native_shortcut_invoke(native_shortcut_t shortcut) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Shortcut>(shortcut);
  if (!self) {
    return;
  }
  try {
    self->Invoke();
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_shortcut_invoke");
    return;
  }
}

void native_shortcut_set_callback(native_shortcut_t shortcut, native_shortcut_set_callback_t callback, void* callback_user_data) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Shortcut>(shortcut);
  if (!self) {
    return;
  }
  try {
    std::function<void()> callback_cpp;
    if (callback) {
      callback_cpp = [callback, callback_user_data]() { callback(callback_user_data); };
    }
    self->SetCallback(callback_cpp);
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_shortcut_set_callback");
    return;
  }
}

void native_shortcut_free(native_shortcut_t shortcut) {
  // The table invalidates the handle itself, so releasing an unknown or
  // already-released one is a no-op rather than a double free.
  nativeapi::HandleTable::GetInstance().Release(shortcut);
}

void native_shortcut_list_free(native_shortcut_list_t* list) {
  if (!list || !list->shortcuts) {
    return;
  }
  for (long i = 0; i < list->count; ++i) {
    nativeapi::HandleTable::GetInstance().Release(list->shortcuts[i]);
  }
  delete[] list->shortcuts;
  list->shortcuts = nullptr;
  list->count = 0;
}

void native_shortcut_list_release(native_shortcut_list_t* list) {
  if (!list) {
    return;
  }
  delete[] list->shortcuts;
  list->shortcuts = nullptr;
  list->count = 0;
}

bool to_c_shortcut_event(const nativeapi::ShortcutEvent& event, native_shortcut_event_t* out) {
  if (!out) {
    return false;
  }
  *out = native_shortcut_event_t{};
  out->shortcut_id = event.GetShortcutId();
  out->accelerator = to_c_str(event.GetAccelerator());
  if (const auto* typed = dynamic_cast<const nativeapi::ShortcutActivatedEvent*>(&event)) {
    out->type = NATIVE_SHORTCUT_EVENT_TYPE_ACTIVATED;
    (void)typed;
    return true;
  }
  if (const auto* typed = dynamic_cast<const nativeapi::ShortcutRegisteredEvent*>(&event)) {
    out->type = NATIVE_SHORTCUT_EVENT_TYPE_REGISTERED;
    (void)typed;
    return true;
  }
  if (const auto* typed = dynamic_cast<const nativeapi::ShortcutUnregisteredEvent*>(&event)) {
    out->type = NATIVE_SHORTCUT_EVENT_TYPE_UNREGISTERED;
    (void)typed;
    return true;
  }
  if (const auto* typed = dynamic_cast<const nativeapi::ShortcutRegistrationFailedEvent*>(&event)) {
    out->type = NATIVE_SHORTCUT_EVENT_TYPE_REGISTRATION_FAILED;
    out->data.registration_failed.error_message = to_c_str(typed->GetErrorMessage());
    return true;
  }
  return false;
}

void free_c_shortcut_event(native_shortcut_event_t* value) {
  if (!value) {
    return;
  }
  free_c_str(value->accelerator);
  value->accelerator = nullptr;
  if (value->type == NATIVE_SHORTCUT_EVENT_TYPE_REGISTRATION_FAILED) {
    free_c_str(value->data.registration_failed.error_message);
    value->data.registration_failed.error_message = nullptr;
  }
}

