// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#pragma once

#include <stdbool.h>
#include <stdint.h>

#include "common_c.h"
#include "color_c.h"
#include "geometry_c.h"

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef unsigned int native_window_id_t;

typedef enum {
  NATIVE_TITLE_BAR_STYLE_NORMAL = 0,
  NATIVE_TITLE_BAR_STYLE_HIDDEN = 1,
} native_title_bar_style_t;

typedef enum {
  NATIVE_VISUAL_EFFECT_NONE = 0,
  NATIVE_VISUAL_EFFECT_BLUR = 1,
  NATIVE_VISUAL_EFFECT_ACRYLIC = 2,
  NATIVE_VISUAL_EFFECT_MICA = 3,
} native_visual_effect_t;

/// Opaque Window handle.
///
/// A generational index into the library's handle table, NOT a pointer:
/// never dereference it, and compare it against NATIVE_INVALID_WINDOW rather than NULL.
/// Releasing a handle invalidates it; later calls fail safely instead of
/// touching freed memory.
typedef uint64_t native_window_t;

/// Never refers to a live Window.
#define NATIVE_INVALID_WINDOW ((native_window_t)0)

/// Owning list of Window handles.
typedef struct {
  native_window_t* windows;
  long count;
} native_window_list_t;

/// Which concrete WindowEvent arrived.
typedef enum {
  NATIVE_WINDOW_EVENT_TYPE_FOCUSED = 0,
  NATIVE_WINDOW_EVENT_TYPE_BLURRED = 1,
  NATIVE_WINDOW_EVENT_TYPE_MINIMIZED = 2,
  NATIVE_WINDOW_EVENT_TYPE_MAXIMIZED = 3,
  NATIVE_WINDOW_EVENT_TYPE_RESTORED = 4,
  NATIVE_WINDOW_EVENT_TYPE_MOVED = 5,
  NATIVE_WINDOW_EVENT_TYPE_RESIZED = 6,
} native_window_event_type_t;

/// One WindowEvent, tagged by its concrete type.
///
/// Valid only for the duration of the callback: anything it points at
/// is released as soon as the callback returns. Copy what you need.
typedef struct {
  native_window_event_type_t type;
  native_window_id_t window_id;
  union {
    struct {
      native_point_t new_position;
    } moved;
    struct {
      native_size_t new_size;
    } resized;
  } data;
} native_window_event_t;

typedef void (*native_window_event_callback_t)(const native_window_event_t* event, void* user_data);

/// Creates a Window instance; release it with native_window_free().
FFI_PLUGIN_EXPORT
native_window_t native_window_create(void);

/// Creates a Window instance; release it with native_window_free().
FFI_PLUGIN_EXPORT
native_window_t native_window_create_with_native_window(void* native_window);

