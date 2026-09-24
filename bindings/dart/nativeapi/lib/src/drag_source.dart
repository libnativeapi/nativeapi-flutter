// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

import 'foundation/geometry.dart';
import 'image.dart';
import 'window.dart';

import 'support.dart';

enum DragOperation {
  none(0),
  copy(1),
  move(2),
  link(3);

  const DragOperation(this.value);
  final int value;

  static DragOperation fromValue(int value) => switch (value) {
    0 => DragOperation.none,
    1 => DragOperation.copy,
    2 => DragOperation.move,
    3 => DragOperation.link,
    _ => DragOperation.none,
  };

  c.native_drag_operation_t get raw =>
      c.native_drag_operation_t.fromValue(value);
}

/// One `DragSourceEvent`, in its concrete form.
sealed class DragSourceEvent {
  const DragSourceEvent();

  WindowId get windowId;
  Point get position;

  /// Reads the event out of its C form. Returns null for a variant this
  /// binding does not know about.
  static DragSourceEvent? fromNative(c.native_drag_source_event_t raw) {
    if (raw.typeAsInt ==
        c
            .native_drag_source_event_type_t
            .NATIVE_DRAG_SOURCE_EVENT_TYPE_ENDED
            .value) {
      return DragSourceEndedEvent(
        windowId: raw.window_id,
        position: Point.fromNative(raw.position),
        operation: DragOperation.fromValue(raw.data.ended.operationAsInt),
      );
    }
    return null;
  }
}

final class DragSourceEndedEvent extends DragSourceEvent {
  const DragSourceEndedEvent({
    required this.windowId,
    required this.position,
    required this.operation,
  });

  @override
  final WindowId windowId;
  @override
  final Point position;
  final DragOperation operation;
}

class DragSource {
  /// Adopts a handle returned by the C API and releases it when this
  /// object becomes unreachable.
  DragSource.fromHandle(this.nativeHandle) {
    _finalizer.attach(this, nativeHandle, detach: this);
  }

  /// Wraps a handle owned elsewhere; releasing it stays the owner's job.
  DragSource.borrowed(this.nativeHandle);

  /// The underlying handle-table entry.
  final int nativeHandle;

  static final Finalizer<int> _finalizer = Finalizer<int>(
    (handle) => c.native_drag_source_free(handle),
  );

  /// Releases the handle now instead of at collection.
  void dispose() {
    _finalizer.detach(this);
    c.native_drag_source_free(nativeHandle);
  }

  /// Creates a new `DragSource`; returns null if the native side failed.
  static DragSource? create() {
    final handle = c.native_drag_source_create();
    if (handle == 0) return null;
    return DragSource.fromHandle(handle);
  }

  static bool isSupported() {
    return c.native_drag_source_is_supported();
  }

  set filePaths(List<String> value) {
    final valueItems = pkg_ffi.calloc<ffi.Pointer<ffi.Char>>(value.length);
    for (var i = 0; i < value.length; i++) {
      valueItems[i] = value[i].toNativeUtf8().cast<ffi.Char>();
    }
    final valueList = pkg_ffi.calloc<c.native_string_list_t>();
    valueList.ref.items = valueItems;
    valueList.ref.count = value.length;
    c.native_drag_source_set_file_paths(nativeHandle, valueList.ref);
    for (var i = 0; i < value.length; i++) {
      pkg_ffi.calloc.free(valueItems[i]);
    }
    pkg_ffi.calloc.free(valueItems);
    pkg_ffi.calloc.free(valueList);
  }

  List<String> get filePaths {
    final list = c.native_drag_source_get_file_paths(nativeHandle);
    final items = <String>[];
    for (var i = 0; i < list.count; i++) {
      final item = list.items[i];
      if (item == ffi.nullptr) continue;
      items.add(item.cast<pkg_ffi.Utf8>().toDartString());
    }
    final listPointer = pkg_ffi.calloc<c.native_string_list_t>();
    listPointer.ref = list;
    c.native_string_list_free(listPointer);
    pkg_ffi.calloc.free(listPointer);
    return items;
  }

  set text(String? value) {
    final valueNative = value == null
        ? ffi.nullptr
        : value.toNativeUtf8().cast<ffi.Char>();
    c.native_drag_source_set_text(nativeHandle, valueNative);
    if (valueNative != ffi.nullptr) pkg_ffi.calloc.free(valueNative);
  }

  String? get text {
    final resultPointer = c.native_drag_source_get_text(nativeHandle);
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    c.free_c_str(resultPointer);
    return result;
  }

  set image(Image? value) {
    c.native_drag_source_set_image(nativeHandle, value?.nativeHandle ?? 0);
  }

  Image? get image {
    final handle = c.native_drag_source_get_image(nativeHandle);
    if (handle == 0) return null;
    return Image.fromHandle(handle);
  }

  set dragOperation(DragOperation value) {
    c.native_drag_source_set_drag_operation(nativeHandle, value.raw);
  }

  DragOperation get dragOperation {
    final raw = c.native_drag_source_get_drag_operation(nativeHandle);
    return DragOperation.fromValue(raw.value);
  }

  bool startDragging(Window? window) {
    return c.native_drag_source_start_dragging(
      nativeHandle,
      window?.nativeHandle ?? 0,
    );
  }

  bool get isDragging {
    return c.native_drag_source_is_dragging(nativeHandle);
  }

  /// Registers [callback] for every `DragSourceEvent` this `DragSource` emits.
  ///
  /// The callback runs synchronously on whichever thread the native side
  /// dispatches from, because the event struct is freed as soon as it
  /// returns. That thread must therefore be this isolate's own; see the
  /// package README for what that means under Flutter.
  ListenerId addListener(void Function(DragSourceEvent) callback) {
    final callable =
        ffi.NativeCallable<
          ffi.Void Function(
            ffi.Pointer<c.native_drag_source_event_t>,
            ffi.Pointer<ffi.Void>,
          )
        >.isolateLocal((
          ffi.Pointer<c.native_drag_source_event_t> event,
          ffi.Pointer<ffi.Void> _,
        ) {
          if (event == ffi.nullptr) return;
          final value = DragSourceEvent.fromNative(event.ref);
          if (value != null) callback(value);
        });
    _listeners.add(callable); // keeps the trampoline alive
    return c.native_drag_source_add_listener(
      nativeHandle,
      callable.nativeFunction,
      ffi.nullptr,
    );
  }

  /// Unregisters a listener. Returns false if unknown.
  bool removeListener(ListenerId listenerId) =>
      c.native_drag_source_remove_listener(nativeHandle, listenerId);

  /// Trampolines stay reachable for as long as the C side may call them.
  static final List<Object> _listeners = <Object>[];
}
