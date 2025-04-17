#include <string.h>
#include <iostream>

#include "libnativeapi/include/nativeapi.h"
#include "window.h"

using namespace nativeapi;

extern WindowManager g_window_manager;

FFI_PLUGIN_EXPORT
void window_focus(long window_id) {
  auto window = g_window_manager.Get(window_id);
  window.Focus();
}

FFI_PLUGIN_EXPORT
void window_blur(long window_id) {
  auto window = g_window_manager.Get(window_id);
  window.Blur();
}

FFI_PLUGIN_EXPORT
bool window_is_focused(long window_id) {
  auto window = g_window_manager.Get(window_id);
  return window.IsFocused();
}

FFI_PLUGIN_EXPORT
void window_show(long window_id) {
  auto window = g_window_manager.Get(window_id);
  window.Show();
}

FFI_PLUGIN_EXPORT
void window_hide(long window_id) {
  auto window = g_window_manager.Get(window_id);
  window.Hide();
}

FFI_PLUGIN_EXPORT
bool window_is_visible(long window_id) {
  auto window = g_window_manager.Get(window_id);
  return window.IsVisible();
}

FFI_PLUGIN_EXPORT
void window_maximize(long window_id) {
  auto window = g_window_manager.Get(window_id);
  window.Maximize();
}

FFI_PLUGIN_EXPORT
void window_unmaximize(long window_id) {
  auto window = g_window_manager.Get(window_id);
  window.Unmaximize();
}

FFI_PLUGIN_EXPORT
bool window_is_maximized(long window_id) {
  auto window = g_window_manager.Get(window_id);
  return window.IsMaximized();
}

FFI_PLUGIN_EXPORT
void window_minimize(long window_id) {
  auto window = g_window_manager.Get(window_id);
  window.Minimize();
}

FFI_PLUGIN_EXPORT
void window_restore(long window_id) {
  auto window = g_window_manager.Get(window_id);
  window.Restore();
}

FFI_PLUGIN_EXPORT
bool window_is_minimized(long window_id) {
  auto window = g_window_manager.Get(window_id);
  return window.IsMinimized();
}

FFI_PLUGIN_EXPORT
void window_set_full_screen(long window_id, bool is_full_screen) {
  auto window = g_window_manager.Get(window_id);
  window.SetFullScreen(is_full_screen);
}

FFI_PLUGIN_EXPORT
bool window_is_full_screen(long window_id) {
  auto window = g_window_manager.Get(window_id);
  return window.IsFullScreen();
}

// FFI_PLUGIN_EXPORT
// void _window_set_background_color(long window_id, NativeColor color);

// FFI_PLUGIN_EXPORT
// NativeColor window_get_background_color(long window_id);

FFI_PLUGIN_EXPORT
void window_set_bounds(long window_id, struct NativeRectangle bounds) {
  auto window = g_window_manager.Get(window_id);
  window.SetBounds({bounds.x, bounds.y, bounds.width, bounds.height});
}

FFI_PLUGIN_EXPORT
struct NativeRectangle window_get_bounds(long window_id) {
  auto window = g_window_manager.Get(window_id);
  auto bounds = window.GetBounds();
  return {bounds.x, bounds.y, bounds.width, bounds.height};
}

FFI_PLUGIN_EXPORT
void window_set_size(long window_id, struct NativeSize size) {
  auto window = g_window_manager.Get(window_id);
  window.SetSize({size.width, size.height});
}

FFI_PLUGIN_EXPORT
struct NativeSize window_get_size(long window_id) {
  auto window = g_window_manager.Get(window_id);
  auto size = window.GetSize();
  return {size.width, size.height};
}

FFI_PLUGIN_EXPORT
void window_set_content_size(long window_id, struct NativeSize size) {
  auto window = g_window_manager.Get(window_id);
  window.SetContentSize({size.width, size.height});
}

FFI_PLUGIN_EXPORT
NativeSize window_get_content_size(long window_id) {
  auto window = g_window_manager.Get(window_id);
  auto size = window.GetContentSize();
  return {size.width, size.height};
}

FFI_PLUGIN_EXPORT
void window_set_minimum_size(long window_id, struct NativeSize size) {
  auto window = g_window_manager.Get(window_id);
  window.SetMinimumSize({size.width, size.height});
}

FFI_PLUGIN_EXPORT
struct NativeSize window_get_minimum_size(long window_id) {
  auto window = g_window_manager.Get(window_id);
  auto size = window.GetMinimumSize();
  return {size.width, size.height};
}

FFI_PLUGIN_EXPORT
void window_set_maximum_size(long window_id, struct NativeSize size) {
  auto window = g_window_manager.Get(window_id);
  window.SetMaximumSize({size.width, size.height});
}

FFI_PLUGIN_EXPORT
struct NativeSize window_get_maximum_size(long window_id) {
  auto window = g_window_manager.Get(window_id);
  auto size = window.GetMaximumSize();
  return {size.width, size.height};
}

FFI_PLUGIN_EXPORT
void window_set_resizable(long window_id, bool is_resizable) {
  auto window = g_window_manager.Get(window_id);
  window.SetResizable(is_resizable);
}

