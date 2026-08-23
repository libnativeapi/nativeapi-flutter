// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "secure_storage_c.h"

#include <cstdio>
#include <memory>
#include <new>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "string_utils_c.h"
#include "../foundation/handle_table.h"
#include "../secure_storage.h"

native_secure_storage_t native_secure_storage_create(void) {
  try {
    return nativeapi::HandleTable::GetInstance().Insert(
        std::make_shared<nativeapi::SecureStorage>());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_secure_storage_create");
    return 0;
  }
}

native_secure_storage_t native_secure_storage_create_with_scope(const char* scope) {
  try {
    return nativeapi::HandleTable::GetInstance().Insert(
        std::make_shared<nativeapi::SecureStorage>(std::string(scope ? scope : "")));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_secure_storage_create_with_scope");
    return 0;
  }
}

bool native_secure_storage_set(native_secure_storage_t secure_storage, const char* key, const char* value) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::SecureStorage>(secure_storage);
  if (!self) {
    return false;
  }
  try {
    return self->Set(std::string(key ? key : ""), std::string(value ? value : ""));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_secure_storage_set");
    return false;
  }
}

char* native_secure_storage_get(native_secure_storage_t secure_storage, const char* key, const char* default_value) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::SecureStorage>(secure_storage);
  if (!self) {
    return nullptr;
  }
  try {
    return to_c_str(self->Get(std::string(key ? key : ""), std::string(default_value ? default_value : "")));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_secure_storage_get");
    return nullptr;
  }
}

bool native_secure_storage_remove(native_secure_storage_t secure_storage, const char* key) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::SecureStorage>(secure_storage);
  if (!self) {
    return false;
  }
  try {
    return self->Remove(std::string(key ? key : ""));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_secure_storage_remove");
    return false;
  }
}

bool native_secure_storage_clear(native_secure_storage_t secure_storage) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::SecureStorage>(secure_storage);
  if (!self) {
    return false;
  }
  try {
    return self->Clear();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_secure_storage_clear");
    return false;
  }
}

bool native_secure_storage_contains(native_secure_storage_t secure_storage, const char* key) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::SecureStorage>(secure_storage);
  if (!self) {
    return false;
  }
  try {
    return self->Contains(std::string(key ? key : ""));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_secure_storage_contains");
    return false;
  }
}

native_string_list_t native_secure_storage_get_keys(native_secure_storage_t secure_storage) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::SecureStorage>(secure_storage);
  if (!self) {
    native_string_list_t empty = {};
    return empty;
  }
  try {
    return to_c_string_list(self->GetKeys());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_secure_storage_get_keys");
    native_string_list_t empty = {};
    return empty;
  }
}

unsigned long native_secure_storage_get_size(native_secure_storage_t secure_storage) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::SecureStorage>(secure_storage);
  if (!self) {
    return 0;
  }
  try {
    return self->GetSize();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_secure_storage_get_size");
    return 0;
  }
}

native_string_map_t native_secure_storage_get_all(native_secure_storage_t secure_storage) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::SecureStorage>(secure_storage);
  if (!self) {
    native_string_map_t empty = {};
    return empty;
  }
  try {
    return to_c_string_map(self->GetAll());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_secure_storage_get_all");
    native_string_map_t empty = {};
    return empty;
  }
}

char* native_secure_storage_get_scope(native_secure_storage_t secure_storage) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::SecureStorage>(secure_storage);
  if (!self) {
    return nullptr;
  }
  try {
    return to_c_str(self->GetScope());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_secure_storage_get_scope");
    return nullptr;
  }
}

bool native_secure_storage_is_available(void) {
  try {
    return nativeapi::SecureStorage::IsAvailable();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_secure_storage_is_available");
    return false;
  }
}

void native_secure_storage_free(native_secure_storage_t secure_storage) {
  // The table invalidates the handle itself, so releasing an unknown or
  // already-released one is a no-op rather than a double free.
  nativeapi::HandleTable::GetInstance().Release(secure_storage);
}

