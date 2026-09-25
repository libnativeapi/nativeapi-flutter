// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_tray_icon_create(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_tray_icon_create(); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_tray_icon_create_with_tray(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_tray_icon_create_with_tray(p0); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_tray_icon_free(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_tray_icon_free(self); });
  return Undefined(env);
}

napi_value Js_native_tray_icon_get_native_object(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_tray_icon_get_native_object(self); });
  return Value::BigInt(reinterpret_cast<uintptr_t>(result)).ToJs(env);
}

napi_value Js_native_tray_icon_get_id(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_tray_icon_get_id(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_tray_icon_set_icon(napi_env env, napi_callback_info info) {
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
  native_image_t p0 = {};
  if (!GetHandle(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_tray_icon_set_icon(self, p0); });
  return Undefined(env);
}

napi_value Js_native_tray_icon_get_icon(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_tray_icon_get_icon(self); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_tray_icon_set_icon_template(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_tray_icon_set_icon_template(self, p0); });
  return Undefined(env);
}

napi_value Js_native_tray_icon_is_icon_template(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_tray_icon_is_icon_template(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_tray_icon_set_icon_size(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_tray_icon_set_icon_size(self, p0); });
  return Undefined(env);
}

napi_value Js_native_tray_icon_get_icon_size(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_tray_icon_get_icon_size(self); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_tray_icon_set_icon_position(napi_env env, napi_callback_info info) {
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
  native_tray_icon_position_t p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_tray_icon_set_icon_position(self, p0); });
  return Undefined(env);
}

napi_value Js_native_tray_icon_get_icon_position(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_tray_icon_get_icon_position(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_tray_icon_set_title(napi_env env, napi_callback_info info) {
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
  if (!GetOptionalString(env, args[1], arena, &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_tray_icon_set_title(self, p0); });
  return Undefined(env);
}

napi_value Js_native_tray_icon_get_title(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_tray_icon_get_title(self); });
  Value value = Value::String(result);
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_tray_icon_set_tooltip(napi_env env, napi_callback_info info) {
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
  if (!GetOptionalString(env, args[1], arena, &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_tray_icon_set_tooltip(self, p0); });
  return Undefined(env);
}

napi_value Js_native_tray_icon_get_tooltip(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_tray_icon_get_tooltip(self); });
  Value value = Value::String(result);
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_tray_icon_set_context_menu(napi_env env, napi_callback_info info) {
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
  native_menu_t p0 = {};
  if (!GetHandle(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_tray_icon_set_context_menu(self, p0); });
  return Undefined(env);
}

napi_value Js_native_tray_icon_get_context_menu(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_tray_icon_get_context_menu(self); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_tray_icon_set_context_menu_trigger(napi_env env, napi_callback_info info) {
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
  native_context_menu_trigger_t p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_tray_icon_set_context_menu_trigger(self, p0); });
  return Undefined(env);
}

napi_value Js_native_tray_icon_get_context_menu_trigger(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_tray_icon_get_context_menu_trigger(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_tray_icon_get_bounds(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_tray_icon_get_bounds(self); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_tray_icon_set_visible(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_tray_icon_set_visible(self, p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_tray_icon_is_visible(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_tray_icon_is_visible(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_tray_icon_open_context_menu(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_tray_icon_open_context_menu(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_tray_icon_close_context_menu(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_tray_icon_close_context_menu(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_tray_icon_add_listener(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  uint64_t self = 0;
  if (!GetHandle(env, args[0], &self)) {
    return nullptr;
  }
  Callback* callback = nullptr;
  if (!GetCallback(env, args[1], /*optional=*/false, &callback)) {
    return nullptr;
  }
  native_listener_id_t id = OnMainThread([&] { return native_tray_icon_add_listener(self, +[](const native_tray_icon_event_t* event, void* user_data) {
    if (event != nullptr) {
      Callback::Dispatch(user_data, {ToValue(*event)});
    }
  }, callback, &Callback::ReleaseUserData); });
  return Value::Number(static_cast<double>(id)).ToJs(env);
}

napi_value Js_native_tray_icon_remove_listener(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  uint64_t self = 0;
  if (!GetHandle(env, args[0], &self)) {
    return nullptr;
  }
  native_listener_id_t id = 0;
  if (!GetNumber(env, args[1], &id)) {
    return nullptr;
  }
  bool removed = OnMainThread([&] { return native_tray_icon_remove_listener(self, id); });
  return Value::Bool(removed).ToJs(env);
}

}  // namespace

void RegisterTrayIcon(napi_env env, napi_value exports) {
  Export(env, exports, "native_tray_icon_create", Js_native_tray_icon_create);
  Export(env, exports, "native_tray_icon_create_with_tray", Js_native_tray_icon_create_with_tray);
  Export(env, exports, "native_tray_icon_free", Js_native_tray_icon_free);
  Export(env, exports, "native_tray_icon_get_native_object", Js_native_tray_icon_get_native_object);
  Export(env, exports, "native_tray_icon_get_id", Js_native_tray_icon_get_id);
  Export(env, exports, "native_tray_icon_set_icon", Js_native_tray_icon_set_icon);
  Export(env, exports, "native_tray_icon_get_icon", Js_native_tray_icon_get_icon);
  Export(env, exports, "native_tray_icon_set_icon_template", Js_native_tray_icon_set_icon_template);
  Export(env, exports, "native_tray_icon_is_icon_template", Js_native_tray_icon_is_icon_template);
  Export(env, exports, "native_tray_icon_set_icon_size", Js_native_tray_icon_set_icon_size);
  Export(env, exports, "native_tray_icon_get_icon_size", Js_native_tray_icon_get_icon_size);
  Export(env, exports, "native_tray_icon_set_icon_position", Js_native_tray_icon_set_icon_position);
  Export(env, exports, "native_tray_icon_get_icon_position", Js_native_tray_icon_get_icon_position);
  Export(env, exports, "native_tray_icon_set_title", Js_native_tray_icon_set_title);
  Export(env, exports, "native_tray_icon_get_title", Js_native_tray_icon_get_title);
  Export(env, exports, "native_tray_icon_set_tooltip", Js_native_tray_icon_set_tooltip);
  Export(env, exports, "native_tray_icon_get_tooltip", Js_native_tray_icon_get_tooltip);
  Export(env, exports, "native_tray_icon_set_context_menu", Js_native_tray_icon_set_context_menu);
  Export(env, exports, "native_tray_icon_get_context_menu", Js_native_tray_icon_get_context_menu);
  Export(env, exports, "native_tray_icon_set_context_menu_trigger", Js_native_tray_icon_set_context_menu_trigger);
  Export(env, exports, "native_tray_icon_get_context_menu_trigger", Js_native_tray_icon_get_context_menu_trigger);
  Export(env, exports, "native_tray_icon_get_bounds", Js_native_tray_icon_get_bounds);
  Export(env, exports, "native_tray_icon_set_visible", Js_native_tray_icon_set_visible);
  Export(env, exports, "native_tray_icon_is_visible", Js_native_tray_icon_is_visible);
  Export(env, exports, "native_tray_icon_open_context_menu", Js_native_tray_icon_open_context_menu);
  Export(env, exports, "native_tray_icon_close_context_menu", Js_native_tray_icon_close_context_menu);
  Export(env, exports, "native_tray_icon_add_listener", Js_native_tray_icon_add_listener);
  Export(env, exports, "native_tray_icon_remove_listener", Js_native_tray_icon_remove_listener);
}

}  // namespace nativeapi_js
