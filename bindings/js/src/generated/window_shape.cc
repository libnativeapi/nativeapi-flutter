// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_window_shape_create(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = native_window_shape_create();
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_window_shape_free(napi_env env, napi_callback_info info) {
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
  native_window_shape_free(self);
  return Undefined(env);
}

napi_value Js_native_window_shape_add_point(napi_env env, napi_callback_info info) {
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
  native_point_t p0 = {};
  if (!FromJs(env, args[1], &p0, arena)) {
    return nullptr;
  }
  auto result = native_window_shape_add_point(self, p0);
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_shape_clear(napi_env env, napi_callback_info info) {
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
  native_window_shape_clear(self);
  return Undefined(env);
}

napi_value Js_native_window_shape_get_point_count(napi_env env, napi_callback_info info) {
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
  auto result = native_window_shape_get_point_count(self);
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_window_shape_get_point_at(napi_env env, napi_callback_info info) {
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
  unsigned long p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  auto result = native_window_shape_get_point_at(self, p0);
  Value value = ToValue(result);
  return value.ToJs(env);
}

}  // namespace

void RegisterWindowShape(napi_env env, napi_value exports) {
  Export(env, exports, "native_window_shape_create", Js_native_window_shape_create);
  Export(env, exports, "native_window_shape_free", Js_native_window_shape_free);
  Export(env, exports, "native_window_shape_add_point", Js_native_window_shape_add_point);
  Export(env, exports, "native_window_shape_clear", Js_native_window_shape_clear);
  Export(env, exports, "native_window_shape_get_point_count", Js_native_window_shape_get_point_count);
  Export(env, exports, "native_window_shape_get_point_at", Js_native_window_shape_get_point_at);
}

}  // namespace nativeapi_js
