// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;
import 'dart:ui';

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

final _bindings = c.cnativeApiBindings;

typedef ShortcutId = int;

enum ShortcutScope {
  global(0),
  application(1);

  const ShortcutScope(this.value);
  final int value;

  static ShortcutScope fromValue(int value) => switch (value) {
    0 => ShortcutScope.global,
    1 => ShortcutScope.application,
    _ => ShortcutScope.global,
  };

  c.native_shortcut_scope_t get raw => c.native_shortcut_scope_t.fromValue(value);
}

class ShortcutOptions {
  const ShortcutOptions({required this.accelerator, this.callback, required this.description, required this.scope, required this.enabled, });

  final String? accelerator;
  final void Function()? callback;
  final String? description;
  final ShortcutScope scope;
  final bool enabled;

  factory ShortcutOptions.fromNative(c.native_shortcut_options_t raw) => ShortcutOptions(
    accelerator: raw.accelerator == ffi.nullptr ? null : raw.accelerator.cast<pkg_ffi.Utf8>().toDartString(),
    description: raw.description == ffi.nullptr ? null : raw.description.cast<pkg_ffi.Utf8>().toDartString(),
    scope: ShortcutScope.fromValue(raw.scope),
    enabled: raw.enabled,
  );

  /// Allocates the C form; free it with [freeNative].
  ffi.Pointer<c.native_shortcut_options_t> allocNative() {
    final pointer = pkg_ffi.calloc<c.native_shortcut_options_t>();
    pointer.ref.accelerator = accelerator == null
        ? ffi.nullptr
        : accelerator!.toNativeUtf8().cast<ffi.Char>();
    // Callback fields are installed by the caller; see the setters.
    pointer.ref.description = description == null
        ? ffi.nullptr
        : description!.toNativeUtf8().cast<ffi.Char>();
    pointer.ref.scope = scope.value;
    pointer.ref.enabled = enabled;
    return pointer;
  }

  static void freeNative(ffi.Pointer<c.native_shortcut_options_t> pointer) {
    if (pointer.ref.accelerator != ffi.nullptr) {
      pkg_ffi.calloc.free(pointer.ref.accelerator);
    }
    if (pointer.ref.description != ffi.nullptr) {
      pkg_ffi.calloc.free(pointer.ref.description);
    }
    pkg_ffi.calloc.free(pointer);
  }
}

/// One `ShortcutEvent`, in its concrete form.
sealed class ShortcutEvent {
  const ShortcutEvent();

  /// Reads the event out of its C form. Returns null for a variant this
  /// binding does not know about.
  static ShortcutEvent? fromNative(c.native_shortcut_event_t raw) {
    if (raw.type == c.native_shortcut_event_type_t.NATIVE_SHORTCUT_EVENT_TYPE_ACTIVATED.value) {
      return ShortcutActivatedEvent(shortcutId: raw.shortcut_id, accelerator: raw.accelerator == ffi.nullptr ? null : raw.accelerator.cast<pkg_ffi.Utf8>().toDartString());
    }
    if (raw.type == c.native_shortcut_event_type_t.NATIVE_SHORTCUT_EVENT_TYPE_REGISTERED.value) {
      return ShortcutRegisteredEvent(shortcutId: raw.shortcut_id, accelerator: raw.accelerator == ffi.nullptr ? null : raw.accelerator.cast<pkg_ffi.Utf8>().toDartString());
    }
    if (raw.type == c.native_shortcut_event_type_t.NATIVE_SHORTCUT_EVENT_TYPE_UNREGISTERED.value) {
      return ShortcutUnregisteredEvent(shortcutId: raw.shortcut_id, accelerator: raw.accelerator == ffi.nullptr ? null : raw.accelerator.cast<pkg_ffi.Utf8>().toDartString());
    }
    if (raw.type == c.native_shortcut_event_type_t.NATIVE_SHORTCUT_EVENT_TYPE_REGISTRATION_FAILED.value) {
      return ShortcutRegistrationFailedEvent(shortcutId: raw.shortcut_id, accelerator: raw.accelerator == ffi.nullptr ? null : raw.accelerator.cast<pkg_ffi.Utf8>().toDartString(), errorMessage: raw.data.registration_failed.error_message == ffi.nullptr ? null : raw.data.registration_failed.error_message.cast<pkg_ffi.Utf8>().toDartString());
    }
    return null;
  }
}

final class ShortcutActivatedEvent extends ShortcutEvent {
  const ShortcutActivatedEvent({required this.shortcutId, required this.accelerator, });

