// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;
import 'dart:ui';

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

import 'foundation/geometry.dart';

final _bindings = c.cnativeApiBindings;

enum DisplayOrientation {
  portrait(0),
  landscape(90),
  portraitFlipped(180),
  landscapeFlipped(270);

  const DisplayOrientation(this.value);
  final int value;

  static DisplayOrientation fromValue(int value) => switch (value) {
    0 => DisplayOrientation.portrait,
    90 => DisplayOrientation.landscape,
    180 => DisplayOrientation.portraitFlipped,
    270 => DisplayOrientation.landscapeFlipped,
    _ => DisplayOrientation.portrait,
  };

  c.native_display_orientation_t get raw => c.native_display_orientation_t.fromValue(value);
}

/// One `DisplayEvent`, in its concrete form.
sealed class DisplayEvent {
  const DisplayEvent();

  /// Reads the event out of its C form. Returns null for a variant this
  /// binding does not know about.
  static DisplayEvent? fromNative(c.native_display_event_t raw) {
    if (raw.type == c.native_display_event_type_t.NATIVE_DISPLAY_EVENT_TYPE_ADDED.value) {
      return DisplayAddedEvent(display: Display.borrowed(raw.display));
    }
    if (raw.type == c.native_display_event_type_t.NATIVE_DISPLAY_EVENT_TYPE_REMOVED.value) {
      return DisplayRemovedEvent(display: Display.borrowed(raw.display));
    }
    if (raw.type == c.native_display_event_type_t.NATIVE_DISPLAY_EVENT_TYPE_CHANGED.value) {
      return DisplayChangedEvent(display: Display.borrowed(raw.display), oldDisplay: Display.borrowed(raw.data.changed.old_display), newDisplay: Display.borrowed(raw.data.changed.new_display));
    }
    return null;
  }
}

final class DisplayAddedEvent extends DisplayEvent {
  const DisplayAddedEvent({required this.display, });

  final Display display;
}

final class DisplayRemovedEvent extends DisplayEvent {
  const DisplayRemovedEvent({required this.display, });

  final Display display;
}

final class DisplayChangedEvent extends DisplayEvent {
  const DisplayChangedEvent({required this.display, required this.oldDisplay, required this.newDisplay, });

  final Display display;
  final Display oldDisplay;
  final Display newDisplay;
}

class Display {
  /// Adopts a handle returned by the C API and releases it when this
  /// object becomes unreachable.
  Display.fromHandle(this.nativeHandle) {
    _finalizer.attach(this, nativeHandle, detach: this);
  }

  /// Wraps a handle owned elsewhere; releasing it stays the owner's job.
  Display.borrowed(this.nativeHandle);

  /// The underlying handle-table entry.
  final int nativeHandle;

  static final Finalizer<int> _finalizer = Finalizer<int>(
    (handle) => _bindings.native_display_free(handle),
  );

  /// Releases the handle now instead of at collection.
  void dispose() {
    _finalizer.detach(this);
    _bindings.native_display_free(nativeHandle);
  }

  /// Creates a new `Display`; returns null if the native side failed.
  static Display? create() {
    final handle = _bindings.native_display_create();
    if (handle == 0) return null;
    return Display.fromHandle(handle);
  }

  /// Creates a new `Display`; returns null if the native side failed.
  static Display? createWithDisplay(ffi.Pointer<ffi.Void> display) {
    final handle = _bindings.native_display_create_with_display(display);
    if (handle == 0) return null;
    return Display.fromHandle(handle);
  }

  String? get id {
    final resultPointer = _bindings.native_display_get_id(nativeHandle);
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }

  String? get name {
    final resultPointer = _bindings.native_display_get_name(nativeHandle);
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }

  Offset get position {
    final raw = _bindings.native_display_get_position(nativeHandle);
    return Offset(raw.x, raw.y);
  }

  Size get size {
    final raw = _bindings.native_display_get_size(nativeHandle);
    return Size(raw.width, raw.height);
  }

  Rect get workArea {
    final raw = _bindings.native_display_get_work_area(nativeHandle);
    return Rect.fromLTWH(raw.x, raw.y, raw.width, raw.height);
  }

  double get scaleFactor {
    return _bindings.native_display_get_scale_factor(nativeHandle);
  }

  bool get isPrimary {
    return _bindings.native_display_is_primary(nativeHandle);
  }

  DisplayOrientation get orientation {
    final raw = _bindings.native_display_get_orientation(nativeHandle);
    return DisplayOrientation.fromValue(raw.value);
  }

  int get refreshRate {
    return _bindings.native_display_get_refresh_rate(nativeHandle);
  }

  int get bitDepth {
    return _bindings.native_display_get_bit_depth(nativeHandle);
  }

  /// Platform-specific native object behind this handle.
  ffi.Pointer<ffi.Void> get nativeObject =>
      _bindings.native_display_get_native_object(nativeHandle);

}

