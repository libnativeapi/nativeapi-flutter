// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_app_info_get_name(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_app_info_get_name(); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_app_info_get_identifier(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_app_info_get_identifier(); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_app_info_get_version(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_app_info_get_version(); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_app_info_get_build_number(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_app_info_get_build_number(); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

}  // namespace

void RegisterAppInfo(napi_env env, napi_value exports) {
  Export(env, exports, "native_app_info_get_name", Js_native_app_info_get_name);
  Export(env, exports, "native_app_info_get_identifier", Js_native_app_info_get_identifier);
  Export(env, exports, "native_app_info_get_version", Js_native_app_info_get_version);
  Export(env, exports, "native_app_info_get_build_number", Js_native_app_info_get_build_number);
}

}  // namespace nativeapi_js
