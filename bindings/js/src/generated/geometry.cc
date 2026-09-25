// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_edge_insets_all(napi_env env, napi_callback_info info) {
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
  auto result = native_edge_insets_all(p0);
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_edge_insets_symmetric(napi_env env, napi_callback_info info) {
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
  double p1 = {};
  if (!GetNumber(env, args[1], &p1)) {
    return nullptr;
  }
  auto result = native_edge_insets_symmetric(p0, p1);
  Value value = ToValue(result);
  return value.ToJs(env);
}

}  // namespace

void RegisterGeometry(napi_env env, napi_value exports) {
  Export(env, exports, "native_edge_insets_all", Js_native_edge_insets_all);
  Export(env, exports, "native_edge_insets_symmetric", Js_native_edge_insets_symmetric);
}

}  // namespace nativeapi_js