FFI_PLUGIN_EXPORT
bool window_is_resizable(long window_id) {
  auto window = g_window_manager.Get(window_id);
  return window.IsResizable();
}

FFI_PLUGIN_EXPORT
void window_set_movable(long window_id, bool is_movable) {
  auto window = g_window_manager.Get(window_id);
  window.SetMovable(is_movable);
}

FFI_PLUGIN_EXPORT
bool window_is_movable(long window_id) {
  auto window = g_window_manager.Get(window_id);
  return window.IsMovable();
}

FFI_PLUGIN_EXPORT
void window_set_minimizable(long window_id, bool is_minimizable) {
  auto window = g_window_manager.Get(window_id);
  window.SetMinimizable(is_minimizable);
}

FFI_PLUGIN_EXPORT
bool window_is_minimizable(long window_id) {
  auto window = g_window_manager.Get(window_id);
  return window.IsMinimizable();
}

FFI_PLUGIN_EXPORT
void window_set_maximizable(long window_id, bool is_maximizable) {
  auto window = g_window_manager.Get(window_id);
  window.SetMaximizable(is_maximizable);
}

FFI_PLUGIN_EXPORT
bool window_is_maximizable(long window_id) {
  auto window = g_window_manager.Get(window_id);
  return window.IsMaximizable();
}

FFI_PLUGIN_EXPORT
void window_set_full_screenable(long window_id, bool is_full_screenable) {
  auto window = g_window_manager.Get(window_id);
  window.SetFullScreenable(is_full_screenable);
}

FFI_PLUGIN_EXPORT
bool window_is_full_screenable(long window_id) {
  auto window = g_window_manager.Get(window_id);
  return window.IsFullScreenable();
}

FFI_PLUGIN_EXPORT
void window_set_closable(long window_id, bool is_closable) {
  auto window = g_window_manager.Get(window_id);
  window.SetClosable(is_closable);
}

FFI_PLUGIN_EXPORT
bool window_is_closable(long window_id) {
  auto window = g_window_manager.Get(window_id);
  return window.IsClosable();
}

FFI_PLUGIN_EXPORT
void window_set_always_on_top(long window_id, bool is_always_on_top) {
  auto window = g_window_manager.Get(window_id);
  window.SetAlwaysOnTop(is_always_on_top);
}

FFI_PLUGIN_EXPORT
bool window_is_always_on_top(long window_id) {
  auto window = g_window_manager.Get(window_id);
  return window.IsAlwaysOnTop();
}

FFI_PLUGIN_EXPORT
void window_set_position(long window_id, struct NativePoint point) {
  auto window = g_window_manager.Get(window_id);
  window.SetPosition({point.x, point.y});
}

FFI_PLUGIN_EXPORT
struct NativePoint window_get_position(long window_id) {
  auto window = g_window_manager.Get(window_id);
  auto position = window.GetPosition();
  return {position.x, position.y};
}

FFI_PLUGIN_EXPORT
void window_set_title(long window_id, const char* title) {
  auto window = g_window_manager.Get(window_id);
  window.SetTitle(title);
}

FFI_PLUGIN_EXPORT
const char* window_get_title(long window_id) {
  static std::string title_storage;  // Static storage for the returned string
  auto window = g_window_manager.Get(window_id);
  title_storage = window.GetTitle();  // Store the string
  return title_storage.c_str();  // Return pointer to the stored string
}

FFI_PLUGIN_EXPORT
void window_set_has_shadow(long window_id, bool has_shadow) {
  auto window = g_window_manager.Get(window_id);
  window.SetHasShadow(has_shadow);
}

FFI_PLUGIN_EXPORT
bool window_has_shadow(long window_id) {
  auto window = g_window_manager.Get(window_id);
  return window.HasShadow();
}

FFI_PLUGIN_EXPORT
void window_set_opacity(long window_id, float opacity) {
  auto window = g_window_manager.Get(window_id);
  window.SetOpacity(opacity);
}

FFI_PLUGIN_EXPORT
float window_get_opacity(long window_id) {
  auto window = g_window_manager.Get(window_id);
  return window.GetOpacity();
}

FFI_PLUGIN_EXPORT
void window_set_focusable(long window_id, bool is_focusable) {
  auto window = g_window_manager.Get(window_id);
  window.SetFocusable(is_focusable);
}

FFI_PLUGIN_EXPORT
bool window_is_focusable(long window_id) {
  auto window = g_window_manager.Get(window_id);
  return window.IsFocusable();
}

FFI_PLUGIN_EXPORT
void window_start_dragging(long window_id) {
  auto window = g_window_manager.Get(window_id);
  window.StartDragging();
}

FFI_PLUGIN_EXPORT
void window_start_resizing(long window_id) {
  auto window = g_window_manager.Get(window_id);
  window.StartResizing();
}

FFI_PLUGIN_EXPORT
void window_start_listening(long window_id) {
  // TODO: Implement
}

FFI_PLUGIN_EXPORT
void window_stop_listening(long window_id) {
  // TODO: Implement
}
