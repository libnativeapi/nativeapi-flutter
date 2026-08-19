// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;
import 'dart:ui';

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

import 'foundation/keyboard.dart';

import 'support.dart';

final _bindings = c.cnativeApiBindings;

class KeyboardMonitor {
  /// Adopts a handle returned by the C API and releases it when this
  /// object becomes unreachable.
  KeyboardMonitor.fromHandle(this.nativeHandle) {
    _finalizer.attach(this, nativeHandle, detach: this);
  }

  /// Wraps a handle owned elsewhere; releasing it stays the owner's job.
  KeyboardMonitor.borrowed(this.nativeHandle);

  /// The underlying handle-table entry.
  final int nativeHandle;

  static final Finalizer<int> _finalizer = Finalizer<int>(
    (handle) => _bindings.native_keyboard_monitor_free(handle),
  );

  /// Releases the handle now instead of at collection.
  void dispose() {
    _finalizer.detach(this);
    _bindings.native_keyboard_monitor_free(nativeHandle);
  }

  /// Creates a new `KeyboardMonitor`; returns null if the native side failed.
  static KeyboardMonitor? create() {
    final handle = _bindings.native_keyboard_monitor_create();
    if (handle == 0) return null;
    return KeyboardMonitor.fromHandle(handle);
  }

  void start() {
    _bindings.native_keyboard_monitor_start(nativeHandle);
  }

  void stop() {
    _bindings.native_keyboard_monitor_stop(nativeHandle);
  }

  bool get isMonitoring {
    return _bindings.native_keyboard_monitor_is_monitoring(nativeHandle);
  }

  /// Registers [callback] for every `KeyboardEvent` this `KeyboardMonitor` emits.
  ///
  /// The callback runs synchronously on whichever thread the native side
  /// dispatches from, because the event struct is freed as soon as it
  /// returns. That thread must therefore be this isolate's own; see the
  /// package README for what that means under Flutter.
  ListenerId addListener(void Function(KeyboardEvent) callback) {
    final callable = ffi.NativeCallable<
        ffi.Void Function(ffi.Pointer<c.native_keyboard_event_t>, ffi.Pointer<ffi.Void>)>.isolateLocal(
      (ffi.Pointer<c.native_keyboard_event_t> event, ffi.Pointer<ffi.Void> _) {
        if (event == ffi.nullptr) return;
        final value = KeyboardEvent.fromNative(event.ref);
        if (value != null) callback(value);
      },
    );
    _listeners.add(callable);  // keeps the trampoline alive
    return _bindings.native_keyboard_monitor_add_listener(nativeHandle, callable.nativeFunction, ffi.nullptr);
  }

  /// Unregisters a listener. Returns false if unknown.
  bool removeListener(ListenerId listenerId) =>
      _bindings.native_keyboard_monitor_remove_listener(nativeHandle, listenerId);

  /// Trampolines stay reachable for as long as the C side may call them.
  static final List<Object> _listeners = <Object>[];

}

