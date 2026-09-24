// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_notification_manager_is_supported(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_notification_manager_is_supported(); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_notification_manager_initialize(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_notification_manager_initialize(); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_notification_manager_shutdown(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  OnMainThread([&] { return native_notification_manager_shutdown(); });
  return Undefined(env);
}

napi_value Js_native_notification_manager_show(napi_env env, napi_callback_info info) {
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
  const char* p2 = {};
  if (!GetString(env, args[2], arena, &p2)) {
    return nullptr;
  }
  const char* p3 = {};
  if (!GetString(env, args[3], arena, &p3)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_notification_manager_show(p0, p1, p2, p3); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_notification_manager_remove(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_notification_manager_remove(p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_notification_manager_get_last_error(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_notification_manager_get_last_error(); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_notification_manager_add_listener(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  uint64_t self = 0;
  Callback* callback = nullptr;
  if (!GetCallback(env, args[0], /*optional=*/false, &callback)) {
    return nullptr;
  }
  native_listener_id_t id = OnMainThread([&] { return native_notification_manager_add_listener(+[](const native_notification_event_t* event, void* user_data) {
    if (event != nullptr) {
      Callback::Dispatch(user_data, {ToValue(*event)});
    }
  }, callback); });
  if (id == 0) {
    callback->Release();
  } else {
    RememberListener("native_notification_manager_add_listener", self, id, callback);
  }
  return Value::Number(static_cast<double>(id)).ToJs(env);
}

napi_value Js_native_notification_manager_remove_listener(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  uint64_t self = 0;
  native_listener_id_t id = 0;
  if (!GetNumber(env, args[0], &id)) {
    return nullptr;
  }
  bool removed = OnMainThread([&] { return native_notification_manager_remove_listener(id); });
  if (removed) {
    ForgetListener("native_notification_manager_add_listener", self, id);
  }
  return Value::Bool(removed).ToJs(env);
}

}  // namespace

void RegisterNotificationManager(napi_env env, napi_value exports) {
  Export(env, exports, "native_notification_manager_is_supported", Js_native_notification_manager_is_supported);
  Export(env, exports, "native_notification_manager_initialize", Js_native_notification_manager_initialize);
  Export(env, exports, "native_notification_manager_shutdown", Js_native_notification_manager_shutdown);
  Export(env, exports, "native_notification_manager_show", Js_native_notification_manager_show);
  Export(env, exports, "native_notification_manager_remove", Js_native_notification_manager_remove);
  Export(env, exports, "native_notification_manager_get_last_error", Js_native_notification_manager_get_last_error);
  Export(env, exports, "native_notification_manager_add_listener", Js_native_notification_manager_add_listener);
  Export(env, exports, "native_notification_manager_remove_listener", Js_native_notification_manager_remove_listener);
}

}  // namespace nativeapi_js
