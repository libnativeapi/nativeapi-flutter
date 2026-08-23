// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#pragma once

#include <stdbool.h>
#include <stdint.h>

#include "common_c.h"
#include "geometry_c.h"
#include "window_c.h"

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
  NATIVE_POSITIONING_STRATEGY_TYPE_ABSOLUTE = 0,
  NATIVE_POSITIONING_STRATEGY_TYPE_CURSOR_POSITION = 1,
  NATIVE_POSITIONING_STRATEGY_TYPE_RELATIVE = 2,
} native_positioning_strategy_type_t;

/// Opaque PositioningStrategy handle.
///
/// A generational index into the library's handle table, NOT a pointer:
/// never dereference it, and compare it against NATIVE_INVALID_POSITIONING_STRATEGY rather than NULL.
/// Releasing a handle invalidates it; later calls fail safely instead of
/// touching freed memory.
typedef uint64_t native_positioning_strategy_t;

/// Never refers to a live PositioningStrategy.
#define NATIVE_INVALID_POSITIONING_STRATEGY ((native_positioning_strategy_t)0)

/// Caller owns the returned handle; release it with native_positioning_strategy_free().
FFI_PLUGIN_EXPORT
native_positioning_strategy_t native_positioning_strategy_absolute(native_point_t point);

/// Caller owns the returned handle; release it with native_positioning_strategy_free().
FFI_PLUGIN_EXPORT
native_positioning_strategy_t native_positioning_strategy_cursor_position(void);

/// Caller owns the returned handle; release it with native_positioning_strategy_free().
FFI_PLUGIN_EXPORT
native_positioning_strategy_t native_positioning_strategy_relative_with_rect_and_offset(native_rectangle_t rect, native_point_t offset);

/// Caller owns the returned handle; release it with native_positioning_strategy_free().
FFI_PLUGIN_EXPORT
native_positioning_strategy_t native_positioning_strategy_relative_with_window_and_offset(native_window_t window, native_point_t offset);

FFI_PLUGIN_EXPORT
native_positioning_strategy_type_t native_positioning_strategy_get_type(native_positioning_strategy_t positioning_strategy);

FFI_PLUGIN_EXPORT
native_point_t native_positioning_strategy_get_absolute_position(native_positioning_strategy_t positioning_strategy);

FFI_PLUGIN_EXPORT
native_rectangle_t native_positioning_strategy_get_relative_rectangle(native_positioning_strategy_t positioning_strategy);

FFI_PLUGIN_EXPORT
native_point_t native_positioning_strategy_get_relative_offset(native_positioning_strategy_t positioning_strategy);

/// Releases the caller's reference. Safe to call with an invalid or
/// already-released handle.
FFI_PLUGIN_EXPORT
void native_positioning_strategy_free(native_positioning_strategy_t positioning_strategy);

#ifdef __cplusplus
}
#endif

#ifdef __cplusplus
#include "../positioning_strategy.h"
#include "string_utils_c.h"

// Conversion helpers between these C types and their C++ originals.

inline native_positioning_strategy_type_t to_c_positioning_strategy_type(nativeapi::PositioningStrategy::Type value);
inline nativeapi::PositioningStrategy::Type to_cpp_positioning_strategy_type(native_positioning_strategy_type_t value);

inline native_positioning_strategy_type_t to_c_positioning_strategy_type(nativeapi::PositioningStrategy::Type value) {
  switch (value) {
    case nativeapi::PositioningStrategy::Type::Absolute:
      return NATIVE_POSITIONING_STRATEGY_TYPE_ABSOLUTE;
    case nativeapi::PositioningStrategy::Type::CursorPosition:
      return NATIVE_POSITIONING_STRATEGY_TYPE_CURSOR_POSITION;
    case nativeapi::PositioningStrategy::Type::Relative:
      return NATIVE_POSITIONING_STRATEGY_TYPE_RELATIVE;
    default:
      return NATIVE_POSITIONING_STRATEGY_TYPE_ABSOLUTE;
  }
}

inline nativeapi::PositioningStrategy::Type to_cpp_positioning_strategy_type(native_positioning_strategy_type_t value) {
  switch (value) {
    case NATIVE_POSITIONING_STRATEGY_TYPE_ABSOLUTE:
      return nativeapi::PositioningStrategy::Type::Absolute;
    case NATIVE_POSITIONING_STRATEGY_TYPE_CURSOR_POSITION:
      return nativeapi::PositioningStrategy::Type::CursorPosition;
    case NATIVE_POSITIONING_STRATEGY_TYPE_RELATIVE:
      return nativeapi::PositioningStrategy::Type::Relative;
    default:
      return nativeapi::PositioningStrategy::Type::Absolute;
  }
}

#endif  // __cplusplus
