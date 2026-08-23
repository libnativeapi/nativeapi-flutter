// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

#pragma once

#include <stdbool.h>
#include <stdint.h>

#include "common_c.h"
#include "geometry_c.h"

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef unsigned int native_display_id_t;

typedef enum {
  NATIVE_DISPLAY_ORIENTATION_PORTRAIT = 0,
  NATIVE_DISPLAY_ORIENTATION_LANDSCAPE = 90,
  NATIVE_DISPLAY_ORIENTATION_PORTRAIT_FLIPPED = 180,
  NATIVE_DISPLAY_ORIENTATION_LANDSCAPE_FLIPPED = 270,
} native_display_orientation_t;

/// Opaque Display handle.
///
/// A generational index into the library's handle table, NOT a pointer:
/// never dereference it, and compare it against NATIVE_INVALID_DISPLAY rather than NULL.
/// Releasing a handle invalidates it; later calls fail safely instead of
/// touching freed memory.
typedef uint64_t native_display_t;

/// Never refers to a live Display.
#define NATIVE_INVALID_DISPLAY ((native_display_t)0)

/// Owning list of Display handles.
typedef struct {
  native_display_t* displays;
  long count;
} native_display_list_t;

/// Which concrete DisplayEvent arrived.
typedef enum {
  NATIVE_DISPLAY_EVENT_TYPE_ADDED = 0,
  NATIVE_DISPLAY_EVENT_TYPE_REMOVED = 1,
  NATIVE_DISPLAY_EVENT_TYPE_CHANGED = 2,
} native_display_event_type_t;

/// One DisplayEvent, tagged by its concrete type.
///
/// Valid only for the duration of the callback: anything it points at
/// is released as soon as the callback returns. Copy what you need.
typedef struct {
  native_display_event_type_t type;
  native_display_t display;
} native_display_event_t;

typedef void (*native_display_event_callback_t)(const native_display_event_t* event, void* user_data);

/// Creates a Display instance; release it with native_display_free().
FFI_PLUGIN_EXPORT
native_display_t native_display_create(void* display);

FFI_PLUGIN_EXPORT
native_display_id_t native_display_get_id(native_display_t display);

/// Caller owns the returned string; free it with free_c_str().
FFI_PLUGIN_EXPORT
char* native_display_get_name(native_display_t display);

FFI_PLUGIN_EXPORT
native_point_t native_display_get_position(native_display_t display);

FFI_PLUGIN_EXPORT
native_size_t native_display_get_size(native_display_t display);

FFI_PLUGIN_EXPORT
native_rectangle_t native_display_get_work_area(native_display_t display);

FFI_PLUGIN_EXPORT
double native_display_get_scale_factor(native_display_t display);

FFI_PLUGIN_EXPORT
bool native_display_is_primary(native_display_t display);

FFI_PLUGIN_EXPORT
native_display_orientation_t native_display_get_orientation(native_display_t display);

FFI_PLUGIN_EXPORT
int native_display_get_refresh_rate(native_display_t display);

FFI_PLUGIN_EXPORT
int native_display_get_bit_depth(native_display_t display);

/// Platform-specific native object (NSScreen*, HMONITOR, ...).
FFI_PLUGIN_EXPORT
void* native_display_get_native_object(native_display_t display);

/// Releases the caller's reference. Safe to call with an invalid or
/// already-released handle.
FFI_PLUGIN_EXPORT
void native_display_free(native_display_t display);

/// Frees the array and releases every handle it contains.
FFI_PLUGIN_EXPORT
void native_display_list_free(native_display_list_t* list);

/// Frees only the array; the caller takes over the handles.
FFI_PLUGIN_EXPORT
void native_display_list_release(native_display_list_t* list);

#ifdef __cplusplus
}
#endif

#ifdef __cplusplus
namespace nativeapi {
class DisplayEvent;
}  // namespace nativeapi

/// Fills @p out from @p event. Returns false when the event is not one
/// of the concrete types the C ABI knows about.
bool to_c_display_event(const nativeapi::DisplayEvent& event, native_display_event_t* out);
/// Releases everything to_c_display_event() allocated.
void free_c_display_event(native_display_event_t* value);

#endif

#ifdef __cplusplus
#include "../display.h"
#include "string_utils_c.h"

// Conversion helpers between these C types and their C++ originals.

inline native_display_orientation_t to_c_display_orientation(nativeapi::DisplayOrientation value);
inline nativeapi::DisplayOrientation to_cpp_display_orientation(native_display_orientation_t value);

inline native_display_orientation_t to_c_display_orientation(nativeapi::DisplayOrientation value) {
  switch (value) {
    case nativeapi::DisplayOrientation::kPortrait:
      return NATIVE_DISPLAY_ORIENTATION_PORTRAIT;
    case nativeapi::DisplayOrientation::kLandscape:
      return NATIVE_DISPLAY_ORIENTATION_LANDSCAPE;
    case nativeapi::DisplayOrientation::kPortraitFlipped:
      return NATIVE_DISPLAY_ORIENTATION_PORTRAIT_FLIPPED;
    case nativeapi::DisplayOrientation::kLandscapeFlipped:
      return NATIVE_DISPLAY_ORIENTATION_LANDSCAPE_FLIPPED;
    default:
      return NATIVE_DISPLAY_ORIENTATION_PORTRAIT;
  }
}

inline nativeapi::DisplayOrientation to_cpp_display_orientation(native_display_orientation_t value) {
  switch (value) {
    case NATIVE_DISPLAY_ORIENTATION_PORTRAIT:
      return nativeapi::DisplayOrientation::kPortrait;
    case NATIVE_DISPLAY_ORIENTATION_LANDSCAPE:
      return nativeapi::DisplayOrientation::kLandscape;
    case NATIVE_DISPLAY_ORIENTATION_PORTRAIT_FLIPPED:
      return nativeapi::DisplayOrientation::kPortraitFlipped;
    case NATIVE_DISPLAY_ORIENTATION_LANDSCAPE_FLIPPED:
      return nativeapi::DisplayOrientation::kLandscapeFlipped;
    default:
      return nativeapi::DisplayOrientation::kPortrait;
  }
}

#endif  // __cplusplus
