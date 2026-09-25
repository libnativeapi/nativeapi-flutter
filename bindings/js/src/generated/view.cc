// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_view_create(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_view_create(); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_view_create_with_native_view(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  void* p0 = {};
  if (!GetPointer(env, args[0], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_view_create_with_native_view(p0); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_view_free(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_view_free(self); });
  return Undefined(env);
}

napi_value Js_native_view_get_native_object(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_view_get_native_object(self); });
  return Value::BigInt(reinterpret_cast<uintptr_t>(result)).ToJs(env);
}

napi_value Js_native_view_is_supported(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_view_is_supported(); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_view_get_id(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_view_get_id(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_view_add_subview(napi_env env, napi_callback_info info) {
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
  native_view_t p0 = {};
  if (!GetHandle(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_view_add_subview(self, p0); });
  return Undefined(env);
}

napi_value Js_native_view_insert_subview(napi_env env, napi_callback_info info) {
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
  unsigned long p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  native_view_t p1 = {};
  if (!GetHandle(env, args[2], &p1)) {
    return nullptr;
  }
  OnMainThread([&] { return native_view_insert_subview(self, p0, p1); });
  return Undefined(env);
}

napi_value Js_native_view_remove_subview(napi_env env, napi_callback_info info) {
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
  native_view_t p0 = {};
  if (!GetHandle(env, args[1], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_view_remove_subview(self, p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_view_remove_subview_at(napi_env env, napi_callback_info info) {
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
  unsigned long p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_view_remove_subview_at(self, p0); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_view_clear_subviews(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_view_clear_subviews(self); });
  return Undefined(env);
}

napi_value Js_native_view_get_subview_count(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_view_get_subview_count(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_view_get_subview_at(napi_env env, napi_callback_info info) {
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
  unsigned long p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_view_get_subview_at(self, p0); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_view_get_subviews(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_view_get_subviews(self); });
  Value value = Value::Array();
  for (long i = 0; i < result.count; ++i) {
    value.Push(Value::BigInt(result.views[i]));
  }
  // The handles now belong to JS; free just the array.
  native_view_list_release(&result);
  return value.ToJs(env);
}

napi_value Js_native_view_get_parent(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_view_get_parent(self); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_view_get_window(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_view_get_window(self); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_view_set_frame(napi_env env, napi_callback_info info) {
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
  native_rectangle_t p0 = {};
  if (!FromJs(env, args[1], &p0, arena)) {
    return nullptr;
  }
  OnMainThread([&] { return native_view_set_frame(self, p0); });
  return Undefined(env);
}

napi_value Js_native_view_get_frame(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_view_get_frame(self); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_view_set_preferred_size(napi_env env, napi_callback_info info) {
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
  native_size_t p0 = {};
  if (!FromJs(env, args[1], &p0, arena)) {
    return nullptr;
  }
  OnMainThread([&] { return native_view_set_preferred_size(self, p0); });
  return Undefined(env);
}

napi_value Js_native_view_get_preferred_size(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_view_get_preferred_size(self); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_view_get_intrinsic_size(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_view_get_intrinsic_size(self); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_view_set_flex(napi_env env, napi_callback_info info) {
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
  double p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_view_set_flex(self, p0); });
  return Undefined(env);
}

napi_value Js_native_view_get_flex(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_view_get_flex(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_view_set_alignment(napi_env env, napi_callback_info info) {
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
  native_view_alignment_t p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_view_set_alignment(self, p0); });
  return Undefined(env);
}

napi_value Js_native_view_get_alignment(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_view_get_alignment(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_view_set_layout(napi_env env, napi_callback_info info) {
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
  native_view_layout_t p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_view_set_layout(self, p0); });
  return Undefined(env);
}

napi_value Js_native_view_get_layout(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_view_get_layout(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_view_set_spacing(napi_env env, napi_callback_info info) {
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
  double p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_view_set_spacing(self, p0); });
  return Undefined(env);
}

napi_value Js_native_view_get_spacing(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_view_get_spacing(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_view_set_padding(napi_env env, napi_callback_info info) {
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
  native_edge_insets_t p0 = {};
  if (!FromJs(env, args[1], &p0, arena)) {
    return nullptr;
  }
  OnMainThread([&] { return native_view_set_padding(self, p0); });
  return Undefined(env);
}

napi_value Js_native_view_get_padding(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_view_get_padding(self); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_view_set_visible(napi_env env, napi_callback_info info) {
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
  bool p0 = {};
  if (!GetBool(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_view_set_visible(self, p0); });
  return Undefined(env);
}

napi_value Js_native_view_is_visible(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_view_is_visible(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_view_set_enabled(napi_env env, napi_callback_info info) {
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
  bool p0 = {};
  if (!GetBool(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_view_set_enabled(self, p0); });
  return Undefined(env);
}

napi_value Js_native_view_is_enabled(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_view_is_enabled(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_view_set_background_color(napi_env env, napi_callback_info info) {
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
  native_color_t p0 = {};
  if (!FromJs(env, args[1], &p0, arena)) {
    return nullptr;
  }
  OnMainThread([&] { return native_view_set_background_color(self, p0); });
  return Undefined(env);
}

napi_value Js_native_view_get_background_color(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_view_get_background_color(self); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_view_set_tooltip(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_view_set_tooltip(self, p0); });
  return Undefined(env);
}

napi_value Js_native_view_get_tooltip(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_view_get_tooltip(self); });
  Value value = Value::String(result);
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_view_focus(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_view_focus(self); });
  return Undefined(env);
}

napi_value Js_native_view_blur(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_view_blur(self); });
  return Undefined(env);
}

napi_value Js_native_view_is_focused(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_view_is_focused(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_view_add_listener(napi_env env, napi_callback_info info) {
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
  native_listener_id_t id = OnMainThread([&] { return native_view_add_listener(self, +[](const native_view_event_t* event, void* user_data) {
    if (event != nullptr) {
      Callback::Dispatch(user_data, {ToValue(*event)});
    }
  }, callback, &Callback::ReleaseUserData); });
  return Value::Number(static_cast<double>(id)).ToJs(env);
}

napi_value Js_native_view_remove_listener(napi_env env, napi_callback_info info) {
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
  bool removed = OnMainThread([&] { return native_view_remove_listener(self, id); });
  return Value::Bool(removed).ToJs(env);
}

napi_value Js_native_label_create(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_label_create(p0); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_label_free(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_label_free(self); });
  return Undefined(env);
}

napi_value Js_native_label_set_text(napi_env env, napi_callback_info info) {
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
  if (!GetString(env, args[1], arena, &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_label_set_text(self, p0); });
  return Undefined(env);
}

napi_value Js_native_label_get_text(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_label_get_text(self); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_label_set_text_color(napi_env env, napi_callback_info info) {
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
  native_color_t p0 = {};
  if (!FromJs(env, args[1], &p0, arena)) {
    return nullptr;
  }
  OnMainThread([&] { return native_label_set_text_color(self, p0); });
  return Undefined(env);
}

napi_value Js_native_label_get_text_color(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_label_get_text_color(self); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_label_set_font_size(napi_env env, napi_callback_info info) {
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
  double p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_label_set_font_size(self, p0); });
  return Undefined(env);
}

napi_value Js_native_label_get_font_size(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_label_get_font_size(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_label_set_text_alignment(napi_env env, napi_callback_info info) {
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
  native_text_alignment_t p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_label_set_text_alignment(self, p0); });
  return Undefined(env);
}

napi_value Js_native_label_get_text_alignment(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_label_get_text_alignment(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_button_create(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_button_create(p0); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_button_free(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_button_free(self); });
  return Undefined(env);
}

napi_value Js_native_button_set_text(napi_env env, napi_callback_info info) {
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
  if (!GetString(env, args[1], arena, &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_button_set_text(self, p0); });
  return Undefined(env);
}

napi_value Js_native_button_get_text(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_button_get_text(self); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_text_field_create(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_text_field_create(p0); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_text_field_free(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_text_field_free(self); });
  return Undefined(env);
}

napi_value Js_native_text_field_set_text(napi_env env, napi_callback_info info) {
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
  if (!GetString(env, args[1], arena, &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_text_field_set_text(self, p0); });
  return Undefined(env);
}

napi_value Js_native_text_field_get_text(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_text_field_get_text(self); });
  Value value = Value::String(result ? result : "");
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_text_field_set_text_color(napi_env env, napi_callback_info info) {
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
  native_color_t p0 = {};
  if (!FromJs(env, args[1], &p0, arena)) {
    return nullptr;
  }
  OnMainThread([&] { return native_text_field_set_text_color(self, p0); });
  return Undefined(env);
}

napi_value Js_native_text_field_get_text_color(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_text_field_get_text_color(self); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_text_field_set_font_size(napi_env env, napi_callback_info info) {
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
  double p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_text_field_set_font_size(self, p0); });
  return Undefined(env);
}

napi_value Js_native_text_field_get_font_size(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_text_field_get_font_size(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_text_field_set_text_alignment(napi_env env, napi_callback_info info) {
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
  native_text_alignment_t p0 = {};
  if (!GetNumber(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_text_field_set_text_alignment(self, p0); });
  return Undefined(env);
}

napi_value Js_native_text_field_get_text_alignment(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_text_field_get_text_alignment(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_text_field_set_placeholder(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_text_field_set_placeholder(self, p0); });
  return Undefined(env);
}

napi_value Js_native_text_field_get_placeholder(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_text_field_get_placeholder(self); });
  Value value = Value::String(result);
  free_c_str(result);
  return value.ToJs(env);
}

napi_value Js_native_text_field_set_editable(napi_env env, napi_callback_info info) {
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
  bool p0 = {};
  if (!GetBool(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_text_field_set_editable(self, p0); });
  return Undefined(env);
}

napi_value Js_native_text_field_is_editable(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_text_field_is_editable(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_text_field_set_secure(napi_env env, napi_callback_info info) {
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
  bool p0 = {};
  if (!GetBool(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_text_field_set_secure(self, p0); });
  return Undefined(env);
}

napi_value Js_native_text_field_is_secure(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_text_field_is_secure(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_text_field_set_multiline(napi_env env, napi_callback_info info) {
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
  bool p0 = {};
  if (!GetBool(env, args[1], &p0)) {
    return nullptr;
  }
  OnMainThread([&] { return native_text_field_set_multiline(self, p0); });
  return Undefined(env);
}

napi_value Js_native_text_field_is_multiline(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_text_field_is_multiline(self); });
  return Value::Bool(result).ToJs(env);
}

napi_value Js_native_image_view_create(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  auto result = OnMainThread([&] { return native_image_view_create(); });
  return Value::BigInt(result).ToJs(env);
}

napi_value Js_native_image_view_free(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_image_view_free(self); });
  return Undefined(env);
}

napi_value Js_native_image_view_set_image(napi_env env, napi_callback_info info) {
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
  OnMainThread([&] { return native_image_view_set_image(self, p0); });
  return Undefined(env);
}

napi_value Js_native_image_view_get_image(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_image_view_get_image(self); });
  return Value::BigInt(result).ToJs(env);
}

}  // namespace

void RegisterView(napi_env env, napi_value exports) {
  Export(env, exports, "native_view_create", Js_native_view_create);
  Export(env, exports, "native_view_create_with_native_view", Js_native_view_create_with_native_view);
  Export(env, exports, "native_view_free", Js_native_view_free);
  Export(env, exports, "native_view_get_native_object", Js_native_view_get_native_object);
  Export(env, exports, "native_view_is_supported", Js_native_view_is_supported);
  Export(env, exports, "native_view_get_id", Js_native_view_get_id);
  Export(env, exports, "native_view_add_subview", Js_native_view_add_subview);
  Export(env, exports, "native_view_insert_subview", Js_native_view_insert_subview);
  Export(env, exports, "native_view_remove_subview", Js_native_view_remove_subview);
  Export(env, exports, "native_view_remove_subview_at", Js_native_view_remove_subview_at);
  Export(env, exports, "native_view_clear_subviews", Js_native_view_clear_subviews);
  Export(env, exports, "native_view_get_subview_count", Js_native_view_get_subview_count);
  Export(env, exports, "native_view_get_subview_at", Js_native_view_get_subview_at);
  Export(env, exports, "native_view_get_subviews", Js_native_view_get_subviews);
  Export(env, exports, "native_view_get_parent", Js_native_view_get_parent);
  Export(env, exports, "native_view_get_window", Js_native_view_get_window);
  Export(env, exports, "native_view_set_frame", Js_native_view_set_frame);
  Export(env, exports, "native_view_get_frame", Js_native_view_get_frame);
  Export(env, exports, "native_view_set_preferred_size", Js_native_view_set_preferred_size);
  Export(env, exports, "native_view_get_preferred_size", Js_native_view_get_preferred_size);
  Export(env, exports, "native_view_get_intrinsic_size", Js_native_view_get_intrinsic_size);
  Export(env, exports, "native_view_set_flex", Js_native_view_set_flex);
  Export(env, exports, "native_view_get_flex", Js_native_view_get_flex);
  Export(env, exports, "native_view_set_alignment", Js_native_view_set_alignment);
  Export(env, exports, "native_view_get_alignment", Js_native_view_get_alignment);
  Export(env, exports, "native_view_set_layout", Js_native_view_set_layout);
  Export(env, exports, "native_view_get_layout", Js_native_view_get_layout);
  Export(env, exports, "native_view_set_spacing", Js_native_view_set_spacing);
  Export(env, exports, "native_view_get_spacing", Js_native_view_get_spacing);
  Export(env, exports, "native_view_set_padding", Js_native_view_set_padding);
  Export(env, exports, "native_view_get_padding", Js_native_view_get_padding);
  Export(env, exports, "native_view_set_visible", Js_native_view_set_visible);
  Export(env, exports, "native_view_is_visible", Js_native_view_is_visible);
  Export(env, exports, "native_view_set_enabled", Js_native_view_set_enabled);
  Export(env, exports, "native_view_is_enabled", Js_native_view_is_enabled);
  Export(env, exports, "native_view_set_background_color", Js_native_view_set_background_color);
  Export(env, exports, "native_view_get_background_color", Js_native_view_get_background_color);
  Export(env, exports, "native_view_set_tooltip", Js_native_view_set_tooltip);
  Export(env, exports, "native_view_get_tooltip", Js_native_view_get_tooltip);
  Export(env, exports, "native_view_focus", Js_native_view_focus);
  Export(env, exports, "native_view_blur", Js_native_view_blur);
  Export(env, exports, "native_view_is_focused", Js_native_view_is_focused);
  Export(env, exports, "native_view_add_listener", Js_native_view_add_listener);
  Export(env, exports, "native_view_remove_listener", Js_native_view_remove_listener);
  Export(env, exports, "native_label_create", Js_native_label_create);
  Export(env, exports, "native_label_free", Js_native_label_free);
  Export(env, exports, "native_label_set_text", Js_native_label_set_text);
  Export(env, exports, "native_label_get_text", Js_native_label_get_text);
  Export(env, exports, "native_label_set_text_color", Js_native_label_set_text_color);
  Export(env, exports, "native_label_get_text_color", Js_native_label_get_text_color);
  Export(env, exports, "native_label_set_font_size", Js_native_label_set_font_size);
  Export(env, exports, "native_label_get_font_size", Js_native_label_get_font_size);
  Export(env, exports, "native_label_set_text_alignment", Js_native_label_set_text_alignment);
  Export(env, exports, "native_label_get_text_alignment", Js_native_label_get_text_alignment);
  Export(env, exports, "native_button_create", Js_native_button_create);
  Export(env, exports, "native_button_free", Js_native_button_free);
  Export(env, exports, "native_button_set_text", Js_native_button_set_text);
  Export(env, exports, "native_button_get_text", Js_native_button_get_text);
  Export(env, exports, "native_text_field_create", Js_native_text_field_create);
  Export(env, exports, "native_text_field_free", Js_native_text_field_free);
  Export(env, exports, "native_text_field_set_text", Js_native_text_field_set_text);
  Export(env, exports, "native_text_field_get_text", Js_native_text_field_get_text);
  Export(env, exports, "native_text_field_set_text_color", Js_native_text_field_set_text_color);
  Export(env, exports, "native_text_field_get_text_color", Js_native_text_field_get_text_color);
  Export(env, exports, "native_text_field_set_font_size", Js_native_text_field_set_font_size);
  Export(env, exports, "native_text_field_get_font_size", Js_native_text_field_get_font_size);
  Export(env, exports, "native_text_field_set_text_alignment", Js_native_text_field_set_text_alignment);
  Export(env, exports, "native_text_field_get_text_alignment", Js_native_text_field_get_text_alignment);
  Export(env, exports, "native_text_field_set_placeholder", Js_native_text_field_set_placeholder);
  Export(env, exports, "native_text_field_get_placeholder", Js_native_text_field_get_placeholder);
  Export(env, exports, "native_text_field_set_editable", Js_native_text_field_set_editable);
  Export(env, exports, "native_text_field_is_editable", Js_native_text_field_is_editable);
  Export(env, exports, "native_text_field_set_secure", Js_native_text_field_set_secure);
  Export(env, exports, "native_text_field_is_secure", Js_native_text_field_is_secure);
  Export(env, exports, "native_text_field_set_multiline", Js_native_text_field_set_multiline);
  Export(env, exports, "native_text_field_is_multiline", Js_native_text_field_is_multiline);
  Export(env, exports, "native_image_view_create", Js_native_image_view_create);
  Export(env, exports, "native_image_view_free", Js_native_image_view_free);
  Export(env, exports, "native_image_view_set_image", Js_native_image_view_set_image);
  Export(env, exports, "native_image_view_get_image", Js_native_image_view_get_image);
}

}  // namespace nativeapi_js
