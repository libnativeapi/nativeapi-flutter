// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_drag_source_create(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_drag_source_create(); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_drag_source_free(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_drag_source_free(self); });
  return Undefined(env);
}

napi_value Js_native_drag_source_is_supported(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_drag_source_is_supported(); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_drag_source_set_file_paths(napi_env env, napi_callback_info info) {
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
  native_string_list_t p0 = {};
  if (!GetStringList(env, args[1], arena, &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_drag_source_set_file_paths(self, p0); });
  return Undefined(env);
}

napi_value Js_native_drag_source_get_file_paths(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_drag_source_get_file_paths(self); });
  Value value = CopyStringList(result);
  native_string_list_free(&result);
  return value.ToJs(env);
}

napi_value Js_native_drag_source_set_text(napi_env env, napi_callback_info info) {
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
  const char* p0 = {};
  if (!GetOptionalString(env, args[1], arena, &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_drag_source_set_text(self, p0); });
  return Undefined(env);
}

napi_value Js_native_drag_source_get_text(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_drag_source_get_text(self); });
  Value value = Value::String(result);
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_drag_source_set_image(napi_env env, napi_callback_info info) {
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
  native_image_t p0 = {};
  if (!GetHandle(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_drag_source_set_image(self, p0); });
  return Undefined(env);
}

napi_value Js_native_drag_source_get_image(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_drag_source_get_image(self); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_drag_source_set_drag_operation(napi_env env, napi_callback_info info) {
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
  native_drag_operation_t p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_drag_source_set_drag_operation(self, p0); });
  return Undefined(env);
}

napi_value Js_native_drag_source_get_drag_operation(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_drag_source_get_drag_operation(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_drag_source_start_dragging(napi_env env, napi_callback_info info) {
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
  native_window_t p0 = {};
  if (!GetHandle(env, args[1], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_drag_source_start_dragging(self, p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_drag_source_is_dragging(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_drag_source_is_dragging(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_drag_source_add_listener(napi_env env, napi_callback_info info) {
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
  native_listener_id_t id = OnMainThread([&] { return native_drag_source_add_listener(self, +[](const native_drag_source_event_t* event, void* user_data) {
    if (event != nullptr) {
      Callback::Dispatch(user_data, {ToValue(*event)});
    }
  }, callback); });
  if (id == 0) {
    callback->Release();
  } else {
    RememberListener("native_drag_source_add_listener", self, id, callback);
  }
  return Value::Number(static_cast<double>(id)).ToJs(env);
}

napi_value Js_native_drag_source_remove_listener(napi_env env, napi_callback_info info) {
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
  bool removed = OnMainThread([&] { return native_drag_source_remove_listener(self, id); });
  if (removed) {
    ForgetListener("native_drag_source_add_listener", self, id);
  }
  return Value::Bool(removed).ToJs(env);
}

}  // namespace

void RegisterDragSource(napi_env env, napi_value exports) {
  Export(env, exports, "native_drag_source_create", Js_native_drag_source_create);
  Export(env, exports, "native_drag_source_free", Js_native_drag_source_free);
  Export(env, exports, "native_drag_source_is_supported", Js_native_drag_source_is_supported);
  Export(env, exports, "native_drag_source_set_file_paths", Js_native_drag_source_set_file_paths);
  Export(env, exports, "native_drag_source_get_file_paths", Js_native_drag_source_get_file_paths);
  Export(env, exports, "native_drag_source_set_text", Js_native_drag_source_set_text);
  Export(env, exports, "native_drag_source_get_text", Js_native_drag_source_get_text);
  Export(env, exports, "native_drag_source_set_image", Js_native_drag_source_set_image);
  Export(env, exports, "native_drag_source_get_image", Js_native_drag_source_get_image);
  Export(env, exports, "native_drag_source_set_drag_operation", Js_native_drag_source_set_drag_operation);
  Export(env, exports, "native_drag_source_get_drag_operation", Js_native_drag_source_get_drag_operation);
  Export(env, exports, "native_drag_source_start_dragging", Js_native_drag_source_start_dragging);
  Export(env, exports, "native_drag_source_is_dragging", Js_native_drag_source_is_dragging);
  Export(env, exports, "native_drag_source_add_listener", Js_native_drag_source_add_listener);
  Export(env, exports, "native_drag_source_remove_listener", Js_native_drag_source_remove_listener);
}

}  // namespace nativeapi_js
