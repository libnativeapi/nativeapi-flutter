// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_device_info_get_name(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_device_info_get_name(); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_device_info_get_model(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_device_info_get_model(); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_device_info_get_manufacturer(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_device_info_get_manufacturer(); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_device_info_get_os_name(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_device_info_get_os_name(); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_device_info_get_os_version(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_device_info_get_os_version(); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_device_info_get_kernel_version(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_device_info_get_kernel_version(); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_device_info_get_architecture(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_device_info_get_architecture(); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

}  // namespace

void RegisterDeviceInfo(napi_env env, napi_value exports) {
  Export(env, exports, "native_device_info_get_name", Js_native_device_info_get_name);
  Export(env, exports, "native_device_info_get_model", Js_native_device_info_get_model);
  Export(env, exports, "native_device_info_get_manufacturer", Js_native_device_info_get_manufacturer);
  Export(env, exports, "native_device_info_get_os_name", Js_native_device_info_get_os_name);
  Export(env, exports, "native_device_info_get_os_version", Js_native_device_info_get_os_version);
  Export(env, exports, "native_device_info_get_kernel_version", Js_native_device_info_get_kernel_version);
  Export(env, exports, "native_device_info_get_architecture", Js_native_device_info_get_architecture);
}

}  // namespace nativeapi_js
