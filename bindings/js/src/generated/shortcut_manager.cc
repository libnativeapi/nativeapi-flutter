// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_shortcut_manager_is_supported(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_shortcut_manager_is_supported(); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_shortcut_manager_register_with_accelerator_and_callback(napi_env env, napi_callback_info info) {
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
  Callback* p1 = nullptr;
  if (!GetCallback(env, args[1], /*optional=*/false, &p1)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_shortcut_manager_register_with_accelerator_and_callback(p0, +[](void* user_data) { Callback::Dispatch(user_data, {}); }, p1, &Callback::ReleaseUserData); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_shortcut_manager_register_with_options(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  native_shortcut_options_t p0 = {};
  if (!FromJs(env, args[0], &p0, arena)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_shortcut_manager_register_with_options(p0); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_shortcut_manager_unregister_with_id(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_shortcut_manager_unregister_with_id(p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_shortcut_manager_unregister_with_accelerator(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_shortcut_manager_unregister_with_accelerator(p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_shortcut_manager_unregister_all(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_shortcut_manager_unregister_all(); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_shortcut_manager_get_with_id(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_shortcut_manager_get_with_id(p0); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_shortcut_manager_get_with_accelerator(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_shortcut_manager_get_with_accelerator(p0); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_shortcut_manager_get_all(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_shortcut_manager_get_all(); });
  Value value = Value::Array();
  for (long i = 0; i < result.count; ++i) {
    value.Push(Value::BigInt(result.shortcuts[i]));
  }
  // The handles now belong to JS; free just the array.
  native_shortcut_list_release(&result);
  return value.ToJs(env);
}

napi_value Js_native_shortcut_manager_get_by_scope(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  native_shortcut_scope_t p0 = {};
  if (!GetNumber(env, args[0], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_shortcut_manager_get_by_scope(p0); });
  Value value = Value::Array();
  for (long i = 0; i < result.count; ++i) {
    value.Push(Value::BigInt(result.shortcuts[i]));
  }
  // The handles now belong to JS; free just the array.
  native_shortcut_list_release(&result);
  return value.ToJs(env);
}

napi_value Js_native_shortcut_manager_is_available(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_shortcut_manager_is_available(p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_shortcut_manager_is_valid_accelerator(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_shortcut_manager_is_valid_accelerator(p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_shortcut_manager_set_enabled(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  bool p0 = {};
  if (!GetBool(env, args[0], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_shortcut_manager_set_enabled(p0); });
  return Undefined(env);
}

napi_value Js_native_shortcut_manager_is_enabled(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_shortcut_manager_is_enabled(); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_shortcut_manager_emit_shortcut_activated(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_shortcut_manager_emit_shortcut_activated(p0, p1); });
  return Undefined(env);
}

napi_value Js_native_shortcut_manager_add_listener(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  uint64_t self = 0;
  Callback* callback = nullptr;
  if (!GetCallback(env, args[0], /*optional=*/false, &callback)) {
    return nullptr;
  }
  native_listener_id_t id = OnMainThread([&] { return native_shortcut_manager_add_listener(+[](const native_shortcut_event_t* event, void* user_data) {
    if (event != nullptr) {
      Callback::Dispatch(user_data, {ToValue(*event)});
    }
  }, callback, &Callback::ReleaseUserData); });
  return Value::Number(static_cast<double>(id)).ToJs(env);
}

napi_value Js_native_shortcut_manager_remove_listener(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  uint64_t self = 0;
  native_listener_id_t id = 0;
  if (!GetNumber(env, args[0], &id)) {
    return nullptr;
  }
  bool removed = OnMainThread([&] { return native_shortcut_manager_remove_listener(id); });
  return Value::Bool(removed).ToJs(env);
}

}  // namespace

void RegisterShortcutManager(napi_env env, napi_value exports) {
  Export(env, exports, "native_shortcut_manager_is_supported", Js_native_shortcut_manager_is_supported);
  Export(env, exports, "native_shortcut_manager_register_with_accelerator_and_callback", Js_native_shortcut_manager_register_with_accelerator_and_callback);
  Export(env, exports, "native_shortcut_manager_register_with_options", Js_native_shortcut_manager_register_with_options);
  Export(env, exports, "native_shortcut_manager_unregister_with_id", Js_native_shortcut_manager_unregister_with_id);
  Export(env, exports, "native_shortcut_manager_unregister_with_accelerator", Js_native_shortcut_manager_unregister_with_accelerator);
  Export(env, exports, "native_shortcut_manager_unregister_all", Js_native_shortcut_manager_unregister_all);
  Export(env, exports, "native_shortcut_manager_get_with_id", Js_native_shortcut_manager_get_with_id);
  Export(env, exports, "native_shortcut_manager_get_with_accelerator", Js_native_shortcut_manager_get_with_accelerator);
  Export(env, exports, "native_shortcut_manager_get_all", Js_native_shortcut_manager_get_all);
  Export(env, exports, "native_shortcut_manager_get_by_scope", Js_native_shortcut_manager_get_by_scope);
  Export(env, exports, "native_shortcut_manager_is_available", Js_native_shortcut_manager_is_available);
  Export(env, exports, "native_shortcut_manager_is_valid_accelerator", Js_native_shortcut_manager_is_valid_accelerator);
  Export(env, exports, "native_shortcut_manager_set_enabled", Js_native_shortcut_manager_set_enabled);
  Export(env, exports, "native_shortcut_manager_is_enabled", Js_native_shortcut_manager_is_enabled);
  Export(env, exports, "native_shortcut_manager_emit_shortcut_activated", Js_native_shortcut_manager_emit_shortcut_activated);
  Export(env, exports, "native_shortcut_manager_add_listener", Js_native_shortcut_manager_add_listener);
  Export(env, exports, "native_shortcut_manager_remove_listener", Js_native_shortcut_manager_remove_listener);
}

}  // namespace nativeapi_js
