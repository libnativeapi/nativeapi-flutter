// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_display_manager_get_all(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_display_manager_get_all(); });
  Value value = Value::Array();
  for (long i = 0; i < result.count; ++i) {
    value.Push(Value::BigInt(result.displays[i]));
  }
  // The handles now belong to JS; free just the array.
  native_display_list_release(&result);
  return value.ToJs(env);
}

napi_value Js_native_display_manager_get_primary(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_display_manager_get_primary(); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_display_manager_get_cursor_position(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_display_manager_get_cursor_position(); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_display_manager_add_listener(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  uint64_t self = 0;
  Callback* callback = nullptr;
  if (!GetCallback(env, args[0], /*optional=*/false, &callback)) {
    return nullptr;
  }
  native_listener_id_t id = OnMainThread([&] { return native_display_manager_add_listener(+[](const native_display_event_t* event, void* user_data) {
    if (event != nullptr) {
      Callback::Dispatch(user_data, {ToValue(*event)});
    }
  }, callback, &Callback::ReleaseUserData); });
  return Value::Number(static_cast<double>(id)).ToJs(env);
}

napi_value Js_native_display_manager_remove_listener(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  uint64_t self = 0;
  native_listener_id_t id = 0;
  if (!GetNumber(env, args[0], &id)) {
    return nullptr;
  }
  bool removed = OnMainThread([&] { return native_display_manager_remove_listener(id); });
  return Value::Bool(removed).ToJs(env);
}

}  // namespace

void RegisterDisplayManager(napi_env env, napi_value exports) {
  Export(env, exports, "native_display_manager_get_all", Js_native_display_manager_get_all);
  Export(env, exports, "native_display_manager_get_primary", Js_native_display_manager_get_primary);
  Export(env, exports, "native_display_manager_get_cursor_position", Js_native_display_manager_get_cursor_position);
  Export(env, exports, "native_display_manager_add_listener", Js_native_display_manager_add_listener);
  Export(env, exports, "native_display_manager_remove_listener", Js_native_display_manager_remove_listener);
}

}  // namespace nativeapi_js
