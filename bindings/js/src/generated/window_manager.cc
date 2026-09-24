// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_window_manager_get(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  native_window_id_t p0 = {};
  if (!GetNumber(env, args[0], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_window_manager_get(p0); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_window_manager_get_all(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_window_manager_get_all(); });
  Value value = Value::Array();
  for (long i = 0; i < result.count; ++i) {
    value.Push(Value::BigInt(result.windows[i]));
  }
  // The handles now belong to JS; free just the array.
  native_window_list_release(&result);
  return value.ToJs(env);
}

napi_value Js_native_window_manager_get_current(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_window_manager_get_current(); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_window_manager_get_window_at_point(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  native_point_t p0 = {};
  if (!FromJs(env, args[0], &p0, arena)) {
    return nullptr;
  }
  native_window_id_t p1 = {};
  if (!GetNumber(env, args[1], &p1)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_window_manager_get_window_at_point(p0, p1); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_window_manager_set_will_show_hook(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  Callback* p0 = nullptr;
  if (!GetCallback(env, args[0], /*optional=*/true, &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_manager_set_will_show_hook(p0 ? +[](unsigned int arg0, void* user_data) { Callback::Dispatch(user_data, {Value::Number(static_cast<double>(arg0))}); } : nullptr, p0); });
  return Undefined(env);
}

napi_value Js_native_window_manager_set_will_hide_hook(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  Callback* p0 = nullptr;
  if (!GetCallback(env, args[0], /*optional=*/true, &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_manager_set_will_hide_hook(p0 ? +[](unsigned int arg0, void* user_data) { Callback::Dispatch(user_data, {Value::Number(static_cast<double>(arg0))}); } : nullptr, p0); });
  return Undefined(env);
}

napi_value Js_native_window_manager_has_will_show_hook(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_window_manager_has_will_show_hook(); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_manager_has_will_hide_hook(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_window_manager_has_will_hide_hook(); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_manager_handle_will_show(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  native_window_id_t p0 = {};
  if (!GetNumber(env, args[0], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_manager_handle_will_show(p0); });
  return Undefined(env);
}

napi_value Js_native_window_manager_handle_will_hide(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  native_window_id_t p0 = {};
  if (!GetNumber(env, args[0], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_window_manager_handle_will_hide(p0); });
  return Undefined(env);
}

napi_value Js_native_window_manager_call_original_show(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  native_window_id_t p0 = {};
  if (!GetNumber(env, args[0], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_window_manager_call_original_show(p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_manager_call_original_hide(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  native_window_id_t p0 = {};
  if (!GetNumber(env, args[0], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_window_manager_call_original_hide(p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_manager_add_listener(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  uint64_t self = 0;
  Callback* callback = nullptr;
  if (!GetCallback(env, args[0], /*optional=*/false, &callback)) {
    return nullptr;
  }
  native_listener_id_t id = OnMainThread([&] { return native_window_manager_add_listener(+[](const native_window_event_t* event, void* user_data) {
    if (event != nullptr) {
      Callback::Dispatch(user_data, {ToValue(*event)});
    }
  }, callback); });
  if (id == 0) {
    callback->Release();
  } else {
    RememberListener("native_window_manager_add_listener", self, id, callback);
  }
  return Value::Number(static_cast<double>(id)).ToJs(env);
}

napi_value Js_native_window_manager_remove_listener(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  uint64_t self = 0;
  native_listener_id_t id = 0;
  if (!GetNumber(env, args[0], &id)) {
    return nullptr;
  }
  bool removed = OnMainThread([&] { return native_window_manager_remove_listener(id); });
  if (removed) {
    ForgetListener("native_window_manager_add_listener", self, id);
  }
  return Value::Bool(removed).ToJs(env);
}

}  // namespace

void RegisterWindowManager(napi_env env, napi_value exports) {
  Export(env, exports, "native_window_manager_get", Js_native_window_manager_get);
  Export(env, exports, "native_window_manager_get_all", Js_native_window_manager_get_all);
  Export(env, exports, "native_window_manager_get_current", Js_native_window_manager_get_current);
  Export(env, exports, "native_window_manager_get_window_at_point", Js_native_window_manager_get_window_at_point);
  Export(env, exports, "native_window_manager_set_will_show_hook", Js_native_window_manager_set_will_show_hook);
  Export(env, exports, "native_window_manager_set_will_hide_hook", Js_native_window_manager_set_will_hide_hook);
  Export(env, exports, "native_window_manager_has_will_show_hook", Js_native_window_manager_has_will_show_hook);
  Export(env, exports, "native_window_manager_has_will_hide_hook", Js_native_window_manager_has_will_hide_hook);
  Export(env, exports, "native_window_manager_handle_will_show", Js_native_window_manager_handle_will_show);
  Export(env, exports, "native_window_manager_handle_will_hide", Js_native_window_manager_handle_will_hide);
  Export(env, exports, "native_window_manager_call_original_show", Js_native_window_manager_call_original_show);
  Export(env, exports, "native_window_manager_call_original_hide", Js_native_window_manager_call_original_hide);
  Export(env, exports, "native_window_manager_add_listener", Js_native_window_manager_add_listener);
  Export(env, exports, "native_window_manager_remove_listener", Js_native_window_manager_remove_listener);
}

}  // namespace nativeapi_js
