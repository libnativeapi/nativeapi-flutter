import 'dart:ffi' as ffi;

import 'package:nativeapi/src/event_listener_mixin.dart';
import 'package:nativeapi/src/ffi/bindings.dart';
import 'package:nativeapi/src/ffi/bindings_generated.dart';
import 'package:nativeapi/src/keyboard_listener.dart';

class KeyboardMonitor with EventListenerMixin<KeyboardListener> {
  KeyboardMonitor._() {
    _keyPressedCallbackCallable =
        ffi.NativeCallable<KeyPressedCallbackFunction>.listener(_onKeyPressed);
    _keyReleasedCallbackCallable =
        ffi.NativeCallable<KeyReleasedCallbackFunction>.listener(
            _onKeyReleased);
    _bindings.keyboard_monitor_on_key_pressed(
        _keyPressedCallbackCallable.nativeFunction);
    _bindings.keyboard_monitor_on_key_released(
        _keyReleasedCallbackCallable.nativeFunction);
  }

  /// The singleton instance of the KeyboardMonitor.
  static final KeyboardMonitor instance = KeyboardMonitor._();

  /// The native API bindings.
  NativeApiBindings get _bindings => nativeApiBindings;

  late final ffi.NativeCallable<KeyPressedCallbackFunction>
      _keyPressedCallbackCallable;
  late final ffi.NativeCallable<KeyReleasedCallbackFunction>
      _keyReleasedCallbackCallable;

  void start() {
    _bindings.keyboard_monitor_start();
  }

  void stop() {
    _bindings.keyboard_monitor_stop();
  }

  /// Returns true if the shift key is pressed.
  bool isShiftPressed() {
    return _bindings.keyboard_monitor_is_shift_pressed();
  }

  /// Returns true if the ctrl key is pressed.
  bool isCtrlPressed() {
    return _bindings.keyboard_monitor_is_ctrl_pressed();
  }

  /// Returns true if the alt key is pressed.
  bool isAltPressed() {
    return _bindings.keyboard_monitor_is_alt_pressed();
  }

  /// Returns true if the meta key is pressed.
  bool isMetaPressed() {
    return _bindings.keyboard_monitor_is_meta_pressed();
  }

  /// Returns true if the fn key is pressed.
  bool isFnPressed() {
    return _bindings.keyboard_monitor_is_fn_pressed();
  }

  void _onKeyPressed(int keyCode) {
    notifyListeners((l) => l.onKeyPressed(keyCode));
  }

  void _onKeyReleased(int keyCode) {
    notifyListeners((l) => l.onKeyReleased(keyCode));
  }
}
