#include <stdbool.h>

#include "point.h"
#include "rectangle.h"
#include "size.h"

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

FFI_PLUGIN_EXPORT
void window_focus(long window_id);

FFI_PLUGIN_EXPORT
void window_blur(long window_id);

FFI_PLUGIN_EXPORT
bool window_is_focused(long window_id);

FFI_PLUGIN_EXPORT
void window_show(long window_id);

FFI_PLUGIN_EXPORT
void window_show_inactive(long window_id);
FFI_PLUGIN_EXPORT
void window_hide(long window_id);

FFI_PLUGIN_EXPORT
bool window_is_visible(long window_id);

FFI_PLUGIN_EXPORT
void window_maximize(long window_id);

FFI_PLUGIN_EXPORT
void window_unmaximize(long window_id);

FFI_PLUGIN_EXPORT
bool window_is_maximized(long window_id);

FFI_PLUGIN_EXPORT
void window_minimize(long window_id);

FFI_PLUGIN_EXPORT
void window_restore(long window_id);

FFI_PLUGIN_EXPORT
bool window_is_minimized(long window_id);

FFI_PLUGIN_EXPORT
void window_set_full_screen(long window_id, bool is_full_screen);

FFI_PLUGIN_EXPORT
bool window_is_full_screen(long window_id);

// FFI_PLUGIN_EXPORT
// void _window_set_background_color(long window_id, NativeColor color);

// FFI_PLUGIN_EXPORT
// NativeColor window_get_background_color(long window_id);

FFI_PLUGIN_EXPORT
void window_set_bounds(long window_id, struct NativeRectangle bounds);

FFI_PLUGIN_EXPORT
struct NativeRectangle window_get_bounds(long window_id);

FFI_PLUGIN_EXPORT
void window_set_size(long window_id, struct NativeSize size, bool animate);

FFI_PLUGIN_EXPORT
struct NativeSize window_get_size(long window_id);

FFI_PLUGIN_EXPORT
void window_set_content_size(long window_id, struct NativeSize size);

FFI_PLUGIN_EXPORT
struct NativeSize window_get_content_size(long window_id);

FFI_PLUGIN_EXPORT
void window_set_minimum_size(long window_id, struct NativeSize size);

FFI_PLUGIN_EXPORT
struct NativeSize window_get_minimum_size(long window_id);

FFI_PLUGIN_EXPORT
void window_set_maximum_size(long window_id, struct NativeSize size);

FFI_PLUGIN_EXPORT
struct NativeSize window_get_maximum_size(long window_id);

FFI_PLUGIN_EXPORT
void window_set_resizable(long window_id, bool is_resizable);

FFI_PLUGIN_EXPORT
bool window_is_resizable(long window_id);

FFI_PLUGIN_EXPORT
void window_set_movable(long window_id, bool is_movable);

FFI_PLUGIN_EXPORT
bool window_is_movable(long window_id);

FFI_PLUGIN_EXPORT
void window_set_minimizable(long window_id, bool is_minimizable);

FFI_PLUGIN_EXPORT
bool window_is_minimizable(long window_id);

FFI_PLUGIN_EXPORT
void window_set_maximizable(long window_id, bool is_maximizable);

FFI_PLUGIN_EXPORT
bool window_is_maximizable(long window_id);

FFI_PLUGIN_EXPORT
void window_set_full_screenable(long window_id, bool is_full_screenable);

FFI_PLUGIN_EXPORT
bool window_is_full_screenable(long window_id);

FFI_PLUGIN_EXPORT
void window_set_closable(long window_id, bool is_closable);

FFI_PLUGIN_EXPORT
bool window_is_closable(long window_id);

FFI_PLUGIN_EXPORT
void window_set_always_on_top(long window_id, bool is_always_on_top);

FFI_PLUGIN_EXPORT
bool window_is_always_on_top(long window_id);

FFI_PLUGIN_EXPORT
void window_set_position(long window_id, struct NativePoint point);

FFI_PLUGIN_EXPORT
struct NativePoint window_get_position(long window_id);

FFI_PLUGIN_EXPORT
void window_set_title(long window_id, const char* title);

FFI_PLUGIN_EXPORT
const char* window_get_title(long window_id);

FFI_PLUGIN_EXPORT
void window_set_has_shadow(long window_id, bool has_shadow);

FFI_PLUGIN_EXPORT
bool window_has_shadow(long window_id);

FFI_PLUGIN_EXPORT
void window_set_opacity(long window_id, float opacity);

FFI_PLUGIN_EXPORT
float window_get_opacity(long window_id);

FFI_PLUGIN_EXPORT
void window_set_visible_on_all_workspaces(long window_id,
                                          bool is_visible_on_all_workspaces);

FFI_PLUGIN_EXPORT
bool window_is_visible_on_all_workspaces(long window_id);

FFI_PLUGIN_EXPORT
void window_set_ignore_mouse_events(long window_id,
                                    bool is_ignore_mouse_events);

FFI_PLUGIN_EXPORT
bool window_is_ignore_mouse_events(long window_id);

FFI_PLUGIN_EXPORT
void window_set_focusable(long window_id, bool is_focusable);

FFI_PLUGIN_EXPORT
bool window_is_focusable(long window_id);

FFI_PLUGIN_EXPORT
void window_start_dragging(long window_id);

FFI_PLUGIN_EXPORT
void window_start_resizing(long window_id);

FFI_PLUGIN_EXPORT
void window_start_listening(long window_id);

FFI_PLUGIN_EXPORT
void window_stop_listening(long window_id);

#ifdef __cplusplus
}
#endif
