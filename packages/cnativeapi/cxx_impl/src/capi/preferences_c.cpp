// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "preferences_c.h"

#include <cstdio>
#include <memory>
#include <new>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "string_utils_c.h"
#include "../foundation/handle_table.h"
#include "../preferences.h"

native_preferences_t native_preferences_create(void) {
  try {
    return nativeapi::HandleTable::GetInstance().Insert(
        std::make_shared<nativeapi::Preferences>());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_preferences_create");
    return 0;
  }
}

native_preferences_t native_preferences_create_with_scope(const char* scope) {
  try {
    return nativeapi::HandleTable::GetInstance().Insert(
        std::make_shared<nativeapi::Preferences>(std::string(scope ? scope : "")));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_preferences_create_with_scope");
    return 0;
  }
}

bool native_preferences_set(native_preferences_t preferences, const char* key, const char* value) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Preferences>(preferences);
  if (!self) {
    return false;
  }
  try {
    return self->Set(std::string(key ? key : ""), std::string(value ? value : ""));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_preferences_set");
    return false;
  }
}

char* native_preferences_get(native_preferences_t preferences, const char* key, const char* default_value) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Preferences>(preferences);
  if (!self) {
    return nullptr;
  }
  try {
    return to_c_str(self->Get(std::string(key ? key : ""), std::string(default_value ? default_value : "")));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_preferences_get");
    return nullptr;
  }
}

bool native_preferences_remove(native_preferences_t preferences, const char* key) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Preferences>(preferences);
  if (!self) {
    return false;
  }
  try {
    return self->Remove(std::string(key ? key : ""));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_preferences_remove");
    return false;
  }
}

bool native_preferences_clear(native_preferences_t preferences) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Preferences>(preferences);
  if (!self) {
    return false;
  }
  try {
    return self->Clear();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_preferences_clear");
    return false;
  }
}

bool native_preferences_contains(native_preferences_t preferences, const char* key) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Preferences>(preferences);
  if (!self) {
    return false;
  }
  try {
    return self->Contains(std::string(key ? key : ""));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_preferences_contains");
    return false;
  }
}

native_string_list_t native_preferences_get_keys(native_preferences_t preferences) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Preferences>(preferences);
  if (!self) {
    native_string_list_t empty = {};
    return empty;
  }
  try {
    return to_c_string_list(self->GetKeys());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_preferences_get_keys");
    native_string_list_t empty = {};
    return empty;
  }
}

unsigned long native_preferences_get_size(native_preferences_t preferences) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Preferences>(preferences);
  if (!self) {
    return 0;
  }
  try {
    return self->GetSize();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_preferences_get_size");
    return 0;
  }
}

native_string_map_t native_preferences_get_all(native_preferences_t preferences) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Preferences>(preferences);
  if (!self) {
    native_string_map_t empty = {};
    return empty;
  }
  try {
    return to_c_string_map(self->GetAll());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_preferences_get_all");
    native_string_map_t empty = {};
    return empty;
  }
}

char* native_preferences_get_scope(native_preferences_t preferences) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Preferences>(preferences);
  if (!self) {
    return nullptr;
  }
  try {
    return to_c_str(self->GetScope());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_preferences_get_scope");
    return nullptr;
  }
}

void native_preferences_free(native_preferences_t preferences) {
  // The table invalidates the handle itself, so releasing an unknown or
  // already-released one is a no-op rather than a double free.
  nativeapi::HandleTable::GetInstance().Release(preferences);
}

