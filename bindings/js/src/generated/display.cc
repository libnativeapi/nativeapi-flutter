// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_display_create(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  void* p0 = {};
  if (!GetPointer(env, args[0], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_display_create(p0); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_display_free(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_display_free(self); });
  return Undefined(env);
}

napi_value Js_native_display_get_native_object(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_display_get_native_object(self); });
  return Value::BigInt(reinterpret_cast<uintptr_t>(result)).ToJs(env);
}

napi_value Js_native_display_get_id(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_display_get_id(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_display_get_name(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_display_get_name(self); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_display_get_position(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_display_get_position(self); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_display_get_size(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_display_get_size(self); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_display_get_work_area(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_display_get_work_area(self); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_display_get_scale_factor(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_display_get_scale_factor(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_display_is_primary(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_display_is_primary(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_display_get_orientation(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_display_get_orientation(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_display_get_refresh_rate(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_display_get_refresh_rate(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_display_get_bit_depth(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_display_get_bit_depth(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

}  // namespace

void RegisterDisplay(napi_env env, napi_value exports) {
  Export(env, exports, "native_display_create", Js_native_display_create);
  Export(env, exports, "native_display_free", Js_native_display_free);
  Export(env, exports, "native_display_get_native_object", Js_native_display_get_native_object);
  Export(env, exports, "native_display_get_id", Js_native_display_get_id);
  Export(env, exports, "native_display_get_name", Js_native_display_get_name);
  Export(env, exports, "native_display_get_position", Js_native_display_get_position);
  Export(env, exports, "native_display_get_size", Js_native_display_get_size);
  Export(env, exports, "native_display_get_work_area", Js_native_display_get_work_area);
  Export(env, exports, "native_display_get_scale_factor", Js_native_display_get_scale_factor);
  Export(env, exports, "native_display_is_primary", Js_native_display_is_primary);
  Export(env, exports, "native_display_get_orientation", Js_native_display_get_orientation);
  Export(env, exports, "native_display_get_refresh_rate", Js_native_display_get_refresh_rate);
  Export(env, exports, "native_display_get_bit_depth", Js_native_display_get_bit_depth);
}

}  // namespace nativeapi_js
