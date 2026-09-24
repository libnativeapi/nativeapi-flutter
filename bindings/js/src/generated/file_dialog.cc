// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_file_dialog_create(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  native_file_dialog_mode_t p0 = {};
  if (!GetNumber(env, args[0], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_file_dialog_create(p0); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_file_dialog_free(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_file_dialog_free(self); });
  return Undefined(env);
}

napi_value Js_native_file_dialog_is_supported(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_file_dialog_is_supported(); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_file_dialog_set_parent_window(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_file_dialog_set_parent_window(self, p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_file_dialog_set_file_types(napi_env env, napi_callback_info info) {
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
  native_string_list_t p0 = {};
  if (!GetStringList(env, args[1], arena, &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_file_dialog_set_file_types(self, p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_file_dialog_set_suggested_file_name(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_file_dialog_set_suggested_file_name(self, p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_file_dialog_get_modality(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_file_dialog_get_modality(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_file_dialog_set_modality(napi_env env, napi_callback_info info) {
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
  native_dialog_modality_t p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_file_dialog_set_modality(self, p0); });
  return Undefined(env);
}

napi_value Js_native_file_dialog_open(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_file_dialog_open(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_file_dialog_close(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_file_dialog_close(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_file_dialog_get_result(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_file_dialog_get_result(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_file_dialog_get_paths(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_file_dialog_get_paths(self); });
  Value value = CopyStringList(result);
  native_string_list_free(&result);
  return value.ToJs(env);
}

napi_value Js_native_file_dialog_get_last_error(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_file_dialog_get_last_error(self); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

}  // namespace

void RegisterFileDialog(napi_env env, napi_value exports) {
  Export(env, exports, "native_file_dialog_create", Js_native_file_dialog_create);
  Export(env, exports, "native_file_dialog_free", Js_native_file_dialog_free);
  Export(env, exports, "native_file_dialog_is_supported", Js_native_file_dialog_is_supported);
  Export(env, exports, "native_file_dialog_set_parent_window", Js_native_file_dialog_set_parent_window);
  Export(env, exports, "native_file_dialog_set_file_types", Js_native_file_dialog_set_file_types);
  Export(env, exports, "native_file_dialog_set_suggested_file_name", Js_native_file_dialog_set_suggested_file_name);
  Export(env, exports, "native_file_dialog_get_modality", Js_native_file_dialog_get_modality);
  Export(env, exports, "native_file_dialog_set_modality", Js_native_file_dialog_set_modality);
  Export(env, exports, "native_file_dialog_open", Js_native_file_dialog_open);
  Export(env, exports, "native_file_dialog_close", Js_native_file_dialog_close);
  Export(env, exports, "native_file_dialog_get_result", Js_native_file_dialog_get_result);
  Export(env, exports, "native_file_dialog_get_paths", Js_native_file_dialog_get_paths);
  Export(env, exports, "native_file_dialog_get_last_error", Js_native_file_dialog_get_last_error);
}

}  // namespace nativeapi_js
