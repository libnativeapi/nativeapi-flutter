// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_url_opener_is_supported(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_url_opener_is_supported(); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_url_opener_can_open(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_url_opener_can_open(p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_url_opener_open(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_url_opener_open(p0); });
  Value value = ToValue(result);
  native_url_open_result_free(&result);
  return value.ToJs(env);
}

}  // namespace

void RegisterUrlOpener(napi_env env, napi_value exports) {
  Export(env, exports, "native_url_opener_is_supported", Js_native_url_opener_is_supported);
  Export(env, exports, "native_url_opener_can_open", Js_native_url_opener_can_open);
  Export(env, exports, "native_url_opener_open", Js_native_url_opener_open);
}

}  // namespace nativeapi_js
