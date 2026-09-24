// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_image_free(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_image_free(self); });
  return Undefined(env);
}

napi_value Js_native_image_get_native_object(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_image_get_native_object(self); });
  return Value::BigInt(reinterpret_cast<uintptr_t>(result)).ToJs(env);
}

napi_value Js_native_image_from_file(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_image_from_file(p0); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_image_from_base64(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_image_from_base64(p0); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_image_get_size(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_image_get_size(self); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_image_get_format(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_image_get_format(self); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_image_to_base64(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_image_to_base64(self); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_image_save_to_file(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_image_save_to_file(self, p0); });
  return Value::Bool(result).ToJs(env);
}

}  // namespace

void RegisterImage(napi_env env, napi_value exports) {
  Export(env, exports, "native_image_free", Js_native_image_free);
  Export(env, exports, "native_image_get_native_object", Js_native_image_get_native_object);
  Export(env, exports, "native_image_from_file", Js_native_image_from_file);
  Export(env, exports, "native_image_from_base64", Js_native_image_from_base64);
  Export(env, exports, "native_image_get_size", Js_native_image_get_size);
  Export(env, exports, "native_image_get_format", Js_native_image_get_format);
  Export(env, exports, "native_image_to_base64", Js_native_image_to_base64);
  Export(env, exports, "native_image_save_to_file", Js_native_image_save_to_file);
}

}  // namespace nativeapi_js
