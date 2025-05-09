#include <string.h>
#include <iostream>

#include "libnativeapi/include/nativeapi.h"
#include "window.h"

using namespace nativeapi;

extern WindowManager g_window_manager;

Window* __window(long window_id) {
  std::shared_ptr<Window> window_ptr = g_window_manager.Get(window_id);
  if (window_ptr != nullptr) {
    return window_ptr.get();
  }
  return nullptr;
}

FFI_PLUGIN_EXPORT
void window_focus(long window_id) {
  __window(window_id)->Focus();
}

FFI_PLUGIN_EXPORT
void window_blur(long window_id) {
  __window(window_id)->Blur();
}

FFI_PLUGIN_EXPORT
bool window_is_focused(long window_id) {
  return __window(window_id)->IsFocused();
}

FFI_PLUGIN_EXPORT
void window_show(long window_id) {
  __window(window_id)->Show();
}

FFI_PLUGIN_EXPORT
void window_show_inactive(long window_id) {
  __window(window_id)->ShowInactive();
}

FFI_PLUGIN_EXPORT
void window_hide(long window_id) {
  __window(window_id)->Hide();
}

FFI_PLUGIN_EXPORT
bool window_is_visible(long window_id) {
  return __window(window_id)->IsVisible();
}

FFI_PLUGIN_EXPORT
void window_maximize(long window_id) {
  __window(window_id)->Maximize();
}

FFI_PLUGIN_EXPORT
void window_unmaximize(long window_id) {
  __window(window_id)->Unmaximize();
}

FFI_PLUGIN_EXPORT
bool window_is_maximized(long window_id) {
  return __window(window_id)->IsMaximized();
}

FFI_PLUGIN_EXPORT
void window_minimize(long window_id) {
  __window(window_id)->Minimize();
}

FFI_PLUGIN_EXPORT
void window_restore(long window_id) {
  __window(window_id)->Restore();
}

FFI_PLUGIN_EXPORT
bool window_is_minimized(long window_id) {
  return __window(window_id)->IsMinimized();
}

FFI_PLUGIN_EXPORT
void window_set_full_screen(long window_id, bool is_full_screen) {
  __window(window_id)->SetFullScreen(is_full_screen);
}

FFI_PLUGIN_EXPORT
bool window_is_full_screen(long window_id) {
  return __window(window_id)->IsFullScreen();
}

// FFI_PLUGIN_EXPORT
// void _window_set_background_color(long window_id, NativeColor color);

// FFI_PLUGIN_EXPORT
// NativeColor window_get_background_color(long window_id);

FFI_PLUGIN_EXPORT
void window_set_bounds(long window_id, struct NativeRectangle bounds) {
  __window(window_id)->SetBounds(
      {bounds.x, bounds.y, bounds.width, bounds.height});
}

FFI_PLUGIN_EXPORT
struct NativeRectangle window_get_bounds(long window_id) {
  auto bounds = __window(window_id)->GetBounds();
  return {bounds.x, bounds.y, bounds.width, bounds.height};
}

FFI_PLUGIN_EXPORT
void window_set_size(long window_id, struct NativeSize size, bool animate) {
  __window(window_id)->SetSize({size.width, size.height}, animate);
}

FFI_PLUGIN_EXPORT
struct NativeSize window_get_size(long window_id) {
  auto size = __window(window_id)->GetSize();
  return {size.width, size.height};
}

FFI_PLUGIN_EXPORT
void window_set_content_size(long window_id, struct NativeSize size) {
  __window(window_id)->SetContentSize({size.width, size.height});
}

FFI_PLUGIN_EXPORT
NativeSize window_get_content_size(long window_id) {
  auto size = __window(window_id)->GetContentSize();
  return {size.width, size.height};
}

FFI_PLUGIN_EXPORT
void window_set_minimum_size(long window_id, struct NativeSize size) {
  __window(window_id)->SetMinimumSize({size.width, size.height});
}

FFI_PLUGIN_EXPORT
struct NativeSize window_get_minimum_size(long window_id) {
  auto size = __window(window_id)->GetMinimumSize();
  return {size.width, size.height};
}

FFI_PLUGIN_EXPORT
void window_set_maximum_size(long window_id, struct NativeSize size) {
  __window(window_id)->SetMaximumSize({size.width, size.height});
}

FFI_PLUGIN_EXPORT
struct NativeSize window_get_maximum_size(long window_id) {
  auto size = __window(window_id)->GetMaximumSize();
  return {size.width, size.height};
}

FFI_PLUGIN_EXPORT
void window_set_resizable(long window_id, bool is_resizable) {
  __window(window_id)->SetResizable(is_resizable);
}

FFI_PLUGIN_EXPORT
bool window_is_resizable(long window_id) {
  return __window(window_id)->IsResizable();
}

