// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_tray_manager_is_supported(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_tray_manager_is_supported(); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_tray_manager_get(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  native_tray_icon_id_t p0 = {};
  if (!GetNumber(env, args[0], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_tray_manager_get(p0); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_tray_manager_get_all(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_tray_manager_get_all(); });
  Value value = Value::Array();
  for (long i = 0; i < result.count; ++i) {
    value.Push(Value::BigInt(result.tray_icons[i]));
  }
  // The handles now belong to JS; free just the array.
  native_tray_icon_list_release(&result);
  return value.ToJs(env);
}

}  // namespace

void RegisterTrayManager(napi_env env, napi_value exports) {
  Export(env, exports, "native_tray_manager_is_supported", Js_native_tray_manager_is_supported);
  Export(env, exports, "native_tray_manager_get", Js_native_tray_manager_get);
  Export(env, exports, "native_tray_manager_get_all", Js_native_tray_manager_get_all);
}

}  // namespace nativeapi_js
