#pragma once

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*KeyPressedCallback)(int keycode);
typedef void (*KeyReleasedCallback)(int keycode);

FFI_PLUGIN_EXPORT
void keyboard_monitor_start();

FFI_PLUGIN_EXPORT
void keyboard_monitor_stop();

FFI_PLUGIN_EXPORT
void keyboard_monitor_on_key_pressed(KeyPressedCallback callback);

FFI_PLUGIN_EXPORT
void keyboard_monitor_on_key_released(KeyReleasedCallback callback);

#ifdef __cplusplus
}
#endif
