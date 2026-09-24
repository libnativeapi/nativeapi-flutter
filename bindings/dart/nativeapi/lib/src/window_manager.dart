// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

import 'foundation/geometry.dart';
import 'window.dart';

import 'support.dart';

class WindowManager {
  const WindowManager._();

  /// The shared instance backed by the native singleton.
  static const WindowManager instance = WindowManager._();

  Window? get(WindowId id) {
    final handle = c.native_window_manager_get(id);
    if (handle == 0) return null;
    return Window.fromHandle(handle);
  }

  List<Window> getAll() {
    final list = c.native_window_manager_get_all();
    final items = <Window>[];
    for (var i = 0; i < list.count; i++) {
      items.add(Window.fromHandle(list.windows[i]));
    }
    final listPointer = pkg_ffi.calloc<c.native_window_list_t>();
    listPointer.ref = list;
    // The handles now belong to `items`; free just the array.
    c.native_window_list_release(listPointer);
    pkg_ffi.calloc.free(listPointer);
    return items;
  }

  Window? getCurrent() {
    final handle = c.native_window_manager_get_current();
    if (handle == 0) return null;
    return Window.fromHandle(handle);
  }

  Window? getWindowAtPoint(Point point, WindowId excludedWindowId) {
    final pointPointer = point.allocNative();
    final handle = c.native_window_manager_get_window_at_point(
      pointPointer.ref,
      excludedWindowId,
    );
    Point.freeNative(pointPointer);
    if (handle == 0) return null;
    return Window.fromHandle(handle);
  }

  void setWillShowHook(void Function(int)? hook) {
    final hookCallable = hook == null
        ? null
        : ffi.NativeCallable<
            ffi.Void Function(ffi.UnsignedInt, ffi.Pointer<ffi.Void>)
          >.isolateLocal((int arg0, ffi.Pointer<ffi.Void> _) {
            hook(arg0);
          });
    if (hookCallable != null) _listeners.add(hookCallable);
    c.native_window_manager_set_will_show_hook(
      hookCallable?.nativeFunction ?? ffi.nullptr,
      ffi.nullptr,
    );
  }

  void setWillHideHook(void Function(int)? hook) {
    final hookCallable = hook == null
        ? null
        : ffi.NativeCallable<
            ffi.Void Function(ffi.UnsignedInt, ffi.Pointer<ffi.Void>)
          >.isolateLocal((int arg0, ffi.Pointer<ffi.Void> _) {
            hook(arg0);
          });
    if (hookCallable != null) _listeners.add(hookCallable);
    c.native_window_manager_set_will_hide_hook(
      hookCallable?.nativeFunction ?? ffi.nullptr,
      ffi.nullptr,
    );
  }

  bool hasWillShowHook() {
    return c.native_window_manager_has_will_show_hook();
  }

  bool hasWillHideHook() {
    return c.native_window_manager_has_will_hide_hook();
  }

  void handleWillShow(WindowId id) {
    c.native_window_manager_handle_will_show(id);
  }

  void handleWillHide(WindowId id) {
    c.native_window_manager_handle_will_hide(id);
  }

  bool callOriginalShow(WindowId id) {
    return c.native_window_manager_call_original_show(id);
  }

  bool callOriginalHide(WindowId id) {
    return c.native_window_manager_call_original_hide(id);
  }

  /// Registers [callback] for every `WindowEvent` this `WindowManager` emits.
  ///
  /// The callback runs synchronously on whichever thread the native side
  /// dispatches from, because the event struct is freed as soon as it
  /// returns. That thread must therefore be this isolate's own; see the
  /// package README for what that means under Flutter.
  ListenerId addListener(void Function(WindowEvent) callback) {
    final callable =
        ffi.NativeCallable<
          ffi.Void Function(
            ffi.Pointer<c.native_window_event_t>,
            ffi.Pointer<ffi.Void>,
          )
        >.isolateLocal((
          ffi.Pointer<c.native_window_event_t> event,
          ffi.Pointer<ffi.Void> _,
        ) {
          if (event == ffi.nullptr) return;
          final value = WindowEvent.fromNative(event.ref);
          if (value != null) callback(value);
        });
    _listeners.add(callable); // keeps the trampoline alive
    return c.native_window_manager_add_listener(
      callable.nativeFunction,
      ffi.nullptr,
    );
  }

  /// Unregisters a listener. Returns false if unknown.
  bool removeListener(ListenerId listenerId) =>
      c.native_window_manager_remove_listener(listenerId);

  /// Trampolines stay reachable for as long as the C side may call them.
  static final List<Object> _listeners = <Object>[];
}
