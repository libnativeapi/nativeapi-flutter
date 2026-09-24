// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#include "types.h"

namespace nativeapi_js {
namespace {

napi_value Js_native_color_from_rgba(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  unsigned char p0 = {};
  if (!GetNumber(env, args[0], &p0)) {
    return nullptr;
  }
  unsigned char p1 = {};
  if (!GetNumber(env, args[1], &p1)) {
    return nullptr;
  }
  unsigned char p2 = {};
  if (!GetNumber(env, args[2], &p2)) {
    return nullptr;
  }
  unsigned char p3 = {};
  if (!GetNumber(env, args[3], &p3)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_color_from_rgba(p0, p1, p2, p3); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_color_from_hex(napi_env env, napi_callback_info info) {
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
  auto result = OnMainThread([&] { return native_color_from_hex(p0); });
  Value value = ToValue(result);
  return value.ToJs(env);
}

napi_value Js_native_color_to_rgba(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  native_color_t self = {};
  if (!FromJs(env, args[0], &self, arena)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_color_to_rgba(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

napi_value Js_native_color_to_argb(napi_env env, napi_callback_info info) {
  Args args(env, info);
  if (!args.ok()) {
    return nullptr;
  }
  Arena arena;
  (void)arena;
  native_color_t self = {};
  if (!FromJs(env, args[0], &self, arena)) {
    return nullptr;
  }
  auto result = OnMainThread([&] { return native_color_to_argb(self); });
  return Value::Number(static_cast<double>(result)).ToJs(env);
}

}  // namespace

void RegisterColor(napi_env env, napi_value exports) {
  ExportValue(env, exports, "NATIVE_COLOR_TRANSPARENT", ToValue(NATIVE_COLOR_TRANSPARENT));
  ExportValue(env, exports, "NATIVE_COLOR_BLACK", ToValue(NATIVE_COLOR_BLACK));
  ExportValue(env, exports, "NATIVE_COLOR_WHITE", ToValue(NATIVE_COLOR_WHITE));
  ExportValue(env, exports, "NATIVE_COLOR_RED", ToValue(NATIVE_COLOR_RED));
  ExportValue(env, exports, "NATIVE_COLOR_GREEN", ToValue(NATIVE_COLOR_GREEN));
  ExportValue(env, exports, "NATIVE_COLOR_BLUE", ToValue(NATIVE_COLOR_BLUE));
  ExportValue(env, exports, "NATIVE_COLOR_YELLOW", ToValue(NATIVE_COLOR_YELLOW));
  ExportValue(env, exports, "NATIVE_COLOR_CYAN", ToValue(NATIVE_COLOR_CYAN));
  ExportValue(env, exports, "NATIVE_COLOR_MAGENTA", ToValue(NATIVE_COLOR_MAGENTA));
  Export(env, exports, "native_color_from_rgba", Js_native_color_from_rgba);
  Export(env, exports, "native_color_from_hex", Js_native_color_from_hex);
  Export(env, exports, "native_color_to_rgba", Js_native_color_to_rgba);
  Export(env, exports, "native_color_to_argb", Js_native_color_to_argb);
}

}  // namespace nativeapi_js
