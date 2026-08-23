// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#pragma once

#include <stdbool.h>
#include <stdint.h>

#include "common_c.h"

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef unsigned int native_shortcut_id_t;

typedef enum {
  NATIVE_SHORTCUT_SCOPE_GLOBAL = 0,
  NATIVE_SHORTCUT_SCOPE_APPLICATION = 1,
} native_shortcut_scope_t;

typedef void (*native_shortcut_options_callback_t)(void* user_data);

typedef void (*native_shortcut_create_with_id_and_accelerator_and_callback_t)(void* user_data);

typedef void (*native_shortcut_set_callback_t)(void* user_data);

typedef struct {
  char* accelerator;
  native_shortcut_options_callback_t callback;
  void* callback_user_data;
  char* description;
  native_shortcut_scope_t scope;
  bool enabled;
} native_shortcut_options_t;

/// Opaque Shortcut handle.
///
/// A generational index into the library's handle table, NOT a pointer:
/// never dereference it, and compare it against NATIVE_INVALID_SHORTCUT rather than NULL.
/// Releasing a handle invalidates it; later calls fail safely instead of
/// touching freed memory.
typedef uint64_t native_shortcut_t;

/// Never refers to a live Shortcut.
#define NATIVE_INVALID_SHORTCUT ((native_shortcut_t)0)

/// Owning list of Shortcut handles.
typedef struct {
  native_shortcut_t* shortcuts;
  long count;
} native_shortcut_list_t;

/// Which concrete ShortcutEvent arrived.
typedef enum {
  NATIVE_SHORTCUT_EVENT_TYPE_ACTIVATED = 0,
  NATIVE_SHORTCUT_EVENT_TYPE_REGISTERED = 1,
  NATIVE_SHORTCUT_EVENT_TYPE_UNREGISTERED = 2,
  NATIVE_SHORTCUT_EVENT_TYPE_REGISTRATION_FAILED = 3,
} native_shortcut_event_type_t;

/// One ShortcutEvent, tagged by its concrete type.
///
/// Valid only for the duration of the callback: anything it points at
/// is released as soon as the callback returns. Copy what you need.
typedef struct {
  native_shortcut_event_type_t type;
  native_shortcut_id_t shortcut_id;
  char* accelerator;
  union {
    struct {
      char* error_message;
    } registration_failed;
  } data;
} native_shortcut_event_t;

typedef void (*native_shortcut_event_callback_t)(const native_shortcut_event_t* event, void* user_data);

/// Frees everything the struct owns.
FFI_PLUGIN_EXPORT
void native_shortcut_options_free(native_shortcut_options_t* value);

/// Creates a Shortcut instance; release it with native_shortcut_free().
FFI_PLUGIN_EXPORT
native_shortcut_t native_shortcut_create_with_id_and_options(native_shortcut_id_t id, native_shortcut_options_t options);

/// Creates a Shortcut instance; release it with native_shortcut_free().
FFI_PLUGIN_EXPORT
native_shortcut_t native_shortcut_create_with_id_and_accelerator_and_callback(native_shortcut_id_t id, const char* accelerator, native_shortcut_create_with_id_and_accelerator_and_callback_t callback, void* callback_user_data);

FFI_PLUGIN_EXPORT
native_shortcut_id_t native_shortcut_get_id(native_shortcut_t shortcut);

/// Caller owns the returned string; free it with free_c_str().
FFI_PLUGIN_EXPORT
char* native_shortcut_get_accelerator(native_shortcut_t shortcut);

/// Caller owns the returned string; free it with free_c_str().
FFI_PLUGIN_EXPORT
char* native_shortcut_get_description(native_shortcut_t shortcut);

FFI_PLUGIN_EXPORT
void native_shortcut_set_description(native_shortcut_t shortcut, const char* description);

FFI_PLUGIN_EXPORT
native_shortcut_scope_t native_shortcut_get_scope(native_shortcut_t shortcut);

