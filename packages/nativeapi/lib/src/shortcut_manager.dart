// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;
import 'dart:ui';

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

import 'shortcut.dart';

import 'support.dart';

final _bindings = c.cnativeApiBindings;

class ShortcutManager {
  const ShortcutManager._();

  /// The shared instance backed by the native singleton.
  static const ShortcutManager instance = ShortcutManager._();

  bool isSupported() {
    return _bindings.native_shortcut_manager_is_supported();
  }

  Shortcut? registerWithAcceleratorAndCallback(String accelerator, void Function() callback) {
    final acceleratorNative = accelerator.toNativeUtf8().cast<ffi.Char>();
    final callbackCallable = ffi.NativeCallable<
        ffi.Void Function(ffi.Pointer<ffi.Void>)>.isolateLocal(
      (ffi.Pointer<ffi.Void> _) {
        callback();
      },
    );
    _listeners.add(callbackCallable);
    final handle = _bindings.native_shortcut_manager_register_with_accelerator_and_callback(acceleratorNative, callbackCallable.nativeFunction, ffi.nullptr);
    pkg_ffi.calloc.free(acceleratorNative);
    if (handle == 0) return null;
    return Shortcut.fromHandle(handle);
  }

  Shortcut? registerWithOptions(ShortcutOptions options) {
    final optionsPointer = options.allocNative();
    final handle = _bindings.native_shortcut_manager_register_with_options(optionsPointer.ref);
    ShortcutOptions.freeNative(optionsPointer);
    if (handle == 0) return null;
    return Shortcut.fromHandle(handle);
  }

  bool unregisterWithId(ShortcutId id) {
    return _bindings.native_shortcut_manager_unregister_with_id(id);
  }

  bool unregisterWithAccelerator(String accelerator) {
    final acceleratorNative = accelerator.toNativeUtf8().cast<ffi.Char>();
    final result = _bindings.native_shortcut_manager_unregister_with_accelerator(acceleratorNative);
    pkg_ffi.calloc.free(acceleratorNative);
    return result;
  }

  int unregisterAll() {
    return _bindings.native_shortcut_manager_unregister_all();
  }

  Shortcut? getWithId(ShortcutId id) {
    final handle = _bindings.native_shortcut_manager_get_with_id(id);
    if (handle == 0) return null;
    return Shortcut.fromHandle(handle);
  }

  Shortcut? getWithAccelerator(String accelerator) {
    final acceleratorNative = accelerator.toNativeUtf8().cast<ffi.Char>();
    final handle = _bindings.native_shortcut_manager_get_with_accelerator(acceleratorNative);
    pkg_ffi.calloc.free(acceleratorNative);
    if (handle == 0) return null;
    return Shortcut.fromHandle(handle);
  }

  List<Shortcut> getAll() {
    final list = _bindings.native_shortcut_manager_get_all();
    final items = <Shortcut>[];
    for (var i = 0; i < list.count; i++) {
      items.add(Shortcut.fromHandle(list.shortcuts[i]));
    }
    final listPointer = pkg_ffi.calloc<c.native_shortcut_list_t>();
    listPointer.ref = list;
    // The handles now belong to `items`; free just the array.
    _bindings.native_shortcut_list_release(listPointer);
    pkg_ffi.calloc.free(listPointer);
    return items;
  }

  List<Shortcut> getByScope(ShortcutScope scope) {
    final list = _bindings.native_shortcut_manager_get_by_scope(scope.raw);
    final items = <Shortcut>[];
    for (var i = 0; i < list.count; i++) {
      items.add(Shortcut.fromHandle(list.shortcuts[i]));
    }
    final listPointer = pkg_ffi.calloc<c.native_shortcut_list_t>();
    listPointer.ref = list;
    // The handles now belong to `items`; free just the array.
    _bindings.native_shortcut_list_release(listPointer);
    pkg_ffi.calloc.free(listPointer);
    return items;
  }

  bool isAvailable(String accelerator) {
    final acceleratorNative = accelerator.toNativeUtf8().cast<ffi.Char>();
    final result = _bindings.native_shortcut_manager_is_available(acceleratorNative);
    pkg_ffi.calloc.free(acceleratorNative);
    return result;
  }

  bool isValidAccelerator(String accelerator) {
    final acceleratorNative = accelerator.toNativeUtf8().cast<ffi.Char>();
    final result = _bindings.native_shortcut_manager_is_valid_accelerator(acceleratorNative);
    pkg_ffi.calloc.free(acceleratorNative);
    return result;
  }

  void setEnabled(bool enabled) {
    _bindings.native_shortcut_manager_set_enabled(enabled);
  }

  bool isEnabled() {
    return _bindings.native_shortcut_manager_is_enabled();
  }

  void emitShortcutActivated(ShortcutId id, String accelerator) {
    final acceleratorNative = accelerator.toNativeUtf8().cast<ffi.Char>();
    _bindings.native_shortcut_manager_emit_shortcut_activated(id, acceleratorNative);
    pkg_ffi.calloc.free(acceleratorNative);
  }

  /// Registers [callback] for every `ShortcutEvent` this `ShortcutManager` emits.
  ///
  /// The callback runs synchronously on whichever thread the native side
  /// dispatches from, because the event struct is freed as soon as it
  /// returns. That thread must therefore be this isolate's own; see the
  /// package README for what that means under Flutter.
  ListenerId addListener(void Function(ShortcutEvent) callback) {
    final callable = ffi.NativeCallable<
        ffi.Void Function(ffi.Pointer<c.native_shortcut_event_t>, ffi.Pointer<ffi.Void>)>.isolateLocal(
      (ffi.Pointer<c.native_shortcut_event_t> event, ffi.Pointer<ffi.Void> _) {
        if (event == ffi.nullptr) return;
        final value = ShortcutEvent.fromNative(event.ref);
        if (value != null) callback(value);
      },
    );
    _listeners.add(callable);  // keeps the trampoline alive
    return _bindings.native_shortcut_manager_add_listener(callable.nativeFunction, ffi.nullptr);
  }

  /// Unregisters a listener. Returns false if unknown.
  bool removeListener(ListenerId listenerId) =>
      _bindings.native_shortcut_manager_remove_listener(listenerId);

  /// Trampolines stay reachable for as long as the C side may call them.
  static final List<Object> _listeners = <Object>[];

}

