// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_window_shadow_create(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_window_shadow_create(); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_window_shadow_free(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_window_shadow_free(self); });
  return Undefined(env);
}

napi_value Js_native_window_shadow_set_color(napi_env env, napi_callback_info info) {
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
  native_color_t p0 = {};
  if (!FromJs(env, args[1], &p0, arena)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_shadow_set_color(self, p0); });
  return Undefined(env);
}

napi_value Js_native_window_shadow_get_color(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_shadow_get_color(self); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_window_shadow_set_blur_radius(napi_env env, napi_callback_info info) {
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
  double p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_window_shadow_set_blur_radius(self, p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_shadow_get_blur_radius(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_shadow_get_blur_radius(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_window_shadow_set_offset(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_shadow_set_offset(self, p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_shadow_get_offset(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_shadow_get_offset(self); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

}  // namespace

void RegisterWindowShadow(napi_env env, napi_value exports) {
  Export(env, exports, "native_window_shadow_create", Js_native_window_shadow_create);
  Export(env, exports, "native_window_shadow_free", Js_native_window_shadow_free);
  Export(env, exports, "native_window_shadow_set_color", Js_native_window_shadow_set_color);
  Export(env, exports, "native_window_shadow_get_color", Js_native_window_shadow_get_color);
  Export(env, exports, "native_window_shadow_set_blur_radius", Js_native_window_shadow_set_blur_radius);
  Export(env, exports, "native_window_shadow_get_blur_radius", Js_native_window_shadow_get_blur_radius);
  Export(env, exports, "native_window_shadow_set_offset", Js_native_window_shadow_set_offset);
  Export(env, exports, "native_window_shadow_get_offset", Js_native_window_shadow_get_offset);
}

}  // namespace nativeapi_js
