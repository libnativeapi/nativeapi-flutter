// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

import 'foundation/geometry.dart';

typedef DisplayId = int;

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

  c.native_display_orientation_t get raw =>
      c.native_display_orientation_t.fromValue(value);
}

/// One `DisplayEvent`, in its concrete form.
sealed class DisplayEvent {
  const DisplayEvent();

  Display get display;

  /// Reads the event out of its C form. Returns null for a variant this
  /// binding does not know about.
  static DisplayEvent? fromNative(c.native_display_event_t raw) {
    if (raw.typeAsInt ==
        c.native_display_event_type_t.NATIVE_DISPLAY_EVENT_TYPE_ADDED.value) {
      return DisplayAddedEvent(display: Display.borrowed(raw.display));
    }
    if (raw.typeAsInt ==
        c.native_display_event_type_t.NATIVE_DISPLAY_EVENT_TYPE_REMOVED.value) {
      return DisplayRemovedEvent(display: Display.borrowed(raw.display));
    }
    if (raw.typeAsInt ==
        c.native_display_event_type_t.NATIVE_DISPLAY_EVENT_TYPE_CHANGED.value) {
      return DisplayChangedEvent(display: Display.borrowed(raw.display));
    }
    return null;
  }
}

final class DisplayAddedEvent extends DisplayEvent {
  const DisplayAddedEvent({required this.display});

  @override
  final Display display;
}

final class DisplayRemovedEvent extends DisplayEvent {
  const DisplayRemovedEvent({required this.display});

  @override
  final Display display;
}

final class DisplayChangedEvent extends DisplayEvent {
  const DisplayChangedEvent({required this.display});

  @override
  final Display display;
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
    (handle) => c.native_display_free(handle),
  );

  /// Releases the handle now instead of at collection.
  void dispose() {
    _finalizer.detach(this);
    c.native_display_free(nativeHandle);
  }

  /// Creates a new `Display`; returns null if the native side failed.
  static Display? create(ffi.Pointer<ffi.Void> display) {
    final handle = c.native_display_create(display);
    if (handle == 0) return null;
    return Display.fromHandle(handle);
  }

  DisplayId get id {
    return c.native_display_get_id(nativeHandle);
  }

  String? get name {
    final resultPointer = c.native_display_get_name(nativeHandle);
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    c.free_c_str(resultPointer);
    return result;
  }

  Point get position {
    final raw = c.native_display_get_position(nativeHandle);
    return Point.fromNative(raw);
  }

  Size get size {
    final raw = c.native_display_get_size(nativeHandle);
    return Size.fromNative(raw);
  }

  Rectangle get workArea {
    final raw = c.native_display_get_work_area(nativeHandle);
    return Rectangle.fromNative(raw);
  }

  double get scaleFactor {
    return c.native_display_get_scale_factor(nativeHandle);
  }

  bool get isPrimary {
    return c.native_display_is_primary(nativeHandle);
  }

  DisplayOrientation get orientation {
    final raw = c.native_display_get_orientation(nativeHandle);
    return DisplayOrientation.fromValue(raw.value);
  }

  int get refreshRate {
    return c.native_display_get_refresh_rate(nativeHandle);
  }

  int get bitDepth {
    return c.native_display_get_bit_depth(nativeHandle);
  }

  /// Platform-specific native object behind this handle.
  ffi.Pointer<ffi.Void> get nativeObject =>
      c.native_display_get_native_object(nativeHandle);
}
