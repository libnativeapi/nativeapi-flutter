// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_secure_storage_create(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_secure_storage_create(); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_secure_storage_create_with_scope(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_secure_storage_create_with_scope(p0); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_secure_storage_free(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_secure_storage_free(self); });
  return Undefined(env);
}

napi_value Js_native_secure_storage_set(napi_env env, napi_callback_info info) {
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
  const char* p1 = {};
  if (!GetString(env, args[2], arena, &p1)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_secure_storage_set(self, p0, p1); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_secure_storage_get(napi_env env, napi_callback_info info) {
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
  const char* p1 = {};
  if (!GetString(env, args[2], arena, &p1)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_secure_storage_get(self, p0, p1); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_secure_storage_remove(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_secure_storage_remove(self, p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_secure_storage_clear(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_secure_storage_clear(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_secure_storage_contains(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_secure_storage_contains(self, p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_secure_storage_get_keys(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_secure_storage_get_keys(self); });
  Value value = CopyStringList(result);
  native_string_list_free(&result);
  return value.ToJs(env);
}

napi_value Js_native_secure_storage_get_size(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_secure_storage_get_size(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_secure_storage_get_all(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_secure_storage_get_all(self); });
  Value value = CopyStringMap(result);
  native_string_map_free(&result);
  return value.ToJs(env);
}

napi_value Js_native_secure_storage_get_scope(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_secure_storage_get_scope(self); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_secure_storage_is_available(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_secure_storage_is_available(); });
  return Value::Bool(result).ToJs(env);
}

}  // namespace

void RegisterSecureStorage(napi_env env, napi_value exports) {
  Export(env, exports, "native_secure_storage_create", Js_native_secure_storage_create);
  Export(env, exports, "native_secure_storage_create_with_scope", Js_native_secure_storage_create_with_scope);
  Export(env, exports, "native_secure_storage_free", Js_native_secure_storage_free);
  Export(env, exports, "native_secure_storage_set", Js_native_secure_storage_set);
  Export(env, exports, "native_secure_storage_get", Js_native_secure_storage_get);
  Export(env, exports, "native_secure_storage_remove", Js_native_secure_storage_remove);
  Export(env, exports, "native_secure_storage_clear", Js_native_secure_storage_clear);
  Export(env, exports, "native_secure_storage_contains", Js_native_secure_storage_contains);
  Export(env, exports, "native_secure_storage_get_keys", Js_native_secure_storage_get_keys);
  Export(env, exports, "native_secure_storage_get_size", Js_native_secure_storage_get_size);
  Export(env, exports, "native_secure_storage_get_all", Js_native_secure_storage_get_all);
  Export(env, exports, "native_secure_storage_get_scope", Js_native_secure_storage_get_scope);
  Export(env, exports, "native_secure_storage_is_available", Js_native_secure_storage_is_available);
}

}  // namespace nativeapi_js
