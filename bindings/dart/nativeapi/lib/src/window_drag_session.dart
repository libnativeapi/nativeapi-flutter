// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

import 'foundation/geometry.dart';
import 'window.dart';

import 'support.dart';

import 'callbacks.dart';

/// One `WindowDragEvent`, in its concrete form.
sealed class WindowDragEvent {
  const WindowDragEvent();

  WindowId get windowId;
  Point get cursorPosition;

  /// Reads the event out of its C form. Returns null for a variant this
  /// binding does not know about.
  static WindowDragEvent? fromNative(c.native_window_drag_event_t raw) {
    if (raw.typeAsInt ==
        c
            .native_window_drag_event_type_t
            .NATIVE_WINDOW_DRAG_EVENT_TYPE_MOVED
            .value) {
      return WindowDragMovedEvent(
        windowId: raw.window_id,
        cursorPosition: Point.fromNative(raw.cursor_position),
      );
    }
    if (raw.typeAsInt ==
        c
            .native_window_drag_event_type_t
            .NATIVE_WINDOW_DRAG_EVENT_TYPE_ENDED
            .value) {
      return WindowDragEndedEvent(
        windowId: raw.window_id,
        cursorPosition: Point.fromNative(raw.cursor_position),
      );
    }
    if (raw.typeAsInt ==
        c
            .native_window_drag_event_type_t
            .NATIVE_WINDOW_DRAG_EVENT_TYPE_CANCELLED
            .value) {
      return WindowDragCancelledEvent(
        windowId: raw.window_id,
        cursorPosition: Point.fromNative(raw.cursor_position),
      );
    }
    return null;
  }
}

final class WindowDragMovedEvent extends WindowDragEvent {
  const WindowDragMovedEvent({
    required this.windowId,
    required this.cursorPosition,
  });

  @override
  final WindowId windowId;
  @override
  final Point cursorPosition;
}

final class WindowDragEndedEvent extends WindowDragEvent {
  const WindowDragEndedEvent({
    required this.windowId,
    required this.cursorPosition,
  });

  @override
  final WindowId windowId;
  @override
  final Point cursorPosition;
}

final class WindowDragCancelledEvent extends WindowDragEvent {
  const WindowDragCancelledEvent({
    required this.windowId,
    required this.cursorPosition,
  });

  @override
  final WindowId windowId;
  @override
  final Point cursorPosition;
}

class WindowDragSession {
  /// Adopts a handle returned by the C API and releases it when this
  /// object becomes unreachable.
  WindowDragSession.fromHandle(this.nativeHandle) {
    _finalizer.attach(this, nativeHandle, detach: this);
  }

  /// Wraps a handle owned elsewhere; releasing it stays the owner's job.
  WindowDragSession.borrowed(this.nativeHandle);

  /// The underlying handle-table entry.
  final int nativeHandle;

  static final Finalizer<int> _finalizer = Finalizer<int>(
    (handle) => c.native_window_drag_session_free(handle),
  );

  /// Releases the handle now instead of at collection.
  void dispose() {
    _finalizer.detach(this);
    c.native_window_drag_session_free(nativeHandle);
  }

  /// Creates a new `WindowDragSession`; returns null if the native side failed.
  static WindowDragSession? create() {
    final handle = c.native_window_drag_session_create();
    if (handle == 0) return null;
    return WindowDragSession.fromHandle(handle);
  }

  bool start(Window? window, Point anchor) {
    final anchorPointer = anchor.allocNative();
    final result = c.native_window_drag_session_start(
      nativeHandle,
      window?.nativeHandle ?? 0,
      anchorPointer.ref,
    );
    Point.freeNative(anchorPointer);
    return result;
  }

  void cancel() {
    c.native_window_drag_session_cancel(nativeHandle);
  }

  bool get isActive {
    return c.native_window_drag_session_is_active(nativeHandle);
  }

  WindowId get windowId {
    return c.native_window_drag_session_get_window_id(nativeHandle);
  }

  Point get anchor {
    final raw = c.native_window_drag_session_get_anchor(nativeHandle);
    return Point.fromNative(raw);
  }

  /// Registers [callback] for every `WindowDragEvent` this `WindowDragSession` emits.
  ///
  /// The callback runs synchronously on whichever thread the native side
  /// dispatches from, because the event struct is freed as soon as it
  /// returns. That thread must therefore be this isolate's own; see the
  /// package README for what that means under Flutter.
  ListenerId addListener(void Function(WindowDragEvent) callback) {
    final callable =
        ffi.NativeCallable<
          ffi.Void Function(
            ffi.Pointer<c.native_window_drag_event_t>,
            ffi.Pointer<ffi.Void>,
          )
        >.isolateLocal((
          ffi.Pointer<c.native_window_drag_event_t> event,
          ffi.Pointer<ffi.Void> _,
        ) {
          if (event == ffi.nullptr) return;
          final value = WindowDragEvent.fromNative(event.ref);
          if (value != null) callback(value);
        });
    return c.native_window_drag_session_add_listener(
      nativeHandle,
      callable.nativeFunction,
      NativeCallbacks.userData(callable),
      NativeCallbacks.release,
    );
  }

  /// Unregisters a listener. Returns false if unknown.
  bool removeListener(ListenerId listenerId) =>
      c.native_window_drag_session_remove_listener(nativeHandle, listenerId);
}
