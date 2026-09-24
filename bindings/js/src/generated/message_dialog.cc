// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_message_dialog_create(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_message_dialog_create(p0, p1); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_message_dialog_free(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_message_dialog_free(self); });
  return Undefined(env);
}

napi_value Js_native_message_dialog_is_extended_supported(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_message_dialog_is_extended_supported(); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_message_dialog_set_buttons(napi_env env, napi_callback_info info) {
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
  const char* p2 = {};
  if (!GetString(env, args[3], arena, &p2)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_message_dialog_set_buttons(self, p0, p1, p2); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_message_dialog_set_default_button(napi_env env, napi_callback_info info) {
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
  native_message_dialog_result_t p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_message_dialog_set_default_button(self, p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_message_dialog_set_parent_window(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_message_dialog_set_parent_window(self, p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_message_dialog_get_result(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_message_dialog_get_result(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_message_dialog_is_open(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_message_dialog_is_open(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_message_dialog_set_input_enabled(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_message_dialog_set_input_enabled(self, p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_message_dialog_set_input_text(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_message_dialog_set_input_text(self, p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_message_dialog_get_input_text(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_message_dialog_get_input_text(self); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_message_dialog_set_checkbox(napi_env env, napi_callback_info info) {
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
  bool p1 = {};
  if (!GetBool(env, args[2], &p1)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_message_dialog_set_checkbox(self, p0, p1); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_message_dialog_is_checkbox_checked(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_message_dialog_is_checkbox_checked(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_message_dialog_set_progress(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_message_dialog_set_progress(self, p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_message_dialog_set_title(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_message_dialog_set_title(self, p0); });
  return Undefined(env);
}

napi_value Js_native_message_dialog_get_title(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_message_dialog_get_title(self); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_message_dialog_set_message(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_message_dialog_set_message(self, p0); });
  return Undefined(env);
}

napi_value Js_native_message_dialog_get_message(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_message_dialog_get_message(self); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_message_dialog_get_modality(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_message_dialog_get_modality(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_message_dialog_set_modality(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_message_dialog_set_modality(self, p0); });
  return Undefined(env);
}

napi_value Js_native_message_dialog_open(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_message_dialog_open(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_message_dialog_close(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_message_dialog_close(self); });
  return Value::Bool(result).ToJs(env);
}

}  // namespace

void RegisterMessageDialog(napi_env env, napi_value exports) {
  Export(env, exports, "native_message_dialog_create", Js_native_message_dialog_create);
  Export(env, exports, "native_message_dialog_free", Js_native_message_dialog_free);
  Export(env, exports, "native_message_dialog_is_extended_supported", Js_native_message_dialog_is_extended_supported);
  Export(env, exports, "native_message_dialog_set_buttons", Js_native_message_dialog_set_buttons);
  Export(env, exports, "native_message_dialog_set_default_button", Js_native_message_dialog_set_default_button);
  Export(env, exports, "native_message_dialog_set_parent_window", Js_native_message_dialog_set_parent_window);
  Export(env, exports, "native_message_dialog_get_result", Js_native_message_dialog_get_result);
  Export(env, exports, "native_message_dialog_is_open", Js_native_message_dialog_is_open);
  Export(env, exports, "native_message_dialog_set_input_enabled", Js_native_message_dialog_set_input_enabled);
  Export(env, exports, "native_message_dialog_set_input_text", Js_native_message_dialog_set_input_text);
  Export(env, exports, "native_message_dialog_get_input_text", Js_native_message_dialog_get_input_text);
  Export(env, exports, "native_message_dialog_set_checkbox", Js_native_message_dialog_set_checkbox);
  Export(env, exports, "native_message_dialog_is_checkbox_checked", Js_native_message_dialog_is_checkbox_checked);
  Export(env, exports, "native_message_dialog_set_progress", Js_native_message_dialog_set_progress);
  Export(env, exports, "native_message_dialog_set_title", Js_native_message_dialog_set_title);
  Export(env, exports, "native_message_dialog_get_title", Js_native_message_dialog_get_title);
  Export(env, exports, "native_message_dialog_set_message", Js_native_message_dialog_set_message);
  Export(env, exports, "native_message_dialog_get_message", Js_native_message_dialog_get_message);
  Export(env, exports, "native_message_dialog_get_modality", Js_native_message_dialog_get_modality);
  Export(env, exports, "native_message_dialog_set_modality", Js_native_message_dialog_set_modality);
  Export(env, exports, "native_message_dialog_open", Js_native_message_dialog_open);
  Export(env, exports, "native_message_dialog_close", Js_native_message_dialog_close);
}

}  // namespace nativeapi_js
