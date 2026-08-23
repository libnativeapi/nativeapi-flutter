// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#pragma once

#include <stdbool.h>
#include <stdint.h>

#include "common_c.h"
#include "image_c.h"
#include "keyboard_c.h"
#include "placement_c.h"
#include "positioning_strategy_c.h"

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef unsigned int native_menu_id_t;

typedef unsigned int native_menu_item_id_t;

typedef enum {
  NATIVE_MENU_ITEM_TYPE_NORMAL = 0,
  NATIVE_MENU_ITEM_TYPE_CHECKBOX = 1,
  NATIVE_MENU_ITEM_TYPE_RADIO = 2,
  NATIVE_MENU_ITEM_TYPE_SEPARATOR = 3,
  NATIVE_MENU_ITEM_TYPE_SUBMENU = 4,
} native_menu_item_type_t;

typedef enum {
  NATIVE_MENU_ITEM_STATE_UNCHECKED = 0,
  NATIVE_MENU_ITEM_STATE_CHECKED = 1,
  NATIVE_MENU_ITEM_STATE_MIXED = 2,
} native_menu_item_state_t;

/// Opaque MenuItem handle.
///
/// A generational index into the library's handle table, NOT a pointer:
/// never dereference it, and compare it against NATIVE_INVALID_MENU_ITEM rather than NULL.
/// Releasing a handle invalidates it; later calls fail safely instead of
/// touching freed memory.
typedef uint64_t native_menu_item_t;

/// Never refers to a live MenuItem.
#define NATIVE_INVALID_MENU_ITEM ((native_menu_item_t)0)

/// Owning list of MenuItem handles.
typedef struct {
  native_menu_item_t* menu_items;
  long count;
} native_menu_item_list_t;

/// Opaque Menu handle.
///
/// A generational index into the library's handle table, NOT a pointer:
/// never dereference it, and compare it against NATIVE_INVALID_MENU rather than NULL.
/// Releasing a handle invalidates it; later calls fail safely instead of
/// touching freed memory.
typedef uint64_t native_menu_t;

/// Never refers to a live Menu.
#define NATIVE_INVALID_MENU ((native_menu_t)0)

/// Which concrete MenuEvent arrived.
typedef enum {
  NATIVE_MENU_EVENT_TYPE_OPENED = 0,
  NATIVE_MENU_EVENT_TYPE_CLOSED = 1,
  NATIVE_MENU_EVENT_TYPE_ITEM_CLICKED = 2,
  NATIVE_MENU_EVENT_TYPE_ITEM_SUBMENU_OPENED = 3,
  NATIVE_MENU_EVENT_TYPE_ITEM_SUBMENU_CLOSED = 4,
} native_menu_event_type_t;

/// One MenuEvent, tagged by its concrete type.
///
/// Valid only for the duration of the callback: anything it points at
/// is released as soon as the callback returns. Copy what you need.
typedef struct {
  native_menu_event_type_t type;
  union {
    struct {
      native_menu_id_t menu_id;
    } opened;
    struct {
      native_menu_id_t menu_id;
    } closed;
    struct {
      native_menu_item_id_t item_id;
    } item_clicked;
    struct {
      native_menu_item_id_t item_id;
    } item_submenu_opened;
    struct {
      native_menu_item_id_t item_id;
    } item_submenu_closed;
  } data;
} native_menu_event_t;

typedef void (*native_menu_event_callback_t)(const native_menu_event_t* event, void* user_data);

/// Creates a MenuItem instance; release it with native_menu_item_free().
FFI_PLUGIN_EXPORT
native_menu_item_t native_menu_item_create_with_label_and_type(const char* label, native_menu_item_type_t type);

/// Creates a MenuItem instance; release it with native_menu_item_free().
FFI_PLUGIN_EXPORT
native_menu_item_t native_menu_item_create_with_native_item(void* native_item);

FFI_PLUGIN_EXPORT
native_menu_item_id_t native_menu_item_get_id(native_menu_item_t menu_item);

FFI_PLUGIN_EXPORT
native_menu_item_type_t native_menu_item_get_type(native_menu_item_t menu_item);

FFI_PLUGIN_EXPORT
void native_menu_item_set_label(native_menu_item_t menu_item, const char* label);

/// Caller owns the returned string; free it with free_c_str().
FFI_PLUGIN_EXPORT
char* native_menu_item_get_label(native_menu_item_t menu_item);

FFI_PLUGIN_EXPORT
void native_menu_item_set_icon(native_menu_item_t menu_item, native_image_t image);

/// Caller owns the returned handle; release it with native_image_free().
FFI_PLUGIN_EXPORT
native_image_t native_menu_item_get_icon(native_menu_item_t menu_item);

FFI_PLUGIN_EXPORT
void native_menu_item_set_tooltip(native_menu_item_t menu_item, const char* tooltip);

