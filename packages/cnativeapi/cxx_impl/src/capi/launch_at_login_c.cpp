// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "launch_at_login_c.h"

#include <cstdio>
#include <memory>
#include <new>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "string_utils_c.h"
#include "../foundation/handle_table.h"
#include "../launch_at_login.h"

native_launch_at_login_t native_launch_at_login_create(void) {
  try {
    return nativeapi::HandleTable::GetInstance().Insert(
        std::make_shared<nativeapi::LaunchAtLogin>());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_launch_at_login_create");
    return 0;
  }
}

native_launch_at_login_t native_launch_at_login_create_with_id(const char* id) {
  try {
    return nativeapi::HandleTable::GetInstance().Insert(
        std::make_shared<nativeapi::LaunchAtLogin>(std::string(id ? id : "")));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_launch_at_login_create_with_id");
    return 0;
  }
}

native_launch_at_login_t native_launch_at_login_create_with_id_and_display_name(const char* id, const char* display_name) {
  try {
    return nativeapi::HandleTable::GetInstance().Insert(
        std::make_shared<nativeapi::LaunchAtLogin>(std::string(id ? id : ""), std::string(display_name ? display_name : "")));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_launch_at_login_create_with_id_and_display_name");
    return 0;
  }
}

bool native_launch_at_login_is_supported(void) {
  try {
    return nativeapi::LaunchAtLogin::IsSupported();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_launch_at_login_is_supported");
    return false;
  }
}

char* native_launch_at_login_get_id(native_launch_at_login_t launch_at_login) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::LaunchAtLogin>(launch_at_login);
  if (!self) {
    return nullptr;
  }
  try {
    return to_c_str(self->GetId());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_launch_at_login_get_id");
    return nullptr;
  }
}

char* native_launch_at_login_get_display_name(native_launch_at_login_t launch_at_login) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::LaunchAtLogin>(launch_at_login);
  if (!self) {
    return nullptr;
  }
  try {
    return to_c_str(self->GetDisplayName());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_launch_at_login_get_display_name");
    return nullptr;
  }
}

bool native_launch_at_login_set_display_name(native_launch_at_login_t launch_at_login, const char* display_name) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::LaunchAtLogin>(launch_at_login);
  if (!self) {
    return false;
  }
  try {
    return self->SetDisplayName(std::string(display_name ? display_name : ""));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_launch_at_login_set_display_name");
    return false;
  }
}

bool native_launch_at_login_set_program(native_launch_at_login_t launch_at_login, const char* executable_path, native_string_list_t arguments) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::LaunchAtLogin>(launch_at_login);
  if (!self) {
    return false;
  }
  try {
    std::vector<std::string> arguments_cpp;
    for (long i = 0; i < arguments.count; ++i) {
      arguments_cpp.emplace_back(arguments.items[i] ? arguments.items[i] : "");
    }
    return self->SetProgram(std::string(executable_path ? executable_path : ""), arguments_cpp);
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_launch_at_login_set_program");
    return false;
  }
}

char* native_launch_at_login_get_executable_path(native_launch_at_login_t launch_at_login) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::LaunchAtLogin>(launch_at_login);
  if (!self) {
    return nullptr;
  }
  try {
    return to_c_str(self->GetExecutablePath());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_launch_at_login_get_executable_path");
    return nullptr;
  }
}

native_string_list_t native_launch_at_login_get_arguments(native_launch_at_login_t launch_at_login) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::LaunchAtLogin>(launch_at_login);
  if (!self) {
    native_string_list_t empty = {};
    return empty;
  }
  try {
    return to_c_string_list(self->GetArguments());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_launch_at_login_get_arguments");
    native_string_list_t empty = {};
    return empty;
  }
}

bool native_launch_at_login_enable(native_launch_at_login_t launch_at_login) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::LaunchAtLogin>(launch_at_login);
  if (!self) {
    return false;
  }
  try {
    return self->Enable();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_launch_at_login_enable");
    return false;
  }
}

bool native_launch_at_login_disable(native_launch_at_login_t launch_at_login) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::LaunchAtLogin>(launch_at_login);
  if (!self) {
    return false;
  }
  try {
    return self->Disable();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_launch_at_login_disable");
    return false;
  }
}

bool native_launch_at_login_is_enabled(native_launch_at_login_t launch_at_login) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::LaunchAtLogin>(launch_at_login);
  if (!self) {
    return false;
  }
  try {
    return self->IsEnabled();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_launch_at_login_is_enabled");
    return false;
  }
}

void native_launch_at_login_free(native_launch_at_login_t launch_at_login) {
  // The table invalidates the handle itself, so releasing an unknown or
  // already-released one is a no-op rather than a double free.
  nativeapi::HandleTable::GetInstance().Release(launch_at_login);
}

