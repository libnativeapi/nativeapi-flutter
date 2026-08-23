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

typedef struct {
  double x;
  double y;
} native_point_t;

typedef struct {
  double width;
  double height;
} native_size_t;

typedef struct {
  double x;
  double y;
  double width;
  double height;
} native_rectangle_t;

#ifdef __cplusplus
}
#endif

#ifdef __cplusplus
#include "../foundation/geometry.h"
#include "string_utils_c.h"

// Conversion helpers between these C types and their C++ originals.

inline native_point_t to_c_point(const nativeapi::Point& value);
inline nativeapi::Point to_cpp_point(const native_point_t& value);
inline native_size_t to_c_size(const nativeapi::Size& value);
inline nativeapi::Size to_cpp_size(const native_size_t& value);
inline native_rectangle_t to_c_rectangle(const nativeapi::Rectangle& value);
inline nativeapi::Rectangle to_cpp_rectangle(const native_rectangle_t& value);

inline native_point_t to_c_point(const nativeapi::Point& value) {
  native_point_t result = {};
  result.x = value.x;
  result.y = value.y;
  return result;
}

inline nativeapi::Point to_cpp_point(const native_point_t& value) {
  nativeapi::Point result = {};
  result.x = value.x;
  result.y = value.y;
  return result;
}

inline native_size_t to_c_size(const nativeapi::Size& value) {
  native_size_t result = {};
  result.width = value.width;
  result.height = value.height;
  return result;
}

inline nativeapi::Size to_cpp_size(const native_size_t& value) {
  nativeapi::Size result = {};
  result.width = value.width;
  result.height = value.height;
  return result;
}

inline native_rectangle_t to_c_rectangle(const nativeapi::Rectangle& value) {
  native_rectangle_t result = {};
  result.x = value.x;
  result.y = value.y;
  result.width = value.width;
  result.height = value.height;
  return result;
}

inline nativeapi::Rectangle to_cpp_rectangle(const native_rectangle_t& value) {
  nativeapi::Rectangle result = {};
  result.x = value.x;
  result.y = value.y;
  result.width = value.width;
  result.height = value.height;
  return result;
}

#endif  // __cplusplus
