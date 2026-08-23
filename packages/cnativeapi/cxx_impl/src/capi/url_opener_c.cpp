// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "url_opener_c.h"

#include <cstdio>
#include <memory>
#include <new>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "string_utils_c.h"
#include "../foundation/handle_table.h"
#include "../url_opener.h"

void native_url_open_result_free(native_url_open_result_t* value) {
  if (!value) {
    return;
  }
  free_c_str(value->error_message);
  value->error_message = nullptr;
}

bool native_url_opener_is_supported(void) {
  try {
    return nativeapi::UrlOpener::GetInstance().IsSupported();
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_url_opener_is_supported");
    return false;
  }
}

bool native_url_opener_can_open(const char* url) {
  try {
    return nativeapi::UrlOpener::GetInstance().CanOpen(std::string(url ? url : ""));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_url_opener_can_open");
    return false;
  }
}

native_url_open_result_t native_url_opener_open(const char* url) {
  try {
    const auto cpp_result = nativeapi::UrlOpener::GetInstance().Open(std::string(url ? url : ""));
    return to_c_url_open_result(cpp_result);
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_url_opener_open");
    native_url_open_result_t result = {};
    result.success = false;
    return result;
  }
}

