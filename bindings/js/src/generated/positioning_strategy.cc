// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_positioning_strategy_free(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  uint64_t self = 0;
  if (!GetHandle(env, args[0], &self)) {
    return nullptr;
  }
  OnMainThread([&] { return native_positioning_strategy_free(self); });
  return Undefined(env);
}

napi_value Js_native_positioning_strategy_absolute(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  native_point_t p0 = {};
  if (!FromJs(env, args[0], &p0, arena)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_positioning_strategy_absolute(p0); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_positioning_strategy_cursor_position(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_positioning_strategy_cursor_position(); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_positioning_strategy_relative_with_rect_and_offset(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  native_rectangle_t p0 = {};
  if (!FromJs(env, args[0], &p0, arena)) {
    return nullptr;
  }
  native_point_t p1 = {};
  if (!FromJs(env, args[1], &p1, arena)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_positioning_strategy_relative_with_rect_and_offset(p0, p1); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_positioning_strategy_relative_with_window_and_offset(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  native_window_t p0 = {};
  if (!GetHandle(env, args[0], &p0)) {
    return nullptr;
  }
  native_point_t p1 = {};
  if (!FromJs(env, args[1], &p1, arena)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_positioning_strategy_relative_with_window_and_offset(p0, p1); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_positioning_strategy_get_type(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  uint64_t self = 0;
  if (!GetHandle(env, args[0], &self)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_positioning_strategy_get_type(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_positioning_strategy_get_absolute_position(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  uint64_t self = 0;
  if (!GetHandle(env, args[0], &self)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_positioning_strategy_get_absolute_position(self); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_positioning_strategy_get_relative_rectangle(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  uint64_t self = 0;
  if (!GetHandle(env, args[0], &self)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_positioning_strategy_get_relative_rectangle(self); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_positioning_strategy_get_relative_offset(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  uint64_t self = 0;
  if (!GetHandle(env, args[0], &self)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_positioning_strategy_get_relative_offset(self); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

}  // namespace

void RegisterPositioningStrategy(napi_env env, napi_value exports) {
  Export(env, exports, "native_positioning_strategy_free", Js_native_positioning_strategy_free);
  Export(env, exports, "native_positioning_strategy_absolute", Js_native_positioning_strategy_absolute);
  Export(env, exports, "native_positioning_strategy_cursor_position", Js_native_positioning_strategy_cursor_position);
  Export(env, exports, "native_positioning_strategy_relative_with_rect_and_offset", Js_native_positioning_strategy_relative_with_rect_and_offset);
  Export(env, exports, "native_positioning_strategy_relative_with_window_and_offset", Js_native_positioning_strategy_relative_with_window_and_offset);
  Export(env, exports, "native_positioning_strategy_get_type", Js_native_positioning_strategy_get_type);
  Export(env, exports, "native_positioning_strategy_get_absolute_position", Js_native_positioning_strategy_get_absolute_position);
  Export(env, exports, "native_positioning_strategy_get_relative_rectangle", Js_native_positioning_strategy_get_relative_rectangle);
  Export(env, exports, "native_positioning_strategy_get_relative_offset", Js_native_positioning_strategy_get_relative_offset);
}

}  // namespace nativeapi_js
