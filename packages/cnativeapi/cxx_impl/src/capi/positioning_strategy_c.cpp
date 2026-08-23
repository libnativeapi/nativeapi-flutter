// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "positioning_strategy_c.h"

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
#include "../window.h"
#include "window_c.h"
#include "../positioning_strategy.h"

native_positioning_strategy_t native_positioning_strategy_absolute(native_point_t point) {
  try {
    auto point_cpp = to_cpp_point(point);
    return nativeapi::HandleTable::GetInstance().Insert(
        std::make_shared<nativeapi::PositioningStrategy>(nativeapi::PositioningStrategy::Absolute(point_cpp)));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_positioning_strategy_absolute");
    return 0;
  }
}

native_positioning_strategy_t native_positioning_strategy_cursor_position(void) {
  try {
    return nativeapi::HandleTable::GetInstance().Insert(
        std::make_shared<nativeapi::PositioningStrategy>(nativeapi::PositioningStrategy::CursorPosition()));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_positioning_strategy_cursor_position");
    return 0;
  }
}

native_positioning_strategy_t native_positioning_strategy_relative_with_rect_and_offset(native_rectangle_t rect, native_point_t offset) {
  try {
    auto rect_cpp = to_cpp_rectangle(rect);
    auto offset_cpp = to_cpp_point(offset);
    return nativeapi::HandleTable::GetInstance().Insert(
        std::make_shared<nativeapi::PositioningStrategy>(nativeapi::PositioningStrategy::Relative(rect_cpp, offset_cpp)));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_positioning_strategy_relative_with_rect_and_offset");
    return 0;
  }
}

native_positioning_strategy_t native_positioning_strategy_relative_with_window_and_offset(native_window_t window, native_point_t offset) {
  try {
    auto window_cpp = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::Window>(window);
    if (!window_cpp) {
      return 0;
    }
    auto offset_cpp = to_cpp_point(offset);
    return nativeapi::HandleTable::GetInstance().Insert(
        std::make_shared<nativeapi::PositioningStrategy>(nativeapi::PositioningStrategy::Relative(*window_cpp, offset_cpp)));
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_positioning_strategy_relative_with_window_and_offset");
    return 0;
  }
}

native_positioning_strategy_type_t native_positioning_strategy_get_type(native_positioning_strategy_t positioning_strategy) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::PositioningStrategy>(positioning_strategy);
  if (!self) {
    return (native_positioning_strategy_type_t)NATIVE_POSITIONING_STRATEGY_TYPE_ABSOLUTE;
  }
  try {
    return to_c_positioning_strategy_type(self->GetType());
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_positioning_strategy_get_type");
    return (native_positioning_strategy_type_t)NATIVE_POSITIONING_STRATEGY_TYPE_ABSOLUTE;
  }
}

native_point_t native_positioning_strategy_get_absolute_position(native_positioning_strategy_t positioning_strategy) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::PositioningStrategy>(positioning_strategy);
  if (!self) {
    native_point_t result = {};
    return result;
  }
  try {
    const auto cpp_result = self->GetAbsolutePosition();
    return to_c_point(cpp_result);
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_positioning_strategy_get_absolute_position");
    native_point_t result = {};
    return result;
  }
}

native_rectangle_t native_positioning_strategy_get_relative_rectangle(native_positioning_strategy_t positioning_strategy) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::PositioningStrategy>(positioning_strategy);
  if (!self) {
    native_rectangle_t result = {};
    return result;
  }
  try {
    const auto cpp_result = self->GetRelativeRectangle();
    return to_c_rectangle(cpp_result);
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_positioning_strategy_get_relative_rectangle");
    native_rectangle_t result = {};
    return result;
  }
}

native_point_t native_positioning_strategy_get_relative_offset(native_positioning_strategy_t positioning_strategy) {
  auto self = nativeapi::HandleTable::GetInstance().Resolve<nativeapi::PositioningStrategy>(positioning_strategy);
  if (!self) {
    native_point_t result = {};
    return result;
  }
  try {
    const auto cpp_result = self->GetRelativeOffset();
    return to_c_point(cpp_result);
  } catch (...) {
    fprintf(stderr, "[nativeapi] %s: unexpected exception\n", "native_positioning_strategy_get_relative_offset");
    native_point_t result = {};
    return result;
  }
}

void native_positioning_strategy_free(native_positioning_strategy_t positioning_strategy) {
  // The table invalidates the handle itself, so releasing an unknown or
  // already-released one is a no-op rather than a double free.
  nativeapi::HandleTable::GetInstance().Release(positioning_strategy);
}

