// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_drop_target_create(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  native_window_t p0 = {};
  if (!GetHandle(env, args[0], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_drop_target_create(p0); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_drop_target_free(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_drop_target_free(self); });
  return Undefined(env);
}

napi_value Js_native_drop_target_is_supported(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_drop_target_is_supported(); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_drop_target_get_window_id(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_drop_target_get_window_id(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_drop_target_set_drop_operation(napi_env env, napi_callback_info info) {
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
  native_drag_operation_t p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_drop_target_set_drop_operation(self, p0); });
  return Undefined(env);
}

napi_value Js_native_drop_target_get_drop_operation(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_drop_target_get_drop_operation(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_drop_target_is_active(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_drop_target_is_active(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_drop_target_add_listener(napi_env env, napi_callback_info info) {
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
  native_listener_id_t id = OnMainThread([&] { return native_drop_target_add_listener(self, +[](const native_drop_target_event_t* event, void* user_data) {
    if (event != nullptr) {
      Callback::Dispatch(user_data, {ToValue(*event)});
    }
  }, callback, &Callback::ReleaseUserData); });
  return Value::Number(static_cast<double>(id)).ToJs(env);
}

napi_value Js_native_drop_target_remove_listener(napi_env env, napi_callback_info info) {
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
  bool removed = OnMainThread([&] { return native_drop_target_remove_listener(self, id); });
  return Value::Bool(removed).ToJs(env);
}

}  // namespace

void RegisterDropTarget(napi_env env, napi_value exports) {
  Export(env, exports, "native_drop_target_create", Js_native_drop_target_create);
  Export(env, exports, "native_drop_target_free", Js_native_drop_target_free);
  Export(env, exports, "native_drop_target_is_supported", Js_native_drop_target_is_supported);
  Export(env, exports, "native_drop_target_get_window_id", Js_native_drop_target_get_window_id);
  Export(env, exports, "native_drop_target_set_drop_operation", Js_native_drop_target_set_drop_operation);
  Export(env, exports, "native_drop_target_get_drop_operation", Js_native_drop_target_get_drop_operation);
  Export(env, exports, "native_drop_target_is_active", Js_native_drop_target_is_active);
  Export(env, exports, "native_drop_target_add_listener", Js_native_drop_target_add_listener);
  Export(env, exports, "native_drop_target_remove_listener", Js_native_drop_target_remove_listener);
}

}  // namespace nativeapi_js