FFI_PLUGIN_EXPORT
native_window_id_t native_window_get_id(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_focus(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_blur(native_window_t window);

FFI_PLUGIN_EXPORT
bool native_window_is_focused(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_show(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_show_inactive(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_hide(native_window_t window);

FFI_PLUGIN_EXPORT
bool native_window_is_visible(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_maximize(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_unmaximize(native_window_t window);

FFI_PLUGIN_EXPORT
bool native_window_is_maximized(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_minimize(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_restore(native_window_t window);

FFI_PLUGIN_EXPORT
bool native_window_is_minimized(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_set_full_screen(native_window_t window, bool is_full_screen);

FFI_PLUGIN_EXPORT
bool native_window_is_full_screen(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_set_bounds(native_window_t window, native_rectangle_t bounds);

FFI_PLUGIN_EXPORT
native_rectangle_t native_window_get_bounds(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_set_content_bounds(native_window_t window, native_rectangle_t bounds);

FFI_PLUGIN_EXPORT
native_rectangle_t native_window_get_content_bounds(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_set_size(native_window_t window, native_size_t size, bool animate);

FFI_PLUGIN_EXPORT
native_size_t native_window_get_size(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_set_content_size(native_window_t window, native_size_t size);

FFI_PLUGIN_EXPORT
native_size_t native_window_get_content_size(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_set_minimum_size(native_window_t window, native_size_t size);

FFI_PLUGIN_EXPORT
native_size_t native_window_get_minimum_size(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_set_maximum_size(native_window_t window, native_size_t size);

FFI_PLUGIN_EXPORT
native_size_t native_window_get_maximum_size(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_set_resizable(native_window_t window, bool is_resizable);

FFI_PLUGIN_EXPORT
bool native_window_is_resizable(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_set_movable(native_window_t window, bool is_movable);

FFI_PLUGIN_EXPORT
bool native_window_is_movable(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_set_minimizable(native_window_t window, bool is_minimizable);

FFI_PLUGIN_EXPORT
bool native_window_is_minimizable(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_set_maximizable(native_window_t window, bool is_maximizable);

FFI_PLUGIN_EXPORT
bool native_window_is_maximizable(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_set_full_screenable(native_window_t window, bool is_full_screenable);

FFI_PLUGIN_EXPORT
bool native_window_is_full_screenable(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_set_closable(native_window_t window, bool is_closable);

FFI_PLUGIN_EXPORT
bool native_window_is_closable(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_set_window_control_buttons_visible(native_window_t window, bool is_visible);

FFI_PLUGIN_EXPORT
bool native_window_is_window_control_buttons_visible(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_set_always_on_top(native_window_t window, bool is_always_on_top);

FFI_PLUGIN_EXPORT
bool native_window_is_always_on_top(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_set_position(native_window_t window, native_point_t point);

FFI_PLUGIN_EXPORT
native_point_t native_window_get_position(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_center(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_set_title(native_window_t window, const char* title);

/// Caller owns the returned string; free it with free_c_str().
FFI_PLUGIN_EXPORT
char* native_window_get_title(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_set_title_bar_style(native_window_t window, native_title_bar_style_t style);

FFI_PLUGIN_EXPORT
native_title_bar_style_t native_window_get_title_bar_style(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_set_has_shadow(native_window_t window, bool has_shadow);

FFI_PLUGIN_EXPORT
bool native_window_has_shadow(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_set_opacity(native_window_t window, float opacity);

FFI_PLUGIN_EXPORT
float native_window_get_opacity(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_set_visual_effect(native_window_t window, native_visual_effect_t effect);

FFI_PLUGIN_EXPORT
native_visual_effect_t native_window_get_visual_effect(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_set_background_color(native_window_t window, native_color_t color);

FFI_PLUGIN_EXPORT
native_color_t native_window_get_background_color(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_set_visible_on_all_workspaces(native_window_t window, bool is_visible_on_all_workspaces);

FFI_PLUGIN_EXPORT
bool native_window_is_visible_on_all_workspaces(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_set_ignore_mouse_events(native_window_t window, bool is_ignore_mouse_events);

FFI_PLUGIN_EXPORT
bool native_window_is_ignore_mouse_events(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_set_focusable(native_window_t window, bool is_focusable);

FFI_PLUGIN_EXPORT
bool native_window_is_focusable(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_start_dragging(native_window_t window);

FFI_PLUGIN_EXPORT
void native_window_start_resizing(native_window_t window);

/// Platform-specific native object (NSScreen*, HMONITOR, ...).
FFI_PLUGIN_EXPORT
void* native_window_get_native_object(native_window_t window);

/// Releases the caller's reference. Safe to call with an invalid or
/// already-released handle.
FFI_PLUGIN_EXPORT
void native_window_free(native_window_t window);

/// Frees the array and releases every handle it contains.
FFI_PLUGIN_EXPORT
void native_window_list_free(native_window_list_t* list);

/// Frees only the array; the caller takes over the handles.
FFI_PLUGIN_EXPORT
void native_window_list_release(native_window_list_t* list);

#ifdef __cplusplus
}
#endif

#ifdef __cplusplus
namespace nativeapi {
class WindowEvent;
}  // namespace nativeapi

/// Fills @p out from @p event. Returns false when the event is not one
/// of the concrete types the C ABI knows about.
bool to_c_window_event(const nativeapi::WindowEvent& event, native_window_event_t* out);
/// Releases everything to_c_window_event() allocated.
void free_c_window_event(native_window_event_t* value);

#endif

#ifdef __cplusplus
#include "../window.h"
#include "string_utils_c.h"

// Conversion helpers between these C types and their C++ originals.

inline native_title_bar_style_t to_c_title_bar_style(nativeapi::TitleBarStyle value);
inline nativeapi::TitleBarStyle to_cpp_title_bar_style(native_title_bar_style_t value);
inline native_visual_effect_t to_c_visual_effect(nativeapi::VisualEffect value);
inline nativeapi::VisualEffect to_cpp_visual_effect(native_visual_effect_t value);

inline native_title_bar_style_t to_c_title_bar_style(nativeapi::TitleBarStyle value) {
  switch (value) {
    case nativeapi::TitleBarStyle::Normal:
      return NATIVE_TITLE_BAR_STYLE_NORMAL;
    case nativeapi::TitleBarStyle::Hidden:
      return NATIVE_TITLE_BAR_STYLE_HIDDEN;
    default:
      return NATIVE_TITLE_BAR_STYLE_NORMAL;
  }
}

inline nativeapi::TitleBarStyle to_cpp_title_bar_style(native_title_bar_style_t value) {
  switch (value) {
    case NATIVE_TITLE_BAR_STYLE_NORMAL:
      return nativeapi::TitleBarStyle::Normal;
    case NATIVE_TITLE_BAR_STYLE_HIDDEN:
      return nativeapi::TitleBarStyle::Hidden;
    default:
      return nativeapi::TitleBarStyle::Normal;
  }
}

inline native_visual_effect_t to_c_visual_effect(nativeapi::VisualEffect value) {
  switch (value) {
    case nativeapi::VisualEffect::None:
      return NATIVE_VISUAL_EFFECT_NONE;
    case nativeapi::VisualEffect::Blur:
      return NATIVE_VISUAL_EFFECT_BLUR;
    case nativeapi::VisualEffect::Acrylic:
      return NATIVE_VISUAL_EFFECT_ACRYLIC;
    case nativeapi::VisualEffect::Mica:
      return NATIVE_VISUAL_EFFECT_MICA;
    default:
      return NATIVE_VISUAL_EFFECT_NONE;
  }
}

inline nativeapi::VisualEffect to_cpp_visual_effect(native_visual_effect_t value) {
  switch (value) {
    case NATIVE_VISUAL_EFFECT_NONE:
      return nativeapi::VisualEffect::None;
    case NATIVE_VISUAL_EFFECT_BLUR:
      return nativeapi::VisualEffect::Blur;
    case NATIVE_VISUAL_EFFECT_ACRYLIC:
      return nativeapi::VisualEffect::Acrylic;
    case NATIVE_VISUAL_EFFECT_MICA:
      return nativeapi::VisualEffect::Mica;
    default:
      return nativeapi::VisualEffect::None;
  }
}

#endif  // __cplusplus
