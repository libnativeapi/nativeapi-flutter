// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "image_c.h"

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

native_image_t native_image_from_file(const char* file_path) {
  try {
    return nativeapi::HandleTable::GetInstance().Insert(nativeapi::Image::FromFile(std::string(file_path ? file_path : "")));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_image_from_file");
    return 0;
  }
}

native_image_t native_image_from_base64(const char* base64_data) {
  try {
    return nativeapi::HandleTable::GetInstance().Insert(nativeapi::Image::FromBase64(std::string(base64_data ? base64_data : "")));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_image_from_base64");
    return 0;
  }
}

native_size_t native_image_get_size(native_image_t image) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Image>(image);
  if (!self) {
    native_size_t result = {};
    return result;
  }
  try {
    const auto cpp_result = self->GetSize();
    return to_c_size(cpp_result);
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_image_get_size");
    native_size_t result = {};
    return result;
  }
}

char* native_image_get_format(native_image_t image) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Image>(image);
  if (!self) {
    return nullptr;
  }
  try {
    return to_c_str(self->GetFormat());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_image_get_format");
    return nullptr;
  }
}

char* native_image_to_base64(native_image_t image) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Image>(image);
  if (!self) {
    return nullptr;
  }
  try {
    return to_c_str(self->ToBase64());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_image_to_base64");
    return nullptr;
  }
}

bool native_image_save_to_file(native_image_t image, const char* file_path) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Image>(image);
  if (!self) {
    return false;
  }
  try {
    return self->SaveToFile(std::string(file_path ? file_path : ""));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_image_save_to_file");
    return false;
  }
}

void* native_image_get_native_object(native_image_t image) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Image>(image);
  if (!self) {
    return nullptr;
  }
  return self->GetNativeObject();
}

void native_image_free(native_image_t image) {
  // The table invalidates the handle itself, so releasing an unknown or
  // already-released one is a no-op rather than a double free.
  nativeapi::HandleTable::GetInstance().Release(image);
}

