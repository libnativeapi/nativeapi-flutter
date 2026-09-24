// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_keyboard_monitor_create(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_keyboard_monitor_create(); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_keyboard_monitor_free(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_keyboard_monitor_free(self); });
  return Undefined(env);
}

napi_value Js_native_keyboard_monitor_start(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_keyboard_monitor_start(self); });
  return Undefined(env);
}

napi_value Js_native_keyboard_monitor_stop(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_keyboard_monitor_stop(self); });
  return Undefined(env);
}

napi_value Js_native_keyboard_monitor_is_monitoring(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_keyboard_monitor_is_monitoring(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_keyboard_monitor_add_listener(napi_env env, napi_callback_info info) {
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
  native_listener_id_t id = OnMainThread([&] { return native_keyboard_monitor_add_listener(self, +[](const native_keyboard_event_t* event, void* user_data) {
    if (event != nullptr) {
      Callback::Dispatch(user_data, {ToValue(*event)});
    }
  }, callback); });
  if (id == 0) {
    callback->Release();
  } else {
    RememberListener("native_keyboard_monitor_add_listener", self, id, callback);
  }
  return Value::Number(static_cast<double>(id)).ToJs(env);
}

napi_value Js_native_keyboard_monitor_remove_listener(napi_env env, napi_callback_info info) {
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
  bool removed = OnMainThread([&] { return native_keyboard_monitor_remove_listener(self, id); });
  if (removed) {
    ForgetListener("native_keyboard_monitor_add_listener", self, id);
  }
  return Value::Bool(removed).ToJs(env);
}

}  // namespace

void RegisterKeyboardMonitor(napi_env env, napi_value exports) {
  Export(env, exports, "native_keyboard_monitor_create", Js_native_keyboard_monitor_create);
  Export(env, exports, "native_keyboard_monitor_free", Js_native_keyboard_monitor_free);
  Export(env, exports, "native_keyboard_monitor_start", Js_native_keyboard_monitor_start);
  Export(env, exports, "native_keyboard_monitor_stop", Js_native_keyboard_monitor_stop);
  Export(env, exports, "native_keyboard_monitor_is_monitoring", Js_native_keyboard_monitor_is_monitoring);
  Export(env, exports, "native_keyboard_monitor_add_listener", Js_native_keyboard_monitor_add_listener);
  Export(env, exports, "native_keyboard_monitor_remove_listener", Js_native_keyboard_monitor_remove_listener);
}

}  // namespace nativeapi_js