FFI_PLUGIN_EXPORT
void native_shortcut_set_enabled(native_shortcut_t shortcut, bool enabled);

FFI_PLUGIN_EXPORT
bool native_shortcut_is_enabled(native_shortcut_t shortcut);

FFI_PLUGIN_EXPORT
void native_shortcut_invoke(native_shortcut_t shortcut);

FFI_PLUGIN_EXPORT
void native_shortcut_set_callback(native_shortcut_t shortcut, native_shortcut_set_callback_t callback, void* callback_user_data);

/// Releases the caller's reference. Safe to call with an invalid or
/// already-released handle.
FFI_PLUGIN_EXPORT
void native_shortcut_free(native_shortcut_t shortcut);

/// Frees the array and releases every handle it contains.
FFI_PLUGIN_EXPORT
void native_shortcut_list_free(native_shortcut_list_t* list);

/// Frees only the array; the caller takes over the handles.
FFI_PLUGIN_EXPORT
void native_shortcut_list_release(native_shortcut_list_t* list);

#ifdef __cplusplus
}
#endif

#ifdef __cplusplus
namespace nativeapi {
class ShortcutEvent;
}  // namespace nativeapi

/// Fills @p out from @p event. Returns false when the event is not one
/// of the concrete types the C ABI knows about.
bool to_c_shortcut_event(const nativeapi::ShortcutEvent& event, native_shortcut_event_t* out);
/// Releases everything to_c_shortcut_event() allocated.
void free_c_shortcut_event(native_shortcut_event_t* value);

#endif

#ifdef __cplusplus
#include "../shortcut.h"
#include "string_utils_c.h"

// Conversion helpers between these C types and their C++ originals.

inline native_shortcut_scope_t to_c_shortcut_scope(nativeapi::ShortcutScope value);
inline nativeapi::ShortcutScope to_cpp_shortcut_scope(native_shortcut_scope_t value);
inline native_shortcut_options_t to_c_shortcut_options(const nativeapi::ShortcutOptions& value);
inline nativeapi::ShortcutOptions to_cpp_shortcut_options(const native_shortcut_options_t& value);

inline native_shortcut_scope_t to_c_shortcut_scope(nativeapi::ShortcutScope value) {
  switch (value) {
    case nativeapi::ShortcutScope::Global:
      return NATIVE_SHORTCUT_SCOPE_GLOBAL;
    case nativeapi::ShortcutScope::Application:
      return NATIVE_SHORTCUT_SCOPE_APPLICATION;
    default:
      return NATIVE_SHORTCUT_SCOPE_GLOBAL;
  }
}

inline nativeapi::ShortcutScope to_cpp_shortcut_scope(native_shortcut_scope_t value) {
  switch (value) {
    case NATIVE_SHORTCUT_SCOPE_GLOBAL:
      return nativeapi::ShortcutScope::Global;
    case NATIVE_SHORTCUT_SCOPE_APPLICATION:
      return nativeapi::ShortcutScope::Application;
    default:
      return nativeapi::ShortcutScope::Global;
  }
}

inline native_shortcut_options_t to_c_shortcut_options(const nativeapi::ShortcutOptions& value) {
  native_shortcut_options_t result = {};
  result.accelerator = to_c_str(value.accelerator);
  result.description = to_c_str(value.description);
  result.scope = to_c_shortcut_scope(value.scope);
  result.enabled = value.enabled;
  return result;
}

inline nativeapi::ShortcutOptions to_cpp_shortcut_options(const native_shortcut_options_t& value) {
  nativeapi::ShortcutOptions result = {};
  result.accelerator = value.accelerator ? value.accelerator : "";
  if (value.callback) {
    auto callback = value.callback;
    auto* data = value.callback_user_data;
    result.callback = [callback, data]() { callback(data); };
  }
  result.description = value.description ? value.description : "";
  result.scope = to_cpp_shortcut_scope(value.scope);
  result.enabled = value.enabled;
  return result;
}

#endif  // __cplusplus
