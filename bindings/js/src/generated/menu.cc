// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_menu_item_create_with_label_and_type(napi_env env, napi_callback_info info) {
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
  native_menu_item_type_t p1 = {};
  if (!GetNumber(env, args[1], &p1)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_menu_item_create_with_label_and_type(p0, p1); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_menu_item_create_with_native_item(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_menu_item_create_with_native_item(p0); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_menu_item_free(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_menu_item_free(self); });
  return Undefined(env);
}

napi_value Js_native_menu_item_get_native_object(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_menu_item_get_native_object(self); });
  return Value::BigInt(reinterpret_cast<uintptr_t>(result)).ToJs(env);
}

napi_value Js_native_menu_item_get_id(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_menu_item_get_id(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_menu_item_get_type(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_menu_item_get_type(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_menu_item_set_label(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_menu_item_set_label(self, p0); });
  return Undefined(env);
}

napi_value Js_native_menu_item_get_label(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_menu_item_get_label(self); });
  Value value = Value::String(result);
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_menu_item_set_icon(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_menu_item_set_icon(self, p0); });
  return Undefined(env);
}

napi_value Js_native_menu_item_get_icon(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_menu_item_get_icon(self); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_menu_item_set_tooltip(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_menu_item_set_tooltip(self, p0); });
  return Undefined(env);
}

napi_value Js_native_menu_item_get_tooltip(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_menu_item_get_tooltip(self); });
  Value value = Value::String(result);
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_menu_item_set_accelerator(napi_env env, napi_callback_info info) {
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
  native_keyboard_accelerator_t p0_value = {};
  const native_keyboard_accelerator_t* p0 = nullptr;
  if (!IsNullish(env, args[1])) {
    if (!FromJs(env, args[1], &p0_value, arena)) {
      return nullptr;
    }
    p0 = &p0_value;
  }
  OnMainThread([&] { return native_menu_item_set_accelerator(self, p0); });
  return Undefined(env);
}

napi_value Js_native_menu_item_get_accelerator(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_menu_item_get_accelerator(self); });
  Value value = ToValue(result);
  native_keyboard_accelerator_free(&result);
  return value.ToJs(env);
}

napi_value Js_native_menu_item_set_enabled(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_menu_item_set_enabled(self, p0); });
  return Undefined(env);
}

napi_value Js_native_menu_item_is_enabled(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_menu_item_is_enabled(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_menu_item_set_state(napi_env env, napi_callback_info info) {
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
  native_menu_item_state_t p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_menu_item_set_state(self, p0); });
  return Undefined(env);
}

napi_value Js_native_menu_item_get_state(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_menu_item_get_state(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_menu_item_set_radio_group(napi_env env, napi_callback_info info) {
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
  int p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_menu_item_set_radio_group(self, p0); });
  return Undefined(env);
}

napi_value Js_native_menu_item_get_radio_group(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_menu_item_get_radio_group(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_menu_item_set_submenu(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_menu_item_set_submenu(self, p0); });
  return Undefined(env);
}

napi_value Js_native_menu_item_get_submenu(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_menu_item_get_submenu(self); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_menu_item_add_listener(napi_env env, napi_callback_info info) {
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
  native_listener_id_t id = OnMainThread([&] { return native_menu_item_add_listener(self, +[](const native_menu_event_t* event, void* user_data) {
    if (event != nullptr) {
      Callback::Dispatch(user_data, {ToValue(*event)});
    }
  }, callback); });
  if (id == 0) {
    callback->Release();
  } else {
    RememberListener("native_menu_item_add_listener", self, id, callback);
  }
  return Value::Number(static_cast<double>(id)).ToJs(env);
}

napi_value Js_native_menu_item_remove_listener(napi_env env, napi_callback_info info) {
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
  bool removed = OnMainThread([&] { return native_menu_item_remove_listener(self, id); });
  if (removed) {
    ForgetListener("native_menu_item_add_listener", self, id);
  }
  return Value::Bool(removed).ToJs(env);
}

napi_value Js_native_menu_create(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_menu_create(); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_menu_create_with_native_menu(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_menu_create_with_native_menu(p0); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_menu_free(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_menu_free(self); });
  return Undefined(env);
}

napi_value Js_native_menu_get_native_object(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_menu_get_native_object(self); });
  return Value::BigInt(reinterpret_cast<uintptr_t>(result)).ToJs(env);
}

