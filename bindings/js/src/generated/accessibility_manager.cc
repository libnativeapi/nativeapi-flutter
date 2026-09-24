// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_accessibility_manager_enable(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  OnMainThread([&] { return native_accessibility_manager_enable(); });
  return Undefined(env);
}

napi_value Js_native_accessibility_manager_is_enabled(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_accessibility_manager_is_enabled(); });
  return Value::Bool(result).ToJs(env);
}

}  // namespace

void RegisterAccessibilityManager(napi_env env, napi_value exports) {
  Export(env, exports, "native_accessibility_manager_enable", Js_native_accessibility_manager_enable);
  Export(env, exports, "native_accessibility_manager_is_enabled", Js_native_accessibility_manager_is_enabled);
}

}  // namespace nativeapi_js
