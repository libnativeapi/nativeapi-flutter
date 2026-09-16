// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;
import 'dart:ui';

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

import 'foundation/geometry.dart';
import 'window.dart';

import 'support.dart';

final _bindings = c.cnativeApiBindings;

/// One `WindowDragEvent`, in its concrete form.
sealed class WindowDragEvent {
  const WindowDragEvent();

  /// Reads the event out of its C form. Returns null for a variant this
  /// binding does not know about.
  static WindowDragEvent? fromNative(c.native_window_drag_event_t raw) {
    if (raw.type ==
        c
            .native_window_drag_event_type_t
            .NATIVE_WINDOW_DRAG_EVENT_TYPE_MOVED
            .value) {
      return WindowDragMovedEvent(
        windowId: raw.window_id,
        cursorPosition: Offset(raw.cursor_position.x, raw.cursor_position.y),
      );
    }
    if (raw.type ==
        c
            .native_window_drag_event_type_t
            .NATIVE_WINDOW_DRAG_EVENT_TYPE_ENDED
            .value) {
      return WindowDragEndedEvent(
        windowId: raw.window_id,
        cursorPosition: Offset(raw.cursor_position.x, raw.cursor_position.y),
      );
    }
    if (raw.type ==
        c
            .native_window_drag_event_type_t
            .NATIVE_WINDOW_DRAG_EVENT_TYPE_CANCELLED
            .value) {
      return WindowDragCancelledEvent(
        windowId: raw.window_id,
        cursorPosition: Offset(raw.cursor_position.x, raw.cursor_position.y),
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

  final WindowId windowId;
  final Offset cursorPosition;
}

final class WindowDragEndedEvent extends WindowDragEvent {
  const WindowDragEndedEvent({
    required this.windowId,
    required this.cursorPosition,
  });

  final WindowId windowId;
  final Offset cursorPosition;
}

final class WindowDragCancelledEvent extends WindowDragEvent {
  const WindowDragCancelledEvent({
    required this.windowId,
    required this.cursorPosition,
  });

  final WindowId windowId;
  final Offset cursorPosition;
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
    (handle) => _bindings.native_window_drag_session_free(handle),
  );

  /// Releases the handle now instead of at collection.
  void dispose() {
    _finalizer.detach(this);
    _bindings.native_window_drag_session_free(nativeHandle);
  }

  /// Creates a new `WindowDragSession`; returns null if the native side failed.
  static WindowDragSession? create() {
    final handle = _bindings.native_window_drag_session_create();
    if (handle == 0) return null;
    return WindowDragSession.fromHandle(handle);
  }

  bool start(Window? window, Offset anchor) {
    final anchorPointer = pkg_ffi.calloc<c.native_point_t>();
    anchorPointer.ref.x = anchor.dx;
    anchorPointer.ref.y = anchor.dy;
    final result = _bindings.native_window_drag_session_start(
      nativeHandle,
      window?.nativeHandle ?? 0,
      anchorPointer.ref,
    );
    pkg_ffi.calloc.free(anchorPointer);
    return result;
  }

  void cancel() {
    _bindings.native_window_drag_session_cancel(nativeHandle);
  }

  bool get isActive {
    return _bindings.native_window_drag_session_is_active(nativeHandle);
  }

  WindowId get windowId {
    return _bindings.native_window_drag_session_get_window_id(nativeHandle);
  }

  Offset get anchor {
    final raw = _bindings.native_window_drag_session_get_anchor(nativeHandle);
    return Offset(raw.x, raw.y);
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
    _listeners.add(callable); // keeps the trampoline alive
    return _bindings.native_window_drag_session_add_listener(
      nativeHandle,
      callable.nativeFunction,
      ffi.nullptr,
    );
  }

  /// Unregisters a listener. Returns false if unknown.
  bool removeListener(ListenerId listenerId) => _bindings
      .native_window_drag_session_remove_listener(nativeHandle, listenerId);

  /// Trampolines stay reachable for as long as the C side may call them.
  static final List<Object> _listeners = <Object>[];
}
