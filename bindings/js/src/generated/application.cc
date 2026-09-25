// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_application_run(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_application_run(); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_application_run_with_window(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_application_run_with_window(p0); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_application_quit(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  int p0 = {};
  if (!GetNumber(env, args[0], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_application_quit(p0); });
  return Undefined(env);
}

napi_value Js_native_application_is_running(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_application_is_running(); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_application_is_single_instance(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_application_is_single_instance(); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_application_set_icon(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_application_set_icon(p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_application_set_dock_icon_visible(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_application_set_dock_icon_visible(p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_application_set_progress_bar(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  double p0 = {};
  if (!GetNumber(env, args[0], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_application_set_progress_bar(p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_application_set_badge_label(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_application_set_badge_label(p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_application_set_brightness(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  native_brightness_t p0 = {};
  if (!GetNumber(env, args[0], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_application_set_brightness(p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_application_set_menu_bar(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  native_menu_t p0 = {};
  if (!GetHandle(env, args[0], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_application_set_menu_bar(p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_application_get_primary_window(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_application_get_primary_window(); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_application_set_primary_window(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_application_set_primary_window(p0); });
  return Undefined(env);
}

napi_value Js_native_application_get_all_windows(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_application_get_all_windows(); });
  Value value = Value::Array();
  for (long i = 0; i < result.count; ++i) {
    value.Push(Value::BigInt(result.windows[i]));
  }
  // The handles now belong to JS; free just the array.
  native_window_list_release(&result);
  return value.ToJs(env);
}

napi_value Js_native_application_add_listener(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  uint64_t self = 0;
  Callback* callback = nullptr;
  if (!GetCallback(env, args[0], /*optional=*/false, &callback)) {
    return nullptr;
  }
  native_listener_id_t id = OnMainThread([&] { return native_application_add_listener(+[](const native_application_event_t* event, void* user_data) {
    if (event != nullptr) {
      Callback::Dispatch(user_data, {ToValue(*event)});
    }
  }, callback, &Callback::ReleaseUserData); });
  return Value::Number(static_cast<double>(id)).ToJs(env);
}

napi_value Js_native_application_remove_listener(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  uint64_t self = 0;
  native_listener_id_t id = 0;
  if (!GetNumber(env, args[0], &id)) {
    return nullptr;
  }
  bool removed = OnMainThread([&] { return native_application_remove_listener(id); });
  return Value::Bool(removed).ToJs(env);
}

}  // namespace

void RegisterApplication(napi_env env, napi_value exports) {
  Export(env, exports, "native_application_run", Js_native_application_run);
  Export(env, exports, "native_application_run_with_window", Js_native_application_run_with_window);
  Export(env, exports, "native_application_quit", Js_native_application_quit);
  Export(env, exports, "native_application_is_running", Js_native_application_is_running);
  Export(env, exports, "native_application_is_single_instance", Js_native_application_is_single_instance);
  Export(env, exports, "native_application_set_icon", Js_native_application_set_icon);
  Export(env, exports, "native_application_set_dock_icon_visible", Js_native_application_set_dock_icon_visible);
  Export(env, exports, "native_application_set_progress_bar", Js_native_application_set_progress_bar);
  Export(env, exports, "native_application_set_badge_label", Js_native_application_set_badge_label);
  Export(env, exports, "native_application_set_brightness", Js_native_application_set_brightness);
  Export(env, exports, "native_application_set_menu_bar", Js_native_application_set_menu_bar);
  Export(env, exports, "native_application_get_primary_window", Js_native_application_get_primary_window);
  Export(env, exports, "native_application_set_primary_window", Js_native_application_set_primary_window);
  Export(env, exports, "native_application_get_all_windows", Js_native_application_get_all_windows);
  Export(env, exports, "native_application_add_listener", Js_native_application_add_listener);
  Export(env, exports, "native_application_remove_listener", Js_native_application_remove_listener);
}

}  // namespace nativeapi_js
