// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_launch_at_login_create(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_launch_at_login_create(); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_launch_at_login_create_with_id(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  const char* p0 = {};
  if (!GetString(env, args[0], arena, &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_launch_at_login_create_with_id(p0); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_launch_at_login_create_with_id_and_display_name(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  const char* p0 = {};
  if (!GetString(env, args[0], arena, &p0)) {
    return nullptr;
  }
  const char* p1 = {};
  if (!GetString(env, args[1], arena, &p1)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_launch_at_login_create_with_id_and_display_name(p0, p1); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_launch_at_login_free(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_launch_at_login_free(self); });
  return Undefined(env);
}

napi_value Js_native_launch_at_login_is_supported(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_launch_at_login_is_supported(); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_launch_at_login_get_id(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_launch_at_login_get_id(self); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_launch_at_login_get_display_name(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_launch_at_login_get_display_name(self); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_launch_at_login_set_display_name(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_launch_at_login_set_display_name(self, p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_launch_at_login_set_program(napi_env env, napi_callback_info info) {
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
  native_string_list_t p1 = {};
  if (!GetStringList(env, args[2], arena, &p1)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_launch_at_login_set_program(self, p0, p1); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_launch_at_login_get_executable_path(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_launch_at_login_get_executable_path(self); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_launch_at_login_get_arguments(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_launch_at_login_get_arguments(self); });
  Value value = CopyStringList(result);
  native_string_list_free(&result);
  return value.ToJs(env);
}

napi_value Js_native_launch_at_login_enable(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_launch_at_login_enable(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_launch_at_login_disable(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_launch_at_login_disable(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_launch_at_login_is_enabled(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_launch_at_login_is_enabled(self); });
  return Value::Bool(result).ToJs(env);
}

}  // namespace

void RegisterLaunchAtLogin(napi_env env, napi_value exports) {
  Export(env, exports, "native_launch_at_login_create", Js_native_launch_at_login_create);
  Export(env, exports, "native_launch_at_login_create_with_id", Js_native_launch_at_login_create_with_id);
  Export(env, exports, "native_launch_at_login_create_with_id_and_display_name", Js_native_launch_at_login_create_with_id_and_display_name);
  Export(env, exports, "native_launch_at_login_free", Js_native_launch_at_login_free);
  Export(env, exports, "native_launch_at_login_is_supported", Js_native_launch_at_login_is_supported);
  Export(env, exports, "native_launch_at_login_get_id", Js_native_launch_at_login_get_id);
  Export(env, exports, "native_launch_at_login_get_display_name", Js_native_launch_at_login_get_display_name);
  Export(env, exports, "native_launch_at_login_set_display_name", Js_native_launch_at_login_set_display_name);
  Export(env, exports, "native_launch_at_login_set_program", Js_native_launch_at_login_set_program);
  Export(env, exports, "native_launch_at_login_get_executable_path", Js_native_launch_at_login_get_executable_path);
  Export(env, exports, "native_launch_at_login_get_arguments", Js_native_launch_at_login_get_arguments);
  Export(env, exports, "native_launch_at_login_enable", Js_native_launch_at_login_enable);
  Export(env, exports, "native_launch_at_login_disable", Js_native_launch_at_login_disable);
  Export(env, exports, "native_launch_at_login_is_enabled", Js_native_launch_at_login_is_enabled);
}

}  // namespace nativeapi_js
