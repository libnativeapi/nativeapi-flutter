// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_window_create(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_window_create(); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_window_create_with_native_window(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_create_with_native_window(p0); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_window_free(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_window_free(self); });
  return Undefined(env);
}

napi_value Js_native_window_get_native_object(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_get_native_object(self); });
  return Value::BigInt(reinterpret_cast<uintptr_t>(result)).ToJs(env);
}

napi_value Js_native_window_get_id(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_get_id(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_window_get_content_view(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_get_content_view(self); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_window_focus(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_window_focus(self); });
  return Undefined(env);
}

napi_value Js_native_window_blur(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_window_blur(self); });
  return Undefined(env);
}

napi_value Js_native_window_is_focused(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_is_focused(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_show(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_window_show(self); });
  return Undefined(env);
}

napi_value Js_native_window_show_inactive(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_window_show_inactive(self); });
  return Undefined(env);
}

napi_value Js_native_window_hide(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_window_hide(self); });
  return Undefined(env);
}

napi_value Js_native_window_is_visible(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_is_visible(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_maximize(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_window_maximize(self); });
  return Undefined(env);
}

napi_value Js_native_window_unmaximize(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_window_unmaximize(self); });
  return Undefined(env);
}

napi_value Js_native_window_is_maximized(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_is_maximized(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_minimize(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_window_minimize(self); });
  return Undefined(env);
}

napi_value Js_native_window_restore(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_window_restore(self); });
  return Undefined(env);
}

