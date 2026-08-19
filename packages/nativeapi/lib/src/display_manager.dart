// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;
import 'dart:ui';

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

import 'display.dart';
import 'foundation/geometry.dart';

import 'support.dart';

final _bindings = c.cnativeApiBindings;

class DisplayManager {
  const DisplayManager._();

  /// The shared instance backed by the native singleton.
  static const DisplayManager instance = DisplayManager._();

  List<Display> getAll() {
    final list = _bindings.native_display_manager_get_all();
    final items = <Display>[];
    for (var i = 0; i < list.count; i++) {
      items.add(Display.fromHandle(list.displays[i]));
    }
    final listPointer = pkg_ffi.calloc<c.native_display_list_t>();
    listPointer.ref = list;
    // The handles now belong to `items`; free just the array.
    _bindings.native_display_list_release(listPointer);
    pkg_ffi.calloc.free(listPointer);
    return items;
  }

  Display? getPrimary() {
    final handle = _bindings.native_display_manager_get_primary();
    if (handle == 0) return null;
    return Display.fromHandle(handle);
  }

  Offset getCursorPosition() {
    final raw = _bindings.native_display_manager_get_cursor_position();
    return Offset(raw.x, raw.y);
  }

  /// Registers [callback] for every `DisplayEvent` this `DisplayManager` emits.
  ///
  /// The callback runs synchronously on whichever thread the native side
  /// dispatches from, because the event struct is freed as soon as it
  /// returns. That thread must therefore be this isolate's own; see the
  /// package README for what that means under Flutter.
  ListenerId addListener(void Function(DisplayEvent) callback) {
    final callable = ffi.NativeCallable<
        ffi.Void Function(ffi.Pointer<c.native_display_event_t>, ffi.Pointer<ffi.Void>)>.isolateLocal(
      (ffi.Pointer<c.native_display_event_t> event, ffi.Pointer<ffi.Void> _) {
        if (event == ffi.nullptr) return;
        final value = DisplayEvent.fromNative(event.ref);
        if (value != null) callback(value);
      },
    );
    _listeners.add(callable);  // keeps the trampoline alive
    return _bindings.native_display_manager_add_listener(callable.nativeFunction, ffi.nullptr);
  }

  /// Unregisters a listener. Returns false if unknown.
  bool removeListener(ListenerId listenerId) =>
      _bindings.native_display_manager_remove_listener(listenerId);

  /// Trampolines stay reachable for as long as the C side may call them.
  static final List<Object> _listeners = <Object>[];

}