/// Caller owns the returned string; free it with free_c_str().
FFI_PLUGIN_EXPORT
char* native_menu_item_get_tooltip(native_menu_item_t menu_item);

FFI_PLUGIN_EXPORT
void native_menu_item_set_accelerator(native_menu_item_t menu_item, const native_keyboard_accelerator_t* accelerator);

FFI_PLUGIN_EXPORT
native_keyboard_accelerator_t native_menu_item_get_accelerator(native_menu_item_t menu_item);

FFI_PLUGIN_EXPORT
void native_menu_item_set_enabled(native_menu_item_t menu_item, bool enabled);

FFI_PLUGIN_EXPORT
bool native_menu_item_is_enabled(native_menu_item_t menu_item);

FFI_PLUGIN_EXPORT
void native_menu_item_set_state(native_menu_item_t menu_item, native_menu_item_state_t state);

FFI_PLUGIN_EXPORT
native_menu_item_state_t native_menu_item_get_state(native_menu_item_t menu_item);

FFI_PLUGIN_EXPORT
void native_menu_item_set_radio_group(native_menu_item_t menu_item, int group_id);

FFI_PLUGIN_EXPORT
int native_menu_item_get_radio_group(native_menu_item_t menu_item);

FFI_PLUGIN_EXPORT
void native_menu_item_set_submenu(native_menu_item_t menu_item, native_menu_t submenu);

/// Caller owns the returned handle; release it with native_menu_free().
FFI_PLUGIN_EXPORT
native_menu_t native_menu_item_get_submenu(native_menu_item_t menu_item);

/// Platform-specific native object (NSScreen*, HMONITOR, ...).
FFI_PLUGIN_EXPORT
void* native_menu_item_get_native_object(native_menu_item_t menu_item);

/// Releases the caller's reference. Safe to call with an invalid or
/// already-released handle.
FFI_PLUGIN_EXPORT
void native_menu_item_free(native_menu_item_t menu_item);

/// Frees the array and releases every handle it contains.
FFI_PLUGIN_EXPORT
void native_menu_item_list_free(native_menu_item_list_t* list);

/// Frees only the array; the caller takes over the handles.
FFI_PLUGIN_EXPORT
void native_menu_item_list_release(native_menu_item_list_t* list);

/// Registers @p callback for every MenuEvent this MenuItem emits.
/// @return the listener id, or NATIVE_INVALID_LISTENER_ID on failure.
FFI_PLUGIN_EXPORT
native_listener_id_t native_menu_item_add_listener(native_menu_item_t menu_item, native_menu_event_callback_t callback, void* user_data);

/// Unregisters a listener. Returns false if unknown.
FFI_PLUGIN_EXPORT
bool native_menu_item_remove_listener(native_menu_item_t menu_item, native_listener_id_t listener_id);

/// Creates a Menu instance; release it with native_menu_free().
FFI_PLUGIN_EXPORT
native_menu_t native_menu_create(void);

/// Creates a Menu instance; release it with native_menu_free().
FFI_PLUGIN_EXPORT
native_menu_t native_menu_create_with_native_menu(void* native_menu);

FFI_PLUGIN_EXPORT
native_menu_id_t native_menu_get_id(native_menu_t menu);

FFI_PLUGIN_EXPORT
void native_menu_add_item(native_menu_t menu, native_menu_item_t item);

FFI_PLUGIN_EXPORT
void native_menu_insert_item(native_menu_t menu, unsigned long index, native_menu_item_t item);

FFI_PLUGIN_EXPORT
bool native_menu_remove_item(native_menu_t menu, native_menu_item_t item);

FFI_PLUGIN_EXPORT
bool native_menu_remove_item_by_id(native_menu_t menu, native_menu_item_id_t item_id);

FFI_PLUGIN_EXPORT
bool native_menu_remove_item_at(native_menu_t menu, unsigned long index);

FFI_PLUGIN_EXPORT
void native_menu_clear(native_menu_t menu);

FFI_PLUGIN_EXPORT
void native_menu_add_separator(native_menu_t menu);

FFI_PLUGIN_EXPORT
void native_menu_insert_separator(native_menu_t menu, unsigned long index);

FFI_PLUGIN_EXPORT
unsigned long native_menu_get_item_count(native_menu_t menu);

/// Caller owns the returned handle; release it with native_menu_item_free().
FFI_PLUGIN_EXPORT
native_menu_item_t native_menu_get_item_at(native_menu_t menu, unsigned long index);

/// Caller owns the returned handle; release it with native_menu_item_free().
FFI_PLUGIN_EXPORT
native_menu_item_t native_menu_get_item_by_id(native_menu_t menu, native_menu_item_id_t item_id);

FFI_PLUGIN_EXPORT
native_menu_item_list_t native_menu_get_all_items(native_menu_t menu);

FFI_PLUGIN_EXPORT
bool native_menu_open(native_menu_t menu, native_positioning_strategy_t strategy, native_placement_t placement);