napi_value Js_native_window_is_minimized(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_is_minimized(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_set_full_screen(napi_env env, napi_callback_info info) {
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
  bool p0 = {};
  if (!GetBool(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_set_full_screen(self, p0); });
  return Undefined(env);
}

napi_value Js_native_window_is_full_screen(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_is_full_screen(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_set_bounds(napi_env env, napi_callback_info info) {
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
  native_rectangle_t p0 = {};
  if (!FromJs(env, args[1], &p0, arena)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_set_bounds(self, p0); });
  return Undefined(env);
}

napi_value Js_native_window_get_bounds(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_get_bounds(self); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_window_set_content_bounds(napi_env env, napi_callback_info info) {
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
  native_rectangle_t p0 = {};
  if (!FromJs(env, args[1], &p0, arena)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_set_content_bounds(self, p0); });
  return Undefined(env);
}

napi_value Js_native_window_get_content_bounds(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_get_content_bounds(self); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_window_set_size(napi_env env, napi_callback_info info) {
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
  native_size_t p0 = {};
  if (!FromJs(env, args[1], &p0, arena)) {
    return nullptr;
  }
  bool p1 = {};
  if (!GetBool(env, args[2], &p1)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_set_size(self, p0, p1); });
  return Undefined(env);
}

napi_value Js_native_window_get_size(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_get_size(self); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_window_set_content_size(napi_env env, napi_callback_info info) {
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
  native_size_t p0 = {};
  if (!FromJs(env, args[1], &p0, arena)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_set_content_size(self, p0); });
  return Undefined(env);
}

napi_value Js_native_window_get_content_size(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_get_content_size(self); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_window_set_minimum_size(napi_env env, napi_callback_info info) {
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
  native_size_t p0 = {};
  if (!FromJs(env, args[1], &p0, arena)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_set_minimum_size(self, p0); });
  return Undefined(env);
}

napi_value Js_native_window_get_minimum_size(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_get_minimum_size(self); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_window_set_maximum_size(napi_env env, napi_callback_info info) {
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
  native_size_t p0 = {};
  if (!FromJs(env, args[1], &p0, arena)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_set_maximum_size(self, p0); });
  return Undefined(env);
}

napi_value Js_native_window_get_maximum_size(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_get_maximum_size(self); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_window_set_aspect_ratio(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_window_set_aspect_ratio(self, p0); });
  return Undefined(env);
}

napi_value Js_native_window_get_aspect_ratio(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_get_aspect_ratio(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_window_set_resizable(napi_env env, napi_callback_info info) {
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
  bool p0 = {};
  if (!GetBool(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_set_resizable(self, p0); });
  return Undefined(env);
}

napi_value Js_native_window_is_resizable(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_is_resizable(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_set_movable(napi_env env, napi_callback_info info) {
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
  bool p0 = {};
  if (!GetBool(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_set_movable(self, p0); });
  return Undefined(env);
}

napi_value Js_native_window_is_movable(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_is_movable(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_set_minimizable(napi_env env, napi_callback_info info) {
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
  bool p0 = {};
  if (!GetBool(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_set_minimizable(self, p0); });
  return Undefined(env);
}

napi_value Js_native_window_is_minimizable(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_is_minimizable(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_set_maximizable(napi_env env, napi_callback_info info) {
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
  bool p0 = {};
  if (!GetBool(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_set_maximizable(self, p0); });
  return Undefined(env);
}

napi_value Js_native_window_is_maximizable(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_is_maximizable(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_set_full_screenable(napi_env env, napi_callback_info info) {
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
  bool p0 = {};
  if (!GetBool(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_set_full_screenable(self, p0); });
  return Undefined(env);
}

napi_value Js_native_window_is_full_screenable(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_is_full_screenable(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_set_closable(napi_env env, napi_callback_info info) {
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
  bool p0 = {};
  if (!GetBool(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_set_closable(self, p0); });
  return Undefined(env);
}

napi_value Js_native_window_is_closable(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_is_closable(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_set_window_control_buttons_visible(napi_env env, napi_callback_info info) {
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
  bool p0 = {};
  if (!GetBool(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_set_window_control_buttons_visible(self, p0); });
  return Undefined(env);
}

napi_value Js_native_window_is_window_control_buttons_visible(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_is_window_control_buttons_visible(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_set_always_on_top(napi_env env, napi_callback_info info) {
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
  bool p0 = {};
  if (!GetBool(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_set_always_on_top(self, p0); });
  return Undefined(env);
}

napi_value Js_native_window_is_always_on_top(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_is_always_on_top(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_set_always_on_bottom(napi_env env, napi_callback_info info) {
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
  bool p0 = {};
  if (!GetBool(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_set_always_on_bottom(self, p0); });
  return Undefined(env);
}

napi_value Js_native_window_is_always_on_bottom(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_is_always_on_bottom(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_set_parent_window(napi_env env, napi_callback_info info) {
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
  native_window_t p0 = {};
  if (!GetHandle(env, args[1], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_window_set_parent_window(self, p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_get_parent_window(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_get_parent_window(self); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_window_set_non_activating(napi_env env, napi_callback_info info) {
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
  bool p0 = {};
  if (!GetBool(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_set_non_activating(self, p0); });
  return Undefined(env);
}

napi_value Js_native_window_is_non_activating(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_is_non_activating(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_set_position(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_window_set_position(self, p0); });
  return Undefined(env);
}

napi_value Js_native_window_get_position(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_get_position(self); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_window_center(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_window_center(self); });
  return Undefined(env);
}

napi_value Js_native_window_set_title(napi_env env, napi_callback_info info) {
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
  const char* p0 = {};
  if (!GetString(env, args[1], arena, &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_set_title(self, p0); });
  return Undefined(env);
}

napi_value Js_native_window_get_title(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_get_title(self); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_window_set_title_bar_colors(napi_env env, napi_callback_info info) {
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
  native_color_t p1 = {};
  if (!FromJs(env, args[2], &p1, arena)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_window_set_title_bar_colors(self, p0, p1); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_reset_title_bar_colors(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_reset_title_bar_colors(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_set_title_bar_style(napi_env env, napi_callback_info info) {
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
  native_title_bar_style_t p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_set_title_bar_style(self, p0); });
  return Undefined(env);
}

napi_value Js_native_window_get_title_bar_style(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_get_title_bar_style(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_window_set_content_under_title_bar(napi_env env, napi_callback_info info) {
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
  bool p0 = {};
  if (!GetBool(env, args[1], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_window_set_content_under_title_bar(self, p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_is_content_under_title_bar(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_is_content_under_title_bar(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_is_content_under_title_bar_supported(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_window_is_content_under_title_bar_supported(); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_set_has_shadow(napi_env env, napi_callback_info info) {
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
  bool p0 = {};
  if (!GetBool(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_set_has_shadow(self, p0); });
  return Undefined(env);
}

napi_value Js_native_window_has_shadow(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_has_shadow(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_set_custom_shadow(napi_env env, napi_callback_info info) {
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
  native_window_shadow_t p0 = {};
  if (!GetHandle(env, args[1], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_window_set_custom_shadow(self, p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_get_custom_shadow(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_get_custom_shadow(self); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_window_set_opacity(napi_env env, napi_callback_info info) {
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
  float p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_set_opacity(self, p0); });
  return Undefined(env);
}

napi_value Js_native_window_get_opacity(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_get_opacity(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_window_set_visual_effect(napi_env env, napi_callback_info info) {
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
  native_visual_effect_t p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_window_set_visual_effect(self, p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_get_visual_effect(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_get_visual_effect(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_window_is_visual_effect_supported(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  native_visual_effect_t p0 = {};
  if (!GetNumber(env, args[0], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_window_is_visual_effect_supported(p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_set_shape(napi_env env, napi_callback_info info) {
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
  native_window_shape_t p0 = {};
  if (!GetHandle(env, args[1], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_window_set_shape(self, p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_is_shaped(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_is_shaped(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_is_shape_supported(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_window_is_shape_supported(); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_set_input_shape(napi_env env, napi_callback_info info) {
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
  native_window_shape_t p0 = {};
  if (!GetHandle(env, args[1], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_window_set_input_shape(self, p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_is_input_shaped(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_is_input_shaped(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_is_input_shape_supported(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_window_is_input_shape_supported(); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_set_background_color(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_window_set_background_color(self, p0); });
  return Undefined(env);
}

napi_value Js_native_window_get_background_color(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_get_background_color(self); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_window_set_visible_on_all_workspaces(napi_env env, napi_callback_info info) {
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
  bool p0 = {};
  if (!GetBool(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_set_visible_on_all_workspaces(self, p0); });
  return Undefined(env);
}

napi_value Js_native_window_is_visible_on_all_workspaces(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_is_visible_on_all_workspaces(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_set_visible_in_taskbar(napi_env env, napi_callback_info info) {
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
  bool p0 = {};
  if (!GetBool(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_set_visible_in_taskbar(self, p0); });
  return Undefined(env);
}

napi_value Js_native_window_is_visible_in_taskbar(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_is_visible_in_taskbar(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_set_ignore_mouse_events(napi_env env, napi_callback_info info) {
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
  bool p0 = {};
  if (!GetBool(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_set_ignore_mouse_events(self, p0); });
  return Undefined(env);
}

napi_value Js_native_window_is_ignore_mouse_events(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_is_ignore_mouse_events(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_set_focusable(napi_env env, napi_callback_info info) {
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
  bool p0 = {};
  if (!GetBool(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_set_focusable(self, p0); });
  return Undefined(env);
}

napi_value Js_native_window_is_focusable(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_is_focusable(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_start_dragging(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_window_start_dragging(self); });
  return Undefined(env);
}

napi_value Js_native_window_start_resizing(napi_env env, napi_callback_info info) {
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
  native_resize_edge_t p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_start_resizing(self, p0); });
  return Undefined(env);
}

}  // namespace

void RegisterWindow(napi_env env, napi_value exports) {
  Export(env, exports, "native_window_create", Js_native_window_create);
  Export(env, exports, "native_window_create_with_native_window", Js_native_window_create_with_native_window);
  Export(env, exports, "native_window_free", Js_native_window_free);
  Export(env, exports, "native_window_get_native_object", Js_native_window_get_native_object);
  Export(env, exports, "native_window_get_id", Js_native_window_get_id);
  Export(env, exports, "native_window_get_content_view", Js_native_window_get_content_view);
  Export(env, exports, "native_window_focus", Js_native_window_focus);
  Export(env, exports, "native_window_blur", Js_native_window_blur);
  Export(env, exports, "native_window_is_focused", Js_native_window_is_focused);
  Export(env, exports, "native_window_show", Js_native_window_show);
  Export(env, exports, "native_window_show_inactive", Js_native_window_show_inactive);
  Export(env, exports, "native_window_hide", Js_native_window_hide);
  Export(env, exports, "native_window_is_visible", Js_native_window_is_visible);
  Export(env, exports, "native_window_maximize", Js_native_window_maximize);
  Export(env, exports, "native_window_unmaximize", Js_native_window_unmaximize);
  Export(env, exports, "native_window_is_maximized", Js_native_window_is_maximized);
  Export(env, exports, "native_window_minimize", Js_native_window_minimize);
  Export(env, exports, "native_window_restore", Js_native_window_restore);
  Export(env, exports, "native_window_is_minimized", Js_native_window_is_minimized);
  Export(env, exports, "native_window_set_full_screen", Js_native_window_set_full_screen);
  Export(env, exports, "native_window_is_full_screen", Js_native_window_is_full_screen);
  Export(env, exports, "native_window_set_bounds", Js_native_window_set_bounds);
  Export(env, exports, "native_window_get_bounds", Js_native_window_get_bounds);
  Export(env, exports, "native_window_set_content_bounds", Js_native_window_set_content_bounds);
  Export(env, exports, "native_window_get_content_bounds", Js_native_window_get_content_bounds);
  Export(env, exports, "native_window_set_size", Js_native_window_set_size);
  Export(env, exports, "native_window_get_size", Js_native_window_get_size);
  Export(env, exports, "native_window_set_content_size", Js_native_window_set_content_size);
  Export(env, exports, "native_window_get_content_size", Js_native_window_get_content_size);
  Export(env, exports, "native_window_set_minimum_size", Js_native_window_set_minimum_size);
  Export(env, exports, "native_window_get_minimum_size", Js_native_window_get_minimum_size);
  Export(env, exports, "native_window_set_maximum_size", Js_native_window_set_maximum_size);
  Export(env, exports, "native_window_get_maximum_size", Js_native_window_get_maximum_size);
  Export(env, exports, "native_window_set_aspect_ratio", Js_native_window_set_aspect_ratio);
  Export(env, exports, "native_window_get_aspect_ratio", Js_native_window_get_aspect_ratio);
  Export(env, exports, "native_window_set_resizable", Js_native_window_set_resizable);
  Export(env, exports, "native_window_is_resizable", Js_native_window_is_resizable);
  Export(env, exports, "native_window_set_movable", Js_native_window_set_movable);
  Export(env, exports, "native_window_is_movable", Js_native_window_is_movable);
  Export(env, exports, "native_window_set_minimizable", Js_native_window_set_minimizable);
  Export(env, exports, "native_window_is_minimizable", Js_native_window_is_minimizable);
  Export(env, exports, "native_window_set_maximizable", Js_native_window_set_maximizable);
  Export(env, exports, "native_window_is_maximizable", Js_native_window_is_maximizable);
  Export(env, exports, "native_window_set_full_screenable", Js_native_window_set_full_screenable);
  Export(env, exports, "native_window_is_full_screenable", Js_native_window_is_full_screenable);
  Export(env, exports, "native_window_set_closable", Js_native_window_set_closable);
  Export(env, exports, "native_window_is_closable", Js_native_window_is_closable);
  Export(env, exports, "native_window_set_window_control_buttons_visible", Js_native_window_set_window_control_buttons_visible);
  Export(env, exports, "native_window_is_window_control_buttons_visible", Js_native_window_is_window_control_buttons_visible);
  Export(env, exports, "native_window_set_always_on_top", Js_native_window_set_always_on_top);
  Export(env, exports, "native_window_is_always_on_top", Js_native_window_is_always_on_top);
  Export(env, exports, "native_window_set_always_on_bottom", Js_native_window_set_always_on_bottom);
  Export(env, exports, "native_window_is_always_on_bottom", Js_native_window_is_always_on_bottom);
  Export(env, exports, "native_window_set_parent_window", Js_native_window_set_parent_window);
  Export(env, exports, "native_window_get_parent_window", Js_native_window_get_parent_window);
  Export(env, exports, "native_window_set_non_activating", Js_native_window_set_non_activating);
  Export(env, exports, "native_window_is_non_activating", Js_native_window_is_non_activating);
  Export(env, exports, "native_window_set_position", Js_native_window_set_position);
  Export(env, exports, "native_window_get_position", Js_native_window_get_position);
  Export(env, exports, "native_window_center", Js_native_window_center);
  Export(env, exports, "native_window_set_title", Js_native_window_set_title);
  Export(env, exports, "native_window_get_title", Js_native_window_get_title);
  Export(env, exports, "native_window_set_title_bar_colors", Js_native_window_set_title_bar_colors);
  Export(env, exports, "native_window_reset_title_bar_colors", Js_native_window_reset_title_bar_colors);
  Export(env, exports, "native_window_set_title_bar_style", Js_native_window_set_title_bar_style);
  Export(env, exports, "native_window_get_title_bar_style", Js_native_window_get_title_bar_style);
  Export(env, exports, "native_window_set_content_under_title_bar", Js_native_window_set_content_under_title_bar);
  Export(env, exports, "native_window_is_content_under_title_bar", Js_native_window_is_content_under_title_bar);
  Export(env, exports, "native_window_is_content_under_title_bar_supported", Js_native_window_is_content_under_title_bar_supported);
  Export(env, exports, "native_window_set_has_shadow", Js_native_window_set_has_shadow);
  Export(env, exports, "native_window_has_shadow", Js_native_window_has_shadow);
  Export(env, exports, "native_window_set_custom_shadow", Js_native_window_set_custom_shadow);
  Export(env, exports, "native_window_get_custom_shadow", Js_native_window_get_custom_shadow);
  Export(env, exports, "native_window_set_opacity", Js_native_window_set_opacity);
  Export(env, exports, "native_window_get_opacity", Js_native_window_get_opacity);
  Export(env, exports, "native_window_set_visual_effect", Js_native_window_set_visual_effect);
  Export(env, exports, "native_window_get_visual_effect", Js_native_window_get_visual_effect);
  Export(env, exports, "native_window_is_visual_effect_supported", Js_native_window_is_visual_effect_supported);
  Export(env, exports, "native_window_set_shape", Js_native_window_set_shape);
  Export(env, exports, "native_window_is_shaped", Js_native_window_is_shaped);
  Export(env, exports, "native_window_is_shape_supported", Js_native_window_is_shape_supported);
  Export(env, exports, "native_window_set_input_shape", Js_native_window_set_input_shape);
  Export(env, exports, "native_window_is_input_shaped", Js_native_window_is_input_shaped);
  Export(env, exports, "native_window_is_input_shape_supported", Js_native_window_is_input_shape_supported);
  Export(env, exports, "native_window_set_background_color", Js_native_window_set_background_color);
  Export(env, exports, "native_window_get_background_color", Js_native_window_get_background_color);
  Export(env, exports, "native_window_set_visible_on_all_workspaces", Js_native_window_set_visible_on_all_workspaces);
  Export(env, exports, "native_window_is_visible_on_all_workspaces", Js_native_window_is_visible_on_all_workspaces);
  Export(env, exports, "native_window_set_visible_in_taskbar", Js_native_window_set_visible_in_taskbar);
  Export(env, exports, "native_window_is_visible_in_taskbar", Js_native_window_is_visible_in_taskbar);
  Export(env, exports, "native_window_set_ignore_mouse_events", Js_native_window_set_ignore_mouse_events);
  Export(env, exports, "native_window_is_ignore_mouse_events", Js_native_window_is_ignore_mouse_events);
  Export(env, exports, "native_window_set_focusable", Js_native_window_set_focusable);
  Export(env, exports, "native_window_is_focusable", Js_native_window_is_focusable);
  Export(env, exports, "native_window_start_dragging", Js_native_window_start_dragging);
  Export(env, exports, "native_window_start_resizing", Js_native_window_start_resizing);
}

}  // namespace nativeapi_js