  final ShortcutId shortcutId;
  final String? accelerator;
}

final class ShortcutRegisteredEvent extends ShortcutEvent {
  const ShortcutRegisteredEvent({required this.shortcutId, required this.accelerator, });

  final ShortcutId shortcutId;
  final String? accelerator;
}

final class ShortcutUnregisteredEvent extends ShortcutEvent {
  const ShortcutUnregisteredEvent({required this.shortcutId, required this.accelerator, });

  final ShortcutId shortcutId;
  final String? accelerator;
}

final class ShortcutRegistrationFailedEvent extends ShortcutEvent {
  const ShortcutRegistrationFailedEvent({required this.shortcutId, required this.accelerator, required this.errorMessage, });

  final ShortcutId shortcutId;
  final String? accelerator;
  final String? errorMessage;
}

class Shortcut {
  /// Adopts a handle returned by the C API and releases it when this
  /// object becomes unreachable.
  Shortcut.fromHandle(this.nativeHandle) {
    _finalizer.attach(this, nativeHandle, detach: this);
  }

  /// Wraps a handle owned elsewhere; releasing it stays the owner's job.
  Shortcut.borrowed(this.nativeHandle);

  /// The underlying handle-table entry.
  final int nativeHandle;

  static final Finalizer<int> _finalizer = Finalizer<int>(
    (handle) => _bindings.native_shortcut_free(handle),
  );

  /// Releases the handle now instead of at collection.
  void dispose() {
    _finalizer.detach(this);
    _bindings.native_shortcut_free(nativeHandle);
  }

  /// Creates a new `Shortcut`; returns null if the native side failed.
  static Shortcut? createWithIdAndOptions(ShortcutId id, ShortcutOptions options) {
    final optionsPointer = options.allocNative();
    final handle = _bindings.native_shortcut_create_with_id_and_options(id, optionsPointer.ref);
    ShortcutOptions.freeNative(optionsPointer);
    if (handle == 0) return null;
    return Shortcut.fromHandle(handle);
  }

  /// Creates a new `Shortcut`; returns null if the native side failed.
  static Shortcut? createWithIdAndAcceleratorAndCallback(ShortcutId id, String accelerator, void Function() callback) {
    final acceleratorNative = accelerator.toNativeUtf8().cast<ffi.Char>();
    final callbackCallable = ffi.NativeCallable<
        ffi.Void Function(ffi.Pointer<ffi.Void>)>.isolateLocal(
      (ffi.Pointer<ffi.Void> _) {
        callback();
      },
    );
    _listeners.add(callbackCallable);
    final handle = _bindings.native_shortcut_create_with_id_and_accelerator_and_callback(id, acceleratorNative, callbackCallable.nativeFunction, ffi.nullptr);
    pkg_ffi.calloc.free(acceleratorNative);
    if (handle == 0) return null;
    return Shortcut.fromHandle(handle);
  }

  ShortcutId get id {
    return _bindings.native_shortcut_get_id(nativeHandle);
  }

  String? get accelerator {
    final resultPointer = _bindings.native_shortcut_get_accelerator(nativeHandle);
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }

  String? get description {
    final resultPointer = _bindings.native_shortcut_get_description(nativeHandle);
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }

  set description(String value) {
    final valueNative = value.toNativeUtf8().cast<ffi.Char>();
    _bindings.native_shortcut_set_description(nativeHandle, valueNative);
    pkg_ffi.calloc.free(valueNative);
  }

  ShortcutScope get scope {
    final raw = _bindings.native_shortcut_get_scope(nativeHandle);
    return ShortcutScope.fromValue(raw.value);
  }

  set isEnabled(bool value) {
    _bindings.native_shortcut_set_enabled(nativeHandle, value);
  }

  bool get isEnabled {
    return _bindings.native_shortcut_is_enabled(nativeHandle);
  }

  void invoke() {
    _bindings.native_shortcut_invoke(nativeHandle);
  }

  void setCallback(void Function() callback) {
    final callbackCallable = ffi.NativeCallable<
        ffi.Void Function(ffi.Pointer<ffi.Void>)>.isolateLocal(
      (ffi.Pointer<ffi.Void> _) {
        callback();
      },
    );
    _listeners.add(callbackCallable);
    _bindings.native_shortcut_set_callback(nativeHandle, callbackCallable.nativeFunction, ffi.nullptr);
  }

  /// Trampolines stay reachable for as long as the C side may call them.
  static final List<Object> _listeners = <Object>[];

}

