// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#pragma once

#include <stdbool.h>
#include <stdint.h>

#include "common_c.h"
#include "geometry_c.h"
#include "image_c.h"
#include "menu_c.h"

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef unsigned int native_tray_icon_id_t;

typedef enum {
  NATIVE_CONTEXT_MENU_TRIGGER_NONE = 0,
  NATIVE_CONTEXT_MENU_TRIGGER_CLICKED = 1,
  NATIVE_CONTEXT_MENU_TRIGGER_RIGHT_CLICKED = 2,
  NATIVE_CONTEXT_MENU_TRIGGER_DOUBLE_CLICKED = 3,
} native_context_menu_trigger_t;

/// Opaque TrayIcon handle.
///
/// A generational index into the library's handle table, NOT a pointer:
/// never dereference it, and compare it against NATIVE_INVALID_TRAY_ICON rather than NULL.
/// Releasing a handle invalidates it; later calls fail safely instead of
/// touching freed memory.
typedef uint64_t native_tray_icon_t;

/// Never refers to a live TrayIcon.
#define NATIVE_INVALID_TRAY_ICON ((native_tray_icon_t)0)

/// Owning list of TrayIcon handles.
typedef struct {
  native_tray_icon_t* tray_icons;
  long count;
} native_tray_icon_list_t;

/// Which concrete TrayIconEvent arrived.
typedef enum {
  NATIVE_TRAY_ICON_EVENT_TYPE_CLICKED = 0,
  NATIVE_TRAY_ICON_EVENT_TYPE_RIGHT_CLICKED = 1,
  NATIVE_TRAY_ICON_EVENT_TYPE_DOUBLE_CLICKED = 2,
} native_tray_icon_event_type_t;

/// One TrayIconEvent, tagged by its concrete type.
///
/// Valid only for the duration of the callback: anything it points at
/// is released as soon as the callback returns. Copy what you need.
typedef struct {
  native_tray_icon_event_type_t type;
  union {
    struct {
      native_tray_icon_id_t tray_icon_id;
    } clicked;
    struct {
      native_tray_icon_id_t tray_icon_id;
    } right_clicked;
    struct {
      native_tray_icon_id_t tray_icon_id;
    } double_clicked;
  } data;
} native_tray_icon_event_t;

typedef void (*native_tray_icon_event_callback_t)(const native_tray_icon_event_t* event, void* user_data);

/// Creates a TrayIcon instance; release it with native_tray_icon_free().
FFI_PLUGIN_EXPORT
native_tray_icon_t native_tray_icon_create(void);

/// Creates a TrayIcon instance; release it with native_tray_icon_free().
FFI_PLUGIN_EXPORT
native_tray_icon_t native_tray_icon_create_with_tray(void* tray);

FFI_PLUGIN_EXPORT
native_tray_icon_id_t native_tray_icon_get_id(native_tray_icon_t tray_icon);

FFI_PLUGIN_EXPORT
void native_tray_icon_set_icon(native_tray_icon_t tray_icon, native_image_t image);

/// Caller owns the returned handle; release it with native_image_free().
FFI_PLUGIN_EXPORT
native_image_t native_tray_icon_get_icon(native_tray_icon_t tray_icon);

FFI_PLUGIN_EXPORT
void native_tray_icon_set_title(native_tray_icon_t tray_icon, const char* title);

/// Caller owns the returned string; free it with free_c_str().
FFI_PLUGIN_EXPORT
char* native_tray_icon_get_title(native_tray_icon_t tray_icon);

FFI_PLUGIN_EXPORT
void native_tray_icon_set_tooltip(native_tray_icon_t tray_icon, const char* tooltip);

/// Caller owns the returned string; free it with free_c_str().
FFI_PLUGIN_EXPORT
char* native_tray_icon_get_tooltip(native_tray_icon_t tray_icon);

FFI_PLUGIN_EXPORT
void native_tray_icon_set_context_menu(native_tray_icon_t tray_icon, native_menu_t menu);

/// Caller owns the returned handle; release it with native_menu_free().
FFI_PLUGIN_EXPORT
native_menu_t native_tray_icon_get_context_menu(native_tray_icon_t tray_icon);

FFI_PLUGIN_EXPORT
void native_tray_icon_set_context_menu_trigger(native_tray_icon_t tray_icon, native_context_menu_trigger_t trigger);

FFI_PLUGIN_EXPORT
native_context_menu_trigger_t native_tray_icon_get_context_menu_trigger(native_tray_icon_t tray_icon);

