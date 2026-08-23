// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#pragma once

#include <stdbool.h>
#include <stdint.h>

#include "common_c.h"

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
  NATIVE_URL_OPEN_ERROR_CODE_NONE = 0,
  NATIVE_URL_OPEN_ERROR_CODE_INVALID_URL_EMPTY = 1,
  NATIVE_URL_OPEN_ERROR_CODE_INVALID_URL_MISSING_SCHEME = 2,
  NATIVE_URL_OPEN_ERROR_CODE_INVALID_URL_UNSUPPORTED_SCHEME = 3,
  NATIVE_URL_OPEN_ERROR_CODE_UNSUPPORTED_PLATFORM = 4,
  NATIVE_URL_OPEN_ERROR_CODE_INVOCATION_FAILED = 5,
} native_url_open_error_code_t;

typedef struct {
  bool success;
  native_url_open_error_code_t error_code;
  char* error_message;
} native_url_open_result_t;

/// Frees everything the struct owns.
FFI_PLUGIN_EXPORT
void native_url_open_result_free(native_url_open_result_t* value);

FFI_PLUGIN_EXPORT
bool native_url_opener_is_supported(void);

FFI_PLUGIN_EXPORT
bool native_url_opener_can_open(const char* url);

FFI_PLUGIN_EXPORT
native_url_open_result_t native_url_opener_open(const char* url);

#ifdef __cplusplus
}
#endif

#ifdef __cplusplus
#include "../url_opener.h"
#include "string_utils_c.h"

// Conversion helpers between these C types and their C++ originals.

inline native_url_open_error_code_t to_c_url_open_error_code(nativeapi::UrlOpenErrorCode value);
inline nativeapi::UrlOpenErrorCode to_cpp_url_open_error_code(native_url_open_error_code_t value);
inline native_url_open_result_t to_c_url_open_result(const nativeapi::UrlOpenResult& value);
inline nativeapi::UrlOpenResult to_cpp_url_open_result(const native_url_open_result_t& value);

inline native_url_open_error_code_t to_c_url_open_error_code(nativeapi::UrlOpenErrorCode value) {
  switch (value) {
    case nativeapi::UrlOpenErrorCode::kNone:
      return NATIVE_URL_OPEN_ERROR_CODE_NONE;
    case nativeapi::UrlOpenErrorCode::kInvalidUrlEmpty:
      return NATIVE_URL_OPEN_ERROR_CODE_INVALID_URL_EMPTY;
    case nativeapi::UrlOpenErrorCode::kInvalidUrlMissingScheme:
      return NATIVE_URL_OPEN_ERROR_CODE_INVALID_URL_MISSING_SCHEME;
    case nativeapi::UrlOpenErrorCode::kInvalidUrlUnsupportedScheme:
      return NATIVE_URL_OPEN_ERROR_CODE_INVALID_URL_UNSUPPORTED_SCHEME;
    case nativeapi::UrlOpenErrorCode::kUnsupportedPlatform:
      return NATIVE_URL_OPEN_ERROR_CODE_UNSUPPORTED_PLATFORM;
    case nativeapi::UrlOpenErrorCode::kInvocationFailed:
      return NATIVE_URL_OPEN_ERROR_CODE_INVOCATION_FAILED;
    default:
      return NATIVE_URL_OPEN_ERROR_CODE_NONE;
  }
}

inline nativeapi::UrlOpenErrorCode to_cpp_url_open_error_code(native_url_open_error_code_t value) {
  switch (value) {
    case NATIVE_URL_OPEN_ERROR_CODE_NONE:
      return nativeapi::UrlOpenErrorCode::kNone;
    case NATIVE_URL_OPEN_ERROR_CODE_INVALID_URL_EMPTY:
      return nativeapi::UrlOpenErrorCode::kInvalidUrlEmpty;
    case NATIVE_URL_OPEN_ERROR_CODE_INVALID_URL_MISSING_SCHEME:
      return nativeapi::UrlOpenErrorCode::kInvalidUrlMissingScheme;
    case NATIVE_URL_OPEN_ERROR_CODE_INVALID_URL_UNSUPPORTED_SCHEME:
      return nativeapi::UrlOpenErrorCode::kInvalidUrlUnsupportedScheme;
    case NATIVE_URL_OPEN_ERROR_CODE_UNSUPPORTED_PLATFORM:
      return nativeapi::UrlOpenErrorCode::kUnsupportedPlatform;
    case NATIVE_URL_OPEN_ERROR_CODE_INVOCATION_FAILED:
      return nativeapi::UrlOpenErrorCode::kInvocationFailed;
    default:
      return nativeapi::UrlOpenErrorCode::kNone;
  }
}

inline native_url_open_result_t to_c_url_open_result(const nativeapi::UrlOpenResult& value) {
  native_url_open_result_t result = {};
  result.success = value.success;
  result.error_code = to_c_url_open_error_code(value.error_code);
  result.error_message = to_c_str(value.error_message);
  return result;
}

inline nativeapi::UrlOpenResult to_cpp_url_open_result(const native_url_open_result_t& value) {
  nativeapi::UrlOpenResult result = {};
  result.success = value.success;
  result.error_code = to_cpp_url_open_error_code(value.error_code);
  result.error_message = value.error_message ? value.error_message : "";
  return result;
}

#endif  // __cplusplus
