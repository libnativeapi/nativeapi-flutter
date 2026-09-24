// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#pragma once

#include "../napi_support.h"

#include "capi/geometry_c.h"
#include "capi/color_c.h"
#include "capi/keyboard_c.h"
#include "capi/placement_c.h"
#include "capi/dialog_c.h"
#include "capi/accessibility_manager_c.h"
#include "capi/display_c.h"
#include "capi/display_manager_c.h"
#include "capi/url_opener_c.h"
#include "capi/app_info_c.h"
#include "capi/device_info_c.h"
#include "capi/preferences_c.h"
#include "capi/secure_storage_c.h"
#include "capi/launch_at_login_c.h"
#include "capi/message_dialog_c.h"
#include "capi/file_dialog_c.h"
#include "capi/notification_manager_c.h"
#include "capi/image_c.h"
#include "capi/window_shape_c.h"
#include "capi/window_shadow_c.h"
#include "capi/window_c.h"
#include "capi/window_manager_c.h"
#include "capi/window_drag_session_c.h"
#include "capi/drag_source_c.h"
#include "capi/drop_target_c.h"
#include "capi/positioning_strategy_c.h"
#include "capi/menu_c.h"
#include "capi/tray_icon_c.h"
#include "capi/tray_manager_c.h"
#include "capi/shortcut_c.h"
#include "capi/shortcut_manager_c.h"
#include "capi/keyboard_monitor_c.h"
#include "capi/application_c.h"

