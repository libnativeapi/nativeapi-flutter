// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "message_dialog_c.h"

#include <cstdio>
#include <memory>
#include <new>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "string_utils_c.h"
#include "../foundation/handle_table.h"
#include "../dialog.h"
#include "dialog_c.h"
#include "../message_dialog.h"

native_message_dialog_t native_message_dialog_create(const char* title, const char* message) {
  try {
    return nativeapi::HandleTable::GetInstance().Insert(
        std::make_shared<nativeapi::MessageDialog>(std::string(title ? title : ""), std::string(message ? message : "")));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_message_dialog_create");
    return 0;
  }
}

void native_message_dialog_set_title(native_message_dialog_t message_dialog, const char* title) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MessageDialog>(message_dialog);
  if (!self) {
    return;
  }
  try {
    self->SetTitle(std::string(title ? title : ""));
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_message_dialog_set_title");
    return;
  }
}

char* native_message_dialog_get_title(native_message_dialog_t message_dialog) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MessageDialog>(message_dialog);
  if (!self) {
    return nullptr;
  }
  try {
    return to_c_str(self->GetTitle());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_message_dialog_get_title");
    return nullptr;
  }
}

void native_message_dialog_set_message(native_message_dialog_t message_dialog, const char* message) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MessageDialog>(message_dialog);
  if (!self) {
    return;
  }
  try {
    self->SetMessage(std::string(message ? message : ""));
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_message_dialog_set_message");
    return;
  }
}

char* native_message_dialog_get_message(native_message_dialog_t message_dialog) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MessageDialog>(message_dialog);
  if (!self) {
    return nullptr;
  }
  try {
    return to_c_str(self->GetMessage());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_message_dialog_get_message");
    return nullptr;
  }
}

native_dialog_modality_t native_message_dialog_get_modality(native_message_dialog_t message_dialog) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MessageDialog>(message_dialog);
  if (!self) {
    return (native_dialog_modality_t)0;
  }
  try {
    return to_c_dialog_modality(self->GetModality());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_message_dialog_get_modality");
    return (native_dialog_modality_t)0;
  }
}

void native_message_dialog_set_modality(native_message_dialog_t message_dialog, native_dialog_modality_t modality) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MessageDialog>(message_dialog);
  if (!self) {
    return;
  }
  try {
    self->SetModality(to_cpp_dialog_modality(modality));
    return;
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_message_dialog_set_modality");
    return;
  }
}

bool native_message_dialog_open(native_message_dialog_t message_dialog) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MessageDialog>(message_dialog);
  if (!self) {
    return false;
  }
  try {
    return self->Open();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_message_dialog_open");
    return false;
  }
}

bool native_message_dialog_close(native_message_dialog_t message_dialog) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::MessageDialog>(message_dialog);
  if (!self) {
    return false;
  }
  try {
    return self->Close();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_message_dialog_close");
    return false;
  }
}

void native_message_dialog_free(native_message_dialog_t message_dialog) {
  // The table invalidates the handle itself, so releasing an unknown or
  // already-released one is a no-op rather than a double free.
  nativeapi::HandleTable::GetInstance().Release(message_dialog);
}