FFI_PLUGIN_EXPORT
void window_set_movable(long window_id, bool is_movable) {
  __window(window_id)->SetMovable(is_movable);
}

FFI_PLUGIN_EXPORT
bool window_is_movable(long window_id) {
  return __window(window_id)->IsMovable();
}

FFI_PLUGIN_EXPORT
void window_set_minimizable(long window_id, bool is_minimizable) {
  __window(window_id)->SetMinimizable(is_minimizable);
}

FFI_PLUGIN_EXPORT
bool window_is_minimizable(long window_id) {
  return __window(window_id)->IsMinimizable();
}

FFI_PLUGIN_EXPORT
void window_set_maximizable(long window_id, bool is_maximizable) {
  __window(window_id)->SetMaximizable(is_maximizable);
}

FFI_PLUGIN_EXPORT
bool window_is_maximizable(long window_id) {
  return __window(window_id)->IsMaximizable();
}

FFI_PLUGIN_EXPORT
void window_set_full_screenable(long window_id, bool is_full_screenable) {
  __window(window_id)->SetFullScreenable(is_full_screenable);
}

FFI_PLUGIN_EXPORT
bool window_is_full_screenable(long window_id) {
  return __window(window_id)->IsFullScreenable();
}

FFI_PLUGIN_EXPORT
void window_set_closable(long window_id, bool is_closable) {
  __window(window_id)->SetClosable(is_closable);
}

FFI_PLUGIN_EXPORT
bool window_is_closable(long window_id) {
  return __window(window_id)->IsClosable();
}

FFI_PLUGIN_EXPORT
void window_set_always_on_top(long window_id, bool is_always_on_top) {
  __window(window_id)->SetAlwaysOnTop(is_always_on_top);
}

FFI_PLUGIN_EXPORT
bool window_is_always_on_top(long window_id) {
  return __window(window_id)->IsAlwaysOnTop();
}

FFI_PLUGIN_EXPORT
void window_set_position(long window_id, struct NativePoint point) {
  __window(window_id)->SetPosition({point.x, point.y});
}

FFI_PLUGIN_EXPORT
struct NativePoint window_get_position(long window_id) {
  auto position = __window(window_id)->GetPosition();
  return {position.x, position.y};
}

FFI_PLUGIN_EXPORT
void window_set_title(long window_id, const char* title) {
  __window(window_id)->SetTitle(title);
}

FFI_PLUGIN_EXPORT
const char* window_get_title(long window_id) {
  static std::string title_storage = __window(window_id)->GetTitle();
  return title_storage.c_str();
}

FFI_PLUGIN_EXPORT
void window_set_has_shadow(long window_id, bool has_shadow) {
  __window(window_id)->SetHasShadow(has_shadow);
}

FFI_PLUGIN_EXPORT
bool window_has_shadow(long window_id) {
  return __window(window_id)->HasShadow();
}

FFI_PLUGIN_EXPORT
void window_set_opacity(long window_id, float opacity) {
  __window(window_id)->SetOpacity(opacity);
}

FFI_PLUGIN_EXPORT
float window_get_opacity(long window_id) {
  return __window(window_id)->GetOpacity();
}

FFI_PLUGIN_EXPORT
void window_set_visible_on_all_workspaces(long window_id,
                                          bool is_visible_on_all_workspaces) {
  __window(window_id)->SetVisibleOnAllWorkspaces(is_visible_on_all_workspaces);
}

FFI_PLUGIN_EXPORT
bool window_is_visible_on_all_workspaces(long window_id) {
  return __window(window_id)->IsVisibleOnAllWorkspaces();
}

FFI_PLUGIN_EXPORT
void window_set_ignore_mouse_events(long window_id,
                                    bool is_ignore_mouse_events) {
  __window(window_id)->SetIgnoreMouseEvents(is_ignore_mouse_events);
}

FFI_PLUGIN_EXPORT
bool window_is_ignore_mouse_events(long window_id) {
  return __window(window_id)->IsIgnoreMouseEvents();
}

FFI_PLUGIN_EXPORT
void window_set_focusable(long window_id, bool is_focusable) {
  __window(window_id)->SetFocusable(is_focusable);
}

FFI_PLUGIN_EXPORT
bool window_is_focusable(long window_id) {
  return __window(window_id)->IsFocusable();
}

FFI_PLUGIN_EXPORT
void window_start_dragging(long window_id) {
  __window(window_id)->StartDragging();
}

FFI_PLUGIN_EXPORT
void window_start_resizing(long window_id) {
  __window(window_id)->StartResizing();
}

FFI_PLUGIN_EXPORT
void window_start_listening(long window_id) {
  // TODO: Implement
}

FFI_PLUGIN_EXPORT
void window_stop_listening(long window_id) {
  // TODO: Implement
}
