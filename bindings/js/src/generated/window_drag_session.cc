// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_window_drag_session_create(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_window_drag_session_create(); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_window_drag_session_free(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_window_drag_session_free(self); });
  return Undefined(env);
}

napi_value Js_native_window_drag_session_start(napi_env env, napi_callback_info info) {
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
  native_point_t p1 = {};
  if (!FromJs(env, args[2], &p1, arena)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_window_drag_session_start(self, p0, p1); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_drag_session_cancel(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_window_drag_session_cancel(self); });
  return Undefined(env);
}

napi_value Js_native_window_drag_session_is_active(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_drag_session_is_active(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_window_drag_session_get_window_id(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_drag_session_get_window_id(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_window_drag_session_get_anchor(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_window_drag_session_get_anchor(self); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_window_drag_session_add_listener(napi_env env, napi_callback_info info) {
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
  native_listener_id_t id = OnMainThread([&] { return native_window_drag_session_add_listener(self, +[](const native_window_drag_event_t* event, void* user_data) {
    if (event != nullptr) {
      Callback::Dispatch(user_data, {ToValue(*event)});
    }
  }, callback, &Callback::ReleaseUserData); });
  return Value::Number(static_cast<double>(id)).ToJs(env);
}

napi_value Js_native_window_drag_session_remove_listener(napi_env env, napi_callback_info info) {
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
  bool removed = OnMainThread([&] { return native_window_drag_session_remove_listener(self, id); });
  return Value::Bool(removed).ToJs(env);
}

}  // namespace

void RegisterWindowDragSession(napi_env env, napi_value exports) {
  Export(env, exports, "native_window_drag_session_create", Js_native_window_drag_session_create);
  Export(env, exports, "native_window_drag_session_free", Js_native_window_drag_session_free);
  Export(env, exports, "native_window_drag_session_start", Js_native_window_drag_session_start);
  Export(env, exports, "native_window_drag_session_cancel", Js_native_window_drag_session_cancel);
  Export(env, exports, "native_window_drag_session_is_active", Js_native_window_drag_session_is_active);
  Export(env, exports, "native_window_drag_session_get_window_id", Js_native_window_drag_session_get_window_id);
  Export(env, exports, "native_window_drag_session_get_anchor", Js_native_window_drag_session_get_anchor);
  Export(env, exports, "native_window_drag_session_add_listener", Js_native_window_drag_session_add_listener);
  Export(env, exports, "native_window_drag_session_remove_listener", Js_native_window_drag_session_remove_listener);
}

}  // namespace nativeapi_js
