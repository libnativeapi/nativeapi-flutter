// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_shortcut_create_with_id_and_options(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  native_shortcut_id_t p0 = {};
  if (!GetNumber(env, args[0], &p0)) {
    return nullptr;
  }
  native_shortcut_options_t p1 = {};
  if (!FromJs(env, args[1], &p1, arena)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_shortcut_create_with_id_and_options(p0, p1); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_shortcut_create_with_id_and_accelerator_and_callback(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  native_shortcut_id_t p0 = {};
  if (!GetNumber(env, args[0], &p0)) {
    return nullptr;
  }
  const char* p1 = {};
  if (!GetString(env, args[1], arena, &p1)) {
    return nullptr;
  }
  Callback* p2 = nullptr;
  if (!GetCallback(env, args[2], /*optional=*/false, &p2)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_shortcut_create_with_id_and_accelerator_and_callback(p0, p1, +[](void* user_data) { Callback::Dispatch(user_data, {}); }, p2, &Callback::ReleaseUserData); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_shortcut_free(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_shortcut_free(self); });
  return Undefined(env);
}

napi_value Js_native_shortcut_get_id(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_shortcut_get_id(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_shortcut_get_accelerator(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_shortcut_get_accelerator(self); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_shortcut_get_description(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_shortcut_get_description(self); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_shortcut_set_description(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_shortcut_set_description(self, p0); });
  return Undefined(env);
}

napi_value Js_native_shortcut_get_scope(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_shortcut_get_scope(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_shortcut_set_enabled(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_shortcut_set_enabled(self, p0); });
  return Undefined(env);
}

napi_value Js_native_shortcut_is_enabled(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_shortcut_is_enabled(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_shortcut_invoke(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_shortcut_invoke(self); });
  return Undefined(env);
}

napi_value Js_native_shortcut_set_callback(napi_env env, napi_callback_info info) {
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
  Callback* p0 = nullptr;
  if (!GetCallback(env, args[1], /*optional=*/false, &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_shortcut_set_callback(self, +[](void* user_data) { Callback::Dispatch(user_data, {}); }, p0, &Callback::ReleaseUserData); });
  return Undefined(env);
}

}  // namespace

void RegisterShortcut(napi_env env, napi_value exports) {
  Export(env, exports, "native_shortcut_create_with_id_and_options", Js_native_shortcut_create_with_id_and_options);
  Export(env, exports, "native_shortcut_create_with_id_and_accelerator_and_callback", Js_native_shortcut_create_with_id_and_accelerator_and_callback);
  Export(env, exports, "native_shortcut_free", Js_native_shortcut_free);
  Export(env, exports, "native_shortcut_get_id", Js_native_shortcut_get_id);
  Export(env, exports, "native_shortcut_get_accelerator", Js_native_shortcut_get_accelerator);
  Export(env, exports, "native_shortcut_get_description", Js_native_shortcut_get_description);
  Export(env, exports, "native_shortcut_set_description", Js_native_shortcut_set_description);
  Export(env, exports, "native_shortcut_get_scope", Js_native_shortcut_get_scope);
  Export(env, exports, "native_shortcut_set_enabled", Js_native_shortcut_set_enabled);
  Export(env, exports, "native_shortcut_is_enabled", Js_native_shortcut_is_enabled);
  Export(env, exports, "native_shortcut_invoke", Js_native_shortcut_invoke);
  Export(env, exports, "native_shortcut_set_callback", Js_native_shortcut_set_callback);
}

}  // namespace nativeapi_js