namespace nativeapi_js {

inline Value ToValue(const native_point_t& value);
inline bool FromJs(napi_env env, napi_value value, native_point_t* out, Arena& arena);
inline Value ToValue(const native_size_t& value);
inline bool FromJs(napi_env env, napi_value value, native_size_t* out, Arena& arena);
inline Value ToValue(const native_rectangle_t& value);
inline bool FromJs(napi_env env, napi_value value, native_rectangle_t* out, Arena& arena);
inline Value ToValue(const native_color_t& value);
inline bool FromJs(napi_env env, napi_value value, native_color_t* out, Arena& arena);
inline Value ToValue(const native_keyboard_accelerator_t& value);
inline bool FromJs(napi_env env, napi_value value, native_keyboard_accelerator_t* out, Arena& arena);
inline Value ToValue(const native_keyboard_event_t& event);
inline Value ToValue(const native_display_event_t& event);
inline Value ToValue(const native_url_open_result_t& value);
inline bool FromJs(napi_env env, napi_value value, native_url_open_result_t* out, Arena& arena);
inline Value ToValue(const native_notification_event_t& event);
inline Value ToValue(const native_window_event_t& event);
inline Value ToValue(const native_window_drag_event_t& event);
inline Value ToValue(const native_drag_source_event_t& event);
inline Value ToValue(const native_drop_target_event_t& event);
inline Value ToValue(const native_menu_event_t& event);
inline Value ToValue(const native_tray_icon_event_t& event);
inline Value ToValue(const native_shortcut_options_t& value);
inline bool FromJs(napi_env env, napi_value value, native_shortcut_options_t* out, Arena& arena);
inline Value ToValue(const native_shortcut_event_t& event);
inline Value ToValue(const native_application_event_t& event);

inline Value ToValue(const native_point_t& value) {
  Value result = Value::Object();
  result.Set("x", Value::Number(static_cast<double>(value.x)));
  result.Set("y", Value::Number(static_cast<double>(value.y)));
  return result;
}

inline bool FromJs(napi_env env, napi_value value, native_point_t* out, Arena& arena) {
  if (!ExpectObject(env, value, "Point")) {
    return false;
  }
  napi_value field = nullptr;
  if (!GetField(env, value, "x", &field)) {
    return false;
  }
  if (field != nullptr) {
    if (!GetNumber(env, field, &out->x)) {
      return false;
    }
  }
  if (!GetField(env, value, "y", &field)) {
    return false;
  }
  if (field != nullptr) {
    if (!GetNumber(env, field, &out->y)) {
      return false;
    }
  }
  return true;
}

inline Value ToValue(const native_size_t& value) {
  Value result = Value::Object();
  result.Set("width", Value::Number(static_cast<double>(value.width)));
  result.Set("height", Value::Number(static_cast<double>(value.height)));
  return result;
}

inline bool FromJs(napi_env env, napi_value value, native_size_t* out, Arena& arena) {
  if (!ExpectObject(env, value, "Size")) {
    return false;
  }
  napi_value field = nullptr;
  if (!GetField(env, value, "width", &field)) {
    return false;
  }
  if (field != nullptr) {
    if (!GetNumber(env, field, &out->width)) {
      return false;
    }
  }
  if (!GetField(env, value, "height", &field)) {
    return false;
  }
  if (field != nullptr) {
    if (!GetNumber(env, field, &out->height)) {
      return false;
    }
  }
  return true;
}

inline Value ToValue(const native_rectangle_t& value) {
  Value result = Value::Object();
  result.Set("x", Value::Number(static_cast<double>(value.x)));
  result.Set("y", Value::Number(static_cast<double>(value.y)));
  result.Set("width", Value::Number(static_cast<double>(value.width)));
  result.Set("height", Value::Number(static_cast<double>(value.height)));
  return result;
}

inline bool FromJs(napi_env env, napi_value value, native_rectangle_t* out, Arena& arena) {
  if (!ExpectObject(env, value, "Rectangle")) {
    return false;
  }
  napi_value field = nullptr;
  if (!GetField(env, value, "x", &field)) {
    return false;
  }
  if (field != nullptr) {
    if (!GetNumber(env, field, &out->x)) {
      return false;
    }
  }
  if (!GetField(env, value, "y", &field)) {
    return false;
  }
  if (field != nullptr) {
    if (!GetNumber(env, field, &out->y)) {
      return false;
    }
  }
  if (!GetField(env, value, "width", &field)) {
    return false;
  }
  if (field != nullptr) {
    if (!GetNumber(env, field, &out->width)) {
      return false;
    }
  }
  if (!GetField(env, value, "height", &field)) {
    return false;
  }
  if (field != nullptr) {
    if (!GetNumber(env, field, &out->height)) {
      return false;
    }
  }
  return true;
}

inline Value ToValue(const native_color_t& value) {
  Value result = Value::Object();
  result.Set("r", Value::Number(static_cast<double>(value.r)));
  result.Set("g", Value::Number(static_cast<double>(value.g)));
  result.Set("b", Value::Number(static_cast<double>(value.b)));
  result.Set("a", Value::Number(static_cast<double>(value.a)));
  return result;
}

inline bool FromJs(napi_env env, napi_value value, native_color_t* out, Arena& arena) {
  if (!ExpectObject(env, value, "Color")) {
    return false;
  }
  napi_value field = nullptr;
  if (!GetField(env, value, "r", &field)) {
    return false;
  }
  if (field != nullptr) {
    if (!GetNumber(env, field, &out->r)) {
      return false;
    }
  }
  if (!GetField(env, value, "g", &field)) {
    return false;
  }
  if (field != nullptr) {
    if (!GetNumber(env, field, &out->g)) {
      return false;
    }
  }
  if (!GetField(env, value, "b", &field)) {
    return false;
  }
  if (field != nullptr) {
    if (!GetNumber(env, field, &out->b)) {
      return false;
    }
  }
  if (!GetField(env, value, "a", &field)) {
    return false;
  }
  if (field != nullptr) {
    if (!GetNumber(env, field, &out->a)) {
      return false;
    }
  }
  return true;
}

inline Value ToValue(const native_keyboard_accelerator_t& value) {
  Value result = Value::Object();
  result.Set("modifiers", Value::Number(static_cast<double>(value.modifiers)));
  result.Set("key", Value::String(value.key));
  return result;
}

inline bool FromJs(napi_env env, napi_value value, native_keyboard_accelerator_t* out, Arena& arena) {
  if (!ExpectObject(env, value, "KeyboardAccelerator")) {
    return false;
  }
  napi_value field = nullptr;
  if (!GetField(env, value, "modifiers", &field)) {
    return false;
  }
  if (field != nullptr) {
    if (!GetNumber(env, field, &out->modifiers)) {
      return false;
    }
  }
  if (!GetField(env, value, "key", &field)) {
    return false;
  }
  if (field != nullptr) {
    if (!GetString(env, field, arena, &out->key)) {
      return false;
    }
  }
  return true;
}

inline Value ToValue(const native_keyboard_event_t& event) {
  Value result = Value::Object();
  switch (event.type) {
    case NATIVE_KEYBOARD_EVENT_TYPE_KEY_PRESSED:
      result.Set("type", Value::String("keyPressed"));
      break;
    case NATIVE_KEYBOARD_EVENT_TYPE_KEY_RELEASED:
      result.Set("type", Value::String("keyReleased"));
      break;
    case NATIVE_KEYBOARD_EVENT_TYPE_MODIFIER_KEYS_CHANGED:
      result.Set("type", Value::String("modifierKeysChanged"));
      result.Set("modifierKeys", Value::Number(static_cast<double>(event.data.modifier_keys_changed.modifier_keys)));
      break;
    default:
      return Value::Null();
  }
  result.Set("keycode", Value::Number(static_cast<double>(event.keycode)));
  return result;
}

inline Value ToValue(const native_display_event_t& event) {
  Value result = Value::Object();
  switch (event.type) {
    case NATIVE_DISPLAY_EVENT_TYPE_ADDED:
      result.Set("type", Value::String("added"));
      break;
    case NATIVE_DISPLAY_EVENT_TYPE_REMOVED:
      result.Set("type", Value::String("removed"));
      break;
    case NATIVE_DISPLAY_EVENT_TYPE_CHANGED:
      result.Set("type", Value::String("changed"));
      break;
    default:
      return Value::Null();
  }
  result.Set("display", Value::BigInt(event.display));
  return result;
}

inline Value ToValue(const native_url_open_result_t& value) {
  Value result = Value::Object();
  result.Set("success", Value::Bool(value.success));
  result.Set("errorCode", Value::Number(static_cast<double>(value.error_code)));
  result.Set("errorMessage", Value::String(value.error_message));
  return result;
}

inline bool FromJs(napi_env env, napi_value value, native_url_open_result_t* out, Arena& arena) {
  if (!ExpectObject(env, value, "UrlOpenResult")) {
    return false;
  }
  napi_value field = nullptr;
  if (!GetField(env, value, "success", &field)) {
    return false;
  }
  if (field != nullptr) {
    if (!GetBool(env, field, &out->success)) {
      return false;
    }
  }
  if (!GetField(env, value, "errorCode", &field)) {
    return false;
  }
  if (field != nullptr) {
    if (!GetNumber(env, field, &out->error_code)) {
      return false;
    }
  }
  if (!GetField(env, value, "errorMessage", &field)) {
    return false;
  }
  if (field != nullptr) {
    if (!GetString(env, field, arena, &out->error_message)) {
      return false;
    }
  }
  return true;
}

inline Value ToValue(const native_notification_event_t& event) {
  Value result = Value::Object();
  switch (event.type) {
    case NATIVE_NOTIFICATION_EVENT_TYPE_ACTIVATED:
      result.Set("type", Value::String("activated"));
      result.Set("argument", Value::String(event.data.activated.argument));
      break;
    default:
      return Value::Null();
  }
  return result;
}

inline Value ToValue(const native_window_event_t& event) {
  Value result = Value::Object();
  switch (event.type) {
    case NATIVE_WINDOW_EVENT_TYPE_FOCUSED:
      result.Set("type", Value::String("focused"));
      break;
    case NATIVE_WINDOW_EVENT_TYPE_BLURRED:
      result.Set("type", Value::String("blurred"));
      break;
    case NATIVE_WINDOW_EVENT_TYPE_MINIMIZED:
      result.Set("type", Value::String("minimized"));
      break;
    case NATIVE_WINDOW_EVENT_TYPE_MAXIMIZED:
      result.Set("type", Value::String("maximized"));
      break;
    case NATIVE_WINDOW_EVENT_TYPE_RESTORED:
      result.Set("type", Value::String("restored"));
      break;
    case NATIVE_WINDOW_EVENT_TYPE_MOVED:
      result.Set("type", Value::String("moved"));
      result.Set("newPosition", ToValue(event.data.moved.new_position));
      break;
    case NATIVE_WINDOW_EVENT_TYPE_RESIZED:
      result.Set("type", Value::String("resized"));
      result.Set("newSize", ToValue(event.data.resized.new_size));
      break;
    case NATIVE_WINDOW_EVENT_TYPE_CREATED:
      result.Set("type", Value::String("created"));
      break;
    case NATIVE_WINDOW_EVENT_TYPE_CLOSED:
      result.Set("type", Value::String("closed"));
      break;
    default:
      return Value::Null();
  }
  result.Set("windowId", Value::Number(static_cast<double>(event.window_id)));
  return result;
}

inline Value ToValue(const native_window_drag_event_t& event) {
  Value result = Value::Object();
  switch (event.type) {
    case NATIVE_WINDOW_DRAG_EVENT_TYPE_MOVED:
      result.Set("type", Value::String("moved"));
      break;
    case NATIVE_WINDOW_DRAG_EVENT_TYPE_ENDED:
      result.Set("type", Value::String("ended"));
      break;
    case NATIVE_WINDOW_DRAG_EVENT_TYPE_CANCELLED:
      result.Set("type", Value::String("cancelled"));
      break;
    default:
      return Value::Null();
  }
  result.Set("windowId", Value::Number(static_cast<double>(event.window_id)));
  result.Set("cursorPosition", ToValue(event.cursor_position));
  return result;
}

inline Value ToValue(const native_drag_source_event_t& event) {
  Value result = Value::Object();
  switch (event.type) {
    case NATIVE_DRAG_SOURCE_EVENT_TYPE_ENDED:
      result.Set("type", Value::String("ended"));
      result.Set("operation", Value::Number(static_cast<double>(event.data.ended.operation)));
      break;
    default:
      return Value::Null();
  }
  result.Set("windowId", Value::Number(static_cast<double>(event.window_id)));
  result.Set("position", ToValue(event.position));
  return result;
}

inline Value ToValue(const native_drop_target_event_t& event) {
  Value result = Value::Object();
  switch (event.type) {
    case NATIVE_DROP_TARGET_EVENT_TYPE_ENTERED:
      result.Set("type", Value::String("entered"));
      break;
    case NATIVE_DROP_TARGET_EVENT_TYPE_MOVED:
      result.Set("type", Value::String("moved"));
      break;
    case NATIVE_DROP_TARGET_EVENT_TYPE_EXITED:
      result.Set("type", Value::String("exited"));
      break;
    case NATIVE_DROP_TARGET_EVENT_TYPE_DROPPED:
      result.Set("type", Value::String("dropped"));
      result.Set("filePaths", CopyStringList(event.data.dropped.file_paths));
      result.Set("text", Value::String(event.data.dropped.text));
      break;
    default:
      return Value::Null();
  }
  result.Set("windowId", Value::Number(static_cast<double>(event.window_id)));
  result.Set("position", ToValue(event.position));
  return result;
}

inline Value ToValue(const native_menu_event_t& event) {
  Value result = Value::Object();
  switch (event.type) {
    case NATIVE_MENU_EVENT_TYPE_OPENED:
      result.Set("type", Value::String("opened"));
      result.Set("menuId", Value::Number(static_cast<double>(event.data.opened.menu_id)));
      break;
    case NATIVE_MENU_EVENT_TYPE_CLOSED:
      result.Set("type", Value::String("closed"));
      result.Set("menuId", Value::Number(static_cast<double>(event.data.closed.menu_id)));
      break;
    case NATIVE_MENU_EVENT_TYPE_ITEM_CLICKED:
      result.Set("type", Value::String("itemClicked"));
      result.Set("itemId", Value::Number(static_cast<double>(event.data.item_clicked.item_id)));
      break;
    case NATIVE_MENU_EVENT_TYPE_ITEM_SUBMENU_OPENED:
      result.Set("type", Value::String("itemSubmenuOpened"));
      result.Set("itemId", Value::Number(static_cast<double>(event.data.item_submenu_opened.item_id)));
      break;
    case NATIVE_MENU_EVENT_TYPE_ITEM_SUBMENU_CLOSED:
      result.Set("type", Value::String("itemSubmenuClosed"));
      result.Set("itemId", Value::Number(static_cast<double>(event.data.item_submenu_closed.item_id)));
      break;
    default:
      return Value::Null();
  }
  return result;
}

inline Value ToValue(const native_tray_icon_event_t& event) {
  Value result = Value::Object();
  switch (event.type) {
    case NATIVE_TRAY_ICON_EVENT_TYPE_CLICKED:
      result.Set("type", Value::String("clicked"));
      result.Set("trayIconId", Value::Number(static_cast<double>(event.data.clicked.tray_icon_id)));
      break;
    case NATIVE_TRAY_ICON_EVENT_TYPE_RIGHT_CLICKED:
      result.Set("type", Value::String("rightClicked"));
      result.Set("trayIconId", Value::Number(static_cast<double>(event.data.right_clicked.tray_icon_id)));
      break;
    case NATIVE_TRAY_ICON_EVENT_TYPE_DOUBLE_CLICKED:
      result.Set("type", Value::String("doubleClicked"));
      result.Set("trayIconId", Value::Number(static_cast<double>(event.data.double_clicked.tray_icon_id)));
      break;
    default:
      return Value::Null();
  }
  return result;
}

inline Value ToValue(const native_shortcut_options_t& value) {
  Value result = Value::Object();
  result.Set("accelerator", Value::String(value.accelerator));
  result.Set("description", Value::String(value.description));
  result.Set("scope", Value::Number(static_cast<double>(value.scope)));
  result.Set("enabled", Value::Bool(value.enabled));
  return result;
}

inline bool FromJs(napi_env env, napi_value value, native_shortcut_options_t* out, Arena& arena) {
  if (!ExpectObject(env, value, "ShortcutOptions")) {
    return false;
  }
  napi_value field = nullptr;
  if (!GetField(env, value, "accelerator", &field)) {
    return false;
  }
  if (field != nullptr) {
    if (!GetString(env, field, arena, &out->accelerator)) {
      return false;
    }
  }
  if (!GetField(env, value, "callback", &field)) {
    return false;
  }
  if (field != nullptr) {
    Callback* callback = nullptr;
    if (!GetCallback(env, field, /*optional=*/true, &callback)) {
      return false;
    }
    out->callback = callback ? +[](void* user_data) { Callback::Dispatch(user_data, {}); } : nullptr;
    out->callback_user_data = callback;
  }
  if (!GetField(env, value, "description", &field)) {
    return false;
  }
  if (field != nullptr) {
    if (!GetString(env, field, arena, &out->description)) {
      return false;
    }
  }
  if (!GetField(env, value, "scope", &field)) {
    return false;
  }
  if (field != nullptr) {
    if (!GetNumber(env, field, &out->scope)) {
      return false;
    }
  }
  if (!GetField(env, value, "enabled", &field)) {
    return false;
  }
  if (field != nullptr) {
    if (!GetBool(env, field, &out->enabled)) {
      return false;
    }
  }
  return true;
}

inline Value ToValue(const native_shortcut_event_t& event) {
  Value result = Value::Object();
  switch (event.type) {
    case NATIVE_SHORTCUT_EVENT_TYPE_ACTIVATED:
      result.Set("type", Value::String("activated"));
      break;
    case NATIVE_SHORTCUT_EVENT_TYPE_REGISTERED:
      result.Set("type", Value::String("registered"));
      break;
    case NATIVE_SHORTCUT_EVENT_TYPE_UNREGISTERED:
      result.Set("type", Value::String("unregistered"));
      break;
    case NATIVE_SHORTCUT_EVENT_TYPE_REGISTRATION_FAILED:
      result.Set("type", Value::String("registrationFailed"));
      result.Set("errorMessage", Value::String(event.data.registration_failed.error_message));
      break;
    default:
      return Value::Null();
  }
  result.Set("shortcutId", Value::Number(static_cast<double>(event.shortcut_id)));
  result.Set("accelerator", Value::String(event.accelerator));
  return result;
}

inline Value ToValue(const native_application_event_t& event) {
  Value result = Value::Object();
  switch (event.type) {
    case NATIVE_APPLICATION_EVENT_TYPE_STARTED:
      result.Set("type", Value::String("started"));
      break;
    case NATIVE_APPLICATION_EVENT_TYPE_EXITING:
      result.Set("type", Value::String("exiting"));
      result.Set("exitCode", Value::Number(static_cast<double>(event.data.exiting.exit_code)));
      break;
    case NATIVE_APPLICATION_EVENT_TYPE_ACTIVATED:
      result.Set("type", Value::String("activated"));
      break;
    case NATIVE_APPLICATION_EVENT_TYPE_DEACTIVATED:
      result.Set("type", Value::String("deactivated"));
      break;
    case NATIVE_APPLICATION_EVENT_TYPE_QUIT_REQUESTED:
      result.Set("type", Value::String("quitRequested"));
      break;
    default:
      return Value::Null();
  }
  return result;
}

}  // namespace nativeapi_js
