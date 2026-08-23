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

typedef enum {
  NATIVE_DIALOG_MODALITY_NONE = 0,
  NATIVE_DIALOG_MODALITY_APPLICATION = 1,
  NATIVE_DIALOG_MODALITY_WINDOW = 2,
} native_dialog_modality_t;

#ifdef __cplusplus
}
#endif

#ifdef __cplusplus
#include "../dialog.h"
#include "string_utils_c.h"

// Conversion helpers between these C types and their C++ originals.

inline native_dialog_modality_t to_c_dialog_modality(nativeapi::DialogModality value);
inline nativeapi::DialogModality to_cpp_dialog_modality(native_dialog_modality_t value);

inline native_dialog_modality_t to_c_dialog_modality(nativeapi::DialogModality value) {
  switch (value) {
    case nativeapi::DialogModality::None:
      return NATIVE_DIALOG_MODALITY_NONE;
    case nativeapi::DialogModality::Application:
      return NATIVE_DIALOG_MODALITY_APPLICATION;
    case nativeapi::DialogModality::Window:
      return NATIVE_DIALOG_MODALITY_WINDOW;
    default:
      return NATIVE_DIALOG_MODALITY_NONE;
  }
}

inline nativeapi::DialogModality to_cpp_dialog_modality(native_dialog_modality_t value) {
  switch (value) {
    case NATIVE_DIALOG_MODALITY_NONE:
      return nativeapi::DialogModality::None;
    case NATIVE_DIALOG_MODALITY_APPLICATION:
      return nativeapi::DialogModality::Application;
    case NATIVE_DIALOG_MODALITY_WINDOW:
      return nativeapi::DialogModality::Window;
    default:
      return nativeapi::DialogModality::None;
  }
}

#endif  // __cplusplus