FFI_PLUGIN_EXPORT
bool native_menu_close(native_menu_t menu);

/// Platform-specific native object (NSScreen*, HMONITOR, ...).
FFI_PLUGIN_EXPORT
void* native_menu_get_native_object(native_menu_t menu);

/// Releases the caller's reference. Safe to call with an invalid or
/// already-released handle.
FFI_PLUGIN_EXPORT
void native_menu_free(native_menu_t menu);

/// Registers @p callback for every MenuEvent this Menu emits.
/// @return the listener id, or NATIVE_INVALID_LISTENER_ID on failure.
FFI_PLUGIN_EXPORT
native_listener_id_t native_menu_add_listener(native_menu_t menu, native_menu_event_callback_t callback, void* user_data);

/// Unregisters a listener. Returns false if unknown.
FFI_PLUGIN_EXPORT
bool native_menu_remove_listener(native_menu_t menu, native_listener_id_t listener_id);

#ifdef __cplusplus
}
#endif

#ifdef __cplusplus
namespace nativeapi {
class MenuEvent;
}  // namespace nativeapi

/// Fills @p out from @p event. Returns false when the event is not one
/// of the concrete types the C ABI knows about.
bool to_c_menu_event(const nativeapi::MenuEvent& event, native_menu_event_t* out);
/// Releases everything to_c_menu_event() allocated.
void free_c_menu_event(native_menu_event_t* value);

#endif

#ifdef __cplusplus
#include "../menu.h"
#include "string_utils_c.h"

// Conversion helpers between these C types and their C++ originals.

inline native_menu_item_type_t to_c_menu_item_type(nativeapi::MenuItemType value);
inline nativeapi::MenuItemType to_cpp_menu_item_type(native_menu_item_type_t value);
inline native_menu_item_state_t to_c_menu_item_state(nativeapi::MenuItemState value);
inline nativeapi::MenuItemState to_cpp_menu_item_state(native_menu_item_state_t value);

inline native_menu_item_type_t to_c_menu_item_type(nativeapi::MenuItemType value) {
  switch (value) {
    case nativeapi::MenuItemType::Normal:
      return NATIVE_MENU_ITEM_TYPE_NORMAL;
    case nativeapi::MenuItemType::Checkbox:
      return NATIVE_MENU_ITEM_TYPE_CHECKBOX;
    case nativeapi::MenuItemType::Radio:
      return NATIVE_MENU_ITEM_TYPE_RADIO;
    case nativeapi::MenuItemType::Separator:
      return NATIVE_MENU_ITEM_TYPE_SEPARATOR;
    case nativeapi::MenuItemType::Submenu:
      return NATIVE_MENU_ITEM_TYPE_SUBMENU;
    default:
      return NATIVE_MENU_ITEM_TYPE_NORMAL;
  }
}

inline nativeapi::MenuItemType to_cpp_menu_item_type(native_menu_item_type_t value) {
  switch (value) {
    case NATIVE_MENU_ITEM_TYPE_NORMAL:
      return nativeapi::MenuItemType::Normal;
    case NATIVE_MENU_ITEM_TYPE_CHECKBOX:
      return nativeapi::MenuItemType::Checkbox;
    case NATIVE_MENU_ITEM_TYPE_RADIO:
      return nativeapi::MenuItemType::Radio;
    case NATIVE_MENU_ITEM_TYPE_SEPARATOR:
      return nativeapi::MenuItemType::Separator;
    case NATIVE_MENU_ITEM_TYPE_SUBMENU:
      return nativeapi::MenuItemType::Submenu;
    default:
      return nativeapi::MenuItemType::Normal;
  }
}

inline native_menu_item_state_t to_c_menu_item_state(nativeapi::MenuItemState value) {
  switch (value) {
    case nativeapi::MenuItemState::Unchecked:
      return NATIVE_MENU_ITEM_STATE_UNCHECKED;
    case nativeapi::MenuItemState::Checked:
      return NATIVE_MENU_ITEM_STATE_CHECKED;
    case nativeapi::MenuItemState::Mixed:
      return NATIVE_MENU_ITEM_STATE_MIXED;
    default:
      return NATIVE_MENU_ITEM_STATE_UNCHECKED;
  }
}

inline nativeapi::MenuItemState to_cpp_menu_item_state(native_menu_item_state_t value) {
  switch (value) {
    case NATIVE_MENU_ITEM_STATE_UNCHECKED:
      return nativeapi::MenuItemState::Unchecked;
    case NATIVE_MENU_ITEM_STATE_CHECKED:
      return nativeapi::MenuItemState::Checked;
    case NATIVE_MENU_ITEM_STATE_MIXED:
      return nativeapi::MenuItemState::Mixed;
    default:
      return nativeapi::MenuItemState::Unchecked;
  }
}

#endif  // __cplusplus