napi_value Js_native_menu_get_id(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_menu_get_id(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_menu_set_backend(napi_env env, napi_callback_info info) {
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
  native_menu_backend_t p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_menu_set_backend(self, p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_menu_get_backend(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_menu_get_backend(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_menu_is_backend_supported(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  native_menu_backend_t p0 = {};
  if (!GetNumber(env, args[0], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_menu_is_backend_supported(p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_menu_add_item(napi_env env, napi_callback_info info) {
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
  native_menu_item_t p0 = {};
  if (!GetHandle(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_menu_add_item(self, p0); });
  return Undefined(env);
}

napi_value Js_native_menu_insert_item(napi_env env, napi_callback_info info) {
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
  unsigned long p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  native_menu_item_t p1 = {};
  if (!GetHandle(env, args[2], &p1)) {
    return nullptr;
  }
  OnMainThread([&] { return native_menu_insert_item(self, p0, p1); });
  return Undefined(env);
}

napi_value Js_native_menu_remove_item(napi_env env, napi_callback_info info) {
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
  native_menu_item_t p0 = {};
  if (!GetHandle(env, args[1], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_menu_remove_item(self, p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_menu_remove_item_by_id(napi_env env, napi_callback_info info) {
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
  native_menu_item_id_t p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_menu_remove_item_by_id(self, p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_menu_remove_item_at(napi_env env, napi_callback_info info) {
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
  unsigned long p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_menu_remove_item_at(self, p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_menu_clear(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_menu_clear(self); });
  return Undefined(env);
}

napi_value Js_native_menu_add_separator(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_menu_add_separator(self); });
  return Undefined(env);
}

napi_value Js_native_menu_insert_separator(napi_env env, napi_callback_info info) {
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
  unsigned long p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_menu_insert_separator(self, p0); });
  return Undefined(env);
}

napi_value Js_native_menu_get_item_count(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_menu_get_item_count(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_menu_get_item_at(napi_env env, napi_callback_info info) {
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
  unsigned long p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_menu_get_item_at(self, p0); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_menu_get_item_by_id(napi_env env, napi_callback_info info) {
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
  native_menu_item_id_t p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_menu_get_item_by_id(self, p0); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_menu_get_all_items(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_menu_get_all_items(self); });
  Value value = Value::Array();
  for (long i = 0; i < result.count; ++i) {
    value.Push(Value::BigInt(result.menu_items[i]));
  }
  // The handles now belong to JS; free just the array.
  native_menu_item_list_release(&result);
  return value.ToJs(env);
}

napi_value Js_native_menu_open(napi_env env, napi_callback_info info) {
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
  native_positioning_strategy_t p0 = {};
  if (!GetHandle(env, args[1], &p0)) {
    return nullptr;
  }
  native_placement_t p1 = {};
  if (!GetNumber(env, args[2], &p1)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_menu_open(self, p0, p1); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_menu_close(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_menu_close(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_menu_add_listener(napi_env env, napi_callback_info info) {
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
  native_listener_id_t id = OnMainThread([&] { return native_menu_add_listener(self, +[](const native_menu_event_t* event, void* user_data) {
    if (event != nullptr) {
      Callback::Dispatch(user_data, {ToValue(*event)});
    }
  }, callback); });
  if (id == 0) {
    callback->Release();
  } else {
    RememberListener("native_menu_add_listener", self, id, callback);
  }
  return Value::Number(static_cast<double>(id)).ToJs(env);
}

napi_value Js_native_menu_remove_listener(napi_env env, napi_callback_info info) {
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
  bool removed = OnMainThread([&] { return native_menu_remove_listener(self, id); });
  if (removed) {
    ForgetListener("native_menu_add_listener", self, id);
  }
  return Value::Bool(removed).ToJs(env);
}

}  // namespace

void RegisterMenu(napi_env env, napi_value exports) {
  Export(env, exports, "native_menu_item_create_with_label_and_type", Js_native_menu_item_create_with_label_and_type);
  Export(env, exports, "native_menu_item_create_with_native_item", Js_native_menu_item_create_with_native_item);
  Export(env, exports, "native_menu_item_free", Js_native_menu_item_free);
  Export(env, exports, "native_menu_item_get_native_object", Js_native_menu_item_get_native_object);
  Export(env, exports, "native_menu_item_get_id", Js_native_menu_item_get_id);
  Export(env, exports, "native_menu_item_get_type", Js_native_menu_item_get_type);
  Export(env, exports, "native_menu_item_set_label", Js_native_menu_item_set_label);
  Export(env, exports, "native_menu_item_get_label", Js_native_menu_item_get_label);
  Export(env, exports, "native_menu_item_set_icon", Js_native_menu_item_set_icon);
  Export(env, exports, "native_menu_item_get_icon", Js_native_menu_item_get_icon);
  Export(env, exports, "native_menu_item_set_tooltip", Js_native_menu_item_set_tooltip);
  Export(env, exports, "native_menu_item_get_tooltip", Js_native_menu_item_get_tooltip);
  Export(env, exports, "native_menu_item_set_accelerator", Js_native_menu_item_set_accelerator);
  Export(env, exports, "native_menu_item_get_accelerator", Js_native_menu_item_get_accelerator);
  Export(env, exports, "native_menu_item_set_enabled", Js_native_menu_item_set_enabled);
  Export(env, exports, "native_menu_item_is_enabled", Js_native_menu_item_is_enabled);
  Export(env, exports, "native_menu_item_set_state", Js_native_menu_item_set_state);
  Export(env, exports, "native_menu_item_get_state", Js_native_menu_item_get_state);
  Export(env, exports, "native_menu_item_set_radio_group", Js_native_menu_item_set_radio_group);
  Export(env, exports, "native_menu_item_get_radio_group", Js_native_menu_item_get_radio_group);
  Export(env, exports, "native_menu_item_set_submenu", Js_native_menu_item_set_submenu);
  Export(env, exports, "native_menu_item_get_submenu", Js_native_menu_item_get_submenu);
  Export(env, exports, "native_menu_item_add_listener", Js_native_menu_item_add_listener);
  Export(env, exports, "native_menu_item_remove_listener", Js_native_menu_item_remove_listener);
  Export(env, exports, "native_menu_create", Js_native_menu_create);
  Export(env, exports, "native_menu_create_with_native_menu", Js_native_menu_create_with_native_menu);
  Export(env, exports, "native_menu_free", Js_native_menu_free);
  Export(env, exports, "native_menu_get_native_object", Js_native_menu_get_native_object);
  Export(env, exports, "native_menu_get_id", Js_native_menu_get_id);
  Export(env, exports, "native_menu_set_backend", Js_native_menu_set_backend);
  Export(env, exports, "native_menu_get_backend", Js_native_menu_get_backend);
  Export(env, exports, "native_menu_is_backend_supported", Js_native_menu_is_backend_supported);
  Export(env, exports, "native_menu_add_item", Js_native_menu_add_item);
  Export(env, exports, "native_menu_insert_item", Js_native_menu_insert_item);
  Export(env, exports, "native_menu_remove_item", Js_native_menu_remove_item);
  Export(env, exports, "native_menu_remove_item_by_id", Js_native_menu_remove_item_by_id);
  Export(env, exports, "native_menu_remove_item_at", Js_native_menu_remove_item_at);
  Export(env, exports, "native_menu_clear", Js_native_menu_clear);
  Export(env, exports, "native_menu_add_separator", Js_native_menu_add_separator);
  Export(env, exports, "native_menu_insert_separator", Js_native_menu_insert_separator);
  Export(env, exports, "native_menu_get_item_count", Js_native_menu_get_item_count);
  Export(env, exports, "native_menu_get_item_at", Js_native_menu_get_item_at);
  Export(env, exports, "native_menu_get_item_by_id", Js_native_menu_get_item_by_id);
  Export(env, exports, "native_menu_get_all_items", Js_native_menu_get_all_items);
  Export(env, exports, "native_menu_open", Js_native_menu_open);
  Export(env, exports, "native_menu_close", Js_native_menu_close);
  Export(env, exports, "native_menu_add_listener", Js_native_menu_add_listener);
  Export(env, exports, "native_menu_remove_listener", Js_native_menu_remove_listener);
}

}  // namespace nativeapi_js