FFI_PLUGIN_EXPORT
native_rectangle_t native_tray_icon_get_bounds(native_tray_icon_t tray_icon);

FFI_PLUGIN_EXPORT
bool native_tray_icon_set_visible(native_tray_icon_t tray_icon, bool visible);

FFI_PLUGIN_EXPORT
bool native_tray_icon_is_visible(native_tray_icon_t tray_icon);

FFI_PLUGIN_EXPORT
bool native_tray_icon_open_context_menu(native_tray_icon_t tray_icon);

FFI_PLUGIN_EXPORT
bool native_tray_icon_close_context_menu(native_tray_icon_t tray_icon);

/// Platform-specific native object (NSScreen*, HMONITOR, ...).
FFI_PLUGIN_EXPORT
void* native_tray_icon_get_native_object(native_tray_icon_t tray_icon);

/// Releases the caller's reference. Safe to call with an invalid or
/// already-released handle.
FFI_PLUGIN_EXPORT
void native_tray_icon_free(native_tray_icon_t tray_icon);

/// Frees the array and releases every handle it contains.
FFI_PLUGIN_EXPORT
void native_tray_icon_list_free(native_tray_icon_list_t* list);

/// Frees only the array; the caller takes over the handles.
FFI_PLUGIN_EXPORT
void native_tray_icon_list_release(native_tray_icon_list_t* list);

/// Registers @p callback for every TrayIconEvent this TrayIcon emits.
/// @return the listener id, or NATIVE_INVALID_LISTENER_ID on failure.
FFI_PLUGIN_EXPORT
native_listener_id_t native_tray_icon_add_listener(native_tray_icon_t tray_icon, native_tray_icon_event_callback_t callback, void* user_data);

/// Unregisters a listener. Returns false if unknown.
FFI_PLUGIN_EXPORT
bool native_tray_icon_remove_listener(native_tray_icon_t tray_icon, native_listener_id_t listener_id);

#ifdef __cplusplus
}
#endif

#ifdef __cplusplus
namespace nativeapi {
class TrayIconEvent;
}  // namespace nativeapi

/// Fills @p out from @p event. Returns false when the event is not one
/// of the concrete types the C ABI knows about.
bool to_c_tray_icon_event(const nativeapi::TrayIconEvent& event, native_tray_icon_event_t* out);
/// Releases everything to_c_tray_icon_event() allocated.
void free_c_tray_icon_event(native_tray_icon_event_t* value);

#endif

#ifdef __cplusplus
#include "../tray_icon.h"
#include "string_utils_c.h"

// Conversion helpers between these C types and their C++ originals.

inline native_context_menu_trigger_t to_c_context_menu_trigger(nativeapi::ContextMenuTrigger value);
inline nativeapi::ContextMenuTrigger to_cpp_context_menu_trigger(native_context_menu_trigger_t value);

inline native_context_menu_trigger_t to_c_context_menu_trigger(nativeapi::ContextMenuTrigger value) {
  switch (value) {
    case nativeapi::ContextMenuTrigger::None:
      return NATIVE_CONTEXT_MENU_TRIGGER_NONE;
    case nativeapi::ContextMenuTrigger::Clicked:
      return NATIVE_CONTEXT_MENU_TRIGGER_CLICKED;
    case nativeapi::ContextMenuTrigger::RightClicked:
      return NATIVE_CONTEXT_MENU_TRIGGER_RIGHT_CLICKED;
    case nativeapi::ContextMenuTrigger::DoubleClicked:
      return NATIVE_CONTEXT_MENU_TRIGGER_DOUBLE_CLICKED;
    default:
      return NATIVE_CONTEXT_MENU_TRIGGER_NONE;
  }
}

inline nativeapi::ContextMenuTrigger to_cpp_context_menu_trigger(native_context_menu_trigger_t value) {
  switch (value) {
    case NATIVE_CONTEXT_MENU_TRIGGER_NONE:
      return nativeapi::ContextMenuTrigger::None;
    case NATIVE_CONTEXT_MENU_TRIGGER_CLICKED:
      return nativeapi::ContextMenuTrigger::Clicked;
    case NATIVE_CONTEXT_MENU_TRIGGER_RIGHT_CLICKED:
      return nativeapi::ContextMenuTrigger::RightClicked;
    case NATIVE_CONTEXT_MENU_TRIGGER_DOUBLE_CLICKED:
      return nativeapi::ContextMenuTrigger::DoubleClicked;
    default:
      return nativeapi::ContextMenuTrigger::None;
  }
}

#endif  // __cplusplus
