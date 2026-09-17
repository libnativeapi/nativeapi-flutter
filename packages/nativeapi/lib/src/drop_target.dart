// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;
import 'dart:ui';

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

import 'drag_source.dart';
import 'foundation/geometry.dart';
import 'window.dart';

import 'support.dart';

final _bindings = c.cnativeApiBindings;

/// One `DropTargetEvent`, in its concrete form.
sealed class DropTargetEvent {
  const DropTargetEvent();

  /// Reads the event out of its C form. Returns null for a variant this
  /// binding does not know about.
  static DropTargetEvent? fromNative(c.native_drop_target_event_t raw) {
    if (raw.type ==
        c
            .native_drop_target_event_type_t
            .NATIVE_DROP_TARGET_EVENT_TYPE_ENTERED
            .value) {
      return DropTargetEnteredEvent(
        windowId: raw.window_id,
        position: Offset(raw.position.x, raw.position.y),
      );
    }
    if (raw.type ==
        c
            .native_drop_target_event_type_t
            .NATIVE_DROP_TARGET_EVENT_TYPE_MOVED
            .value) {
      return DropTargetMovedEvent(
        windowId: raw.window_id,
        position: Offset(raw.position.x, raw.position.y),
      );
    }
    if (raw.type ==
        c
            .native_drop_target_event_type_t
            .NATIVE_DROP_TARGET_EVENT_TYPE_EXITED
            .value) {
      return DropTargetExitedEvent(
        windowId: raw.window_id,
        position: Offset(raw.position.x, raw.position.y),
      );
    }
    if (raw.type ==
        c
            .native_drop_target_event_type_t
            .NATIVE_DROP_TARGET_EVENT_TYPE_DROPPED
            .value) {
      return DropTargetDroppedEvent(
        windowId: raw.window_id,
        position: Offset(raw.position.x, raw.position.y),
        filePaths: [
          for (var i = 0; i < raw.data.dropped.file_paths.count; i++)
            if (raw.data.dropped.file_paths.items[i] != ffi.nullptr)
              raw.data.dropped.file_paths.items[i]
                  .cast<pkg_ffi.Utf8>()
                  .toDartString(),
        ],
        text: raw.data.dropped.text == ffi.nullptr
            ? null
            : raw.data.dropped.text.cast<pkg_ffi.Utf8>().toDartString(),
      );
    }
    return null;
  }
}

final class DropTargetEnteredEvent extends DropTargetEvent {
  const DropTargetEnteredEvent({
    required this.windowId,
    required this.position,
  });

  final WindowId windowId;
  final Offset position;
}

final class DropTargetMovedEvent extends DropTargetEvent {
  const DropTargetMovedEvent({required this.windowId, required this.position});

  final WindowId windowId;
  final Offset position;
}

final class DropTargetExitedEvent extends DropTargetEvent {
  const DropTargetExitedEvent({required this.windowId, required this.position});

  final WindowId windowId;
  final Offset position;
}

final class DropTargetDroppedEvent extends DropTargetEvent {
  const DropTargetDroppedEvent({
    required this.windowId,
    required this.position,
    required this.filePaths,
    required this.text,
  });

  final WindowId windowId;
  final Offset position;
  final List<String> filePaths;
  final String? text;
}

class DropTarget {
  /// Adopts a handle returned by the C API and releases it when this
  /// object becomes unreachable.
  DropTarget.fromHandle(this.nativeHandle) {
    _finalizer.attach(this, nativeHandle, detach: this);
  }

  /// Wraps a handle owned elsewhere; releasing it stays the owner's job.
  DropTarget.borrowed(this.nativeHandle);

  /// The underlying handle-table entry.
  final int nativeHandle;

  static final Finalizer<int> _finalizer = Finalizer<int>(
    (handle) => _bindings.native_drop_target_free(handle),
  );

  /// Releases the handle now instead of at collection.
  void dispose() {
    _finalizer.detach(this);
    _bindings.native_drop_target_free(nativeHandle);
  }

  /// Creates a new `DropTarget`; returns null if the native side failed.
  static DropTarget? create(Window? window) {
    final handle = _bindings.native_drop_target_create(
      window?.nativeHandle ?? 0,
    );
    if (handle == 0) return null;
    return DropTarget.fromHandle(handle);
  }

  static bool isSupported() {
    return _bindings.native_drop_target_is_supported();
  }

  WindowId get windowId {
    return _bindings.native_drop_target_get_window_id(nativeHandle);
  }

  set dropOperation(DragOperation value) {
    _bindings.native_drop_target_set_drop_operation(nativeHandle, value.raw);
  }

  DragOperation get dropOperation {
    final raw = _bindings.native_drop_target_get_drop_operation(nativeHandle);
    return DragOperation.fromValue(raw.value);
  }

  bool get isActive {
    return _bindings.native_drop_target_is_active(nativeHandle);
  }

  /// Registers [callback] for every `DropTargetEvent` this `DropTarget` emits.
  ///
  /// The callback runs synchronously on whichever thread the native side
  /// dispatches from, because the event struct is freed as soon as it
  /// returns. That thread must therefore be this isolate's own; see the
  /// package README for what that means under Flutter.
  ListenerId addListener(void Function(DropTargetEvent) callback) {
    final callable =
        ffi.NativeCallable<
          ffi.Void Function(
            ffi.Pointer<c.native_drop_target_event_t>,
            ffi.Pointer<ffi.Void>,
          )
        >.isolateLocal((
          ffi.Pointer<c.native_drop_target_event_t> event,
          ffi.Pointer<ffi.Void> _,
        ) {
          if (event == ffi.nullptr) return;
          final value = DropTargetEvent.fromNative(event.ref);
          if (value != null) callback(value);
        });
    _listeners.add(callable); // keeps the trampoline alive
    return _bindings.native_drop_target_add_listener(
      nativeHandle,
      callable.nativeFunction,
      ffi.nullptr,
    );
  }

  /// Unregisters a listener. Returns false if unknown.
  bool removeListener(ListenerId listenerId) =>
      _bindings.native_drop_target_remove_listener(nativeHandle, listenerId);

  /// Trampolines stay reachable for as long as the C side may call them.
  static final List<Object> _listeners = <Object>[];
}
