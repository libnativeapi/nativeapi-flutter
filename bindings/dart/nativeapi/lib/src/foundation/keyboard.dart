// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

enum ModifierKey {
  none(0),
  shift(1),
  ctrl(2),
  alt(4),
  meta(8),
  fn(16),
  capsLock(32),
  numLock(64),
  scrollLock(128);

  const ModifierKey(this.value);
  final int value;

  static ModifierKey fromValue(int value) => switch (value) {
    0 => ModifierKey.none,
    1 => ModifierKey.shift,
    2 => ModifierKey.ctrl,
    4 => ModifierKey.alt,
    8 => ModifierKey.meta,
    16 => ModifierKey.fn,
    32 => ModifierKey.capsLock,
    64 => ModifierKey.numLock,
    128 => ModifierKey.scrollLock,
    _ => ModifierKey.none,
  };

  c.native_modifier_key_t get raw => c.native_modifier_key_t.fromValue(value);
}

class KeyboardAccelerator {
  const KeyboardAccelerator({required this.modifiers, required this.key});

  final ModifierKey modifiers;
  final String? key;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyboardAccelerator &&
          other.modifiers == modifiers &&
          other.key == key);

  @override
  int get hashCode => Object.hash(modifiers, key);

  @override
  String toString() => 'KeyboardAccelerator(modifiers: $modifiers, key: $key)';

  factory KeyboardAccelerator.fromNative(c.native_keyboard_accelerator_t raw) =>
      KeyboardAccelerator(
        modifiers: ModifierKey.fromValue(raw.modifiersAsInt),
        key: raw.key == ffi.nullptr
            ? null
            : raw.key.cast<pkg_ffi.Utf8>().toDartString(),
      );

  /// Allocates the C form; free it with [freeNative].
  ffi.Pointer<c.native_keyboard_accelerator_t> allocNative() {
    final pointer = pkg_ffi.calloc<c.native_keyboard_accelerator_t>();
    pointer.ref.modifiersAsInt = modifiers.value;
    pointer.ref.key = key == null
        ? ffi.nullptr
        : key!.toNativeUtf8().cast<ffi.Char>();
    return pointer;
  }

  static void freeNative(ffi.Pointer<c.native_keyboard_accelerator_t> pointer) {
    if (pointer.ref.key != ffi.nullptr) {
      pkg_ffi.calloc.free(pointer.ref.key);
    }
    pkg_ffi.calloc.free(pointer);
  }
}

/// One `KeyboardEvent`, in its concrete form.
sealed class KeyboardEvent {
  const KeyboardEvent();

  int get keycode;

  /// Reads the event out of its C form. Returns null for a variant this
  /// binding does not know about.
  static KeyboardEvent? fromNative(c.native_keyboard_event_t raw) {
    if (raw.typeAsInt ==
        c
            .native_keyboard_event_type_t
            .NATIVE_KEYBOARD_EVENT_TYPE_KEY_PRESSED
            .value) {
      return KeyPressedEvent(keycode: raw.keycode);
    }
    if (raw.typeAsInt ==
        c
            .native_keyboard_event_type_t
            .NATIVE_KEYBOARD_EVENT_TYPE_KEY_RELEASED
            .value) {
      return KeyReleasedEvent(keycode: raw.keycode);
    }
    if (raw.typeAsInt ==
        c
            .native_keyboard_event_type_t
            .NATIVE_KEYBOARD_EVENT_TYPE_MODIFIER_KEYS_CHANGED
            .value) {
      return ModifierKeysChangedEvent(
        keycode: raw.keycode,
        modifierKeys: raw.data.modifier_keys_changed.modifier_keys,
      );
    }
    return null;
  }
}

final class KeyPressedEvent extends KeyboardEvent {
  const KeyPressedEvent({required this.keycode});

  @override
  final int keycode;
}

final class KeyReleasedEvent extends KeyboardEvent {
  const KeyReleasedEvent({required this.keycode});

  @override
  final int keycode;
}

final class ModifierKeysChangedEvent extends KeyboardEvent {
  const ModifierKeysChangedEvent({
    required this.keycode,
    required this.modifierKeys,
  });

  @override
  final int keycode;
  final int modifierKeys;
}
