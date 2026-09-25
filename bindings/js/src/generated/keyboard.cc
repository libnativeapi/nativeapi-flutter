// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_keyboard_accelerator_to_string(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  native_keyboard_accelerator_t self = {};
  if (!FromJs(env, args[0], &self, arena)) {
    return nullptr;
  }
  auto result = native_keyboard_accelerator_to_string(self);
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_keyboard_accelerator_is_empty(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  native_keyboard_accelerator_t self = {};
  if (!FromJs(env, args[0], &self, arena)) {
    return nullptr;
  }
  auto result = native_keyboard_accelerator_is_empty(self);
  return Value::Bool(result).ToJs(env);
}

}  // namespace

void RegisterKeyboard(napi_env env, napi_value exports) {
  Export(env, exports, "native_keyboard_accelerator_to_string", Js_native_keyboard_accelerator_to_string);
  Export(env, exports, "native_keyboard_accelerator_is_empty", Js_native_keyboard_accelerator_is_empty);
}

}  // namespace nativeapi_js
