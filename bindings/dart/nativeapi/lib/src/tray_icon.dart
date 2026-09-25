// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

import 'foundation/geometry.dart';
import 'image.dart';
import 'menu.dart';

import 'support.dart';

import 'callbacks.dart';

typedef TrayIconId = int;

enum ContextMenuTrigger {
  none(0),
  clicked(1),
  rightClicked(2),
  doubleClicked(3);

  const ContextMenuTrigger(this.value);
  final int value;

  static ContextMenuTrigger fromValue(int value) => switch (value) {
    0 => ContextMenuTrigger.none,
    1 => ContextMenuTrigger.clicked,
    2 => ContextMenuTrigger.rightClicked,
    3 => ContextMenuTrigger.doubleClicked,
    _ => ContextMenuTrigger.none,
  };

  c.native_context_menu_trigger_t get raw =>
      c.native_context_menu_trigger_t.fromValue(value);
}

enum TrayIconPosition {
  left(0),
  right(1);

  const TrayIconPosition(this.value);
  final int value;

  static TrayIconPosition fromValue(int value) => switch (value) {
    0 => TrayIconPosition.left,
    1 => TrayIconPosition.right,
    _ => TrayIconPosition.left,
  };

  c.native_tray_icon_position_t get raw =>
      c.native_tray_icon_position_t.fromValue(value);
}

/// One `TrayIconEvent`, in its concrete form.
sealed class TrayIconEvent {
  const TrayIconEvent();

  /// Reads the event out of its C form. Returns null for a variant this
  /// binding does not know about.
  static TrayIconEvent? fromNative(c.native_tray_icon_event_t raw) {
    if (raw.typeAsInt ==
        c
            .native_tray_icon_event_type_t
            .NATIVE_TRAY_ICON_EVENT_TYPE_CLICKED
            .value) {
      return TrayIconClickedEvent(trayIconId: raw.data.clicked.tray_icon_id);
    }
    if (raw.typeAsInt ==
        c
            .native_tray_icon_event_type_t
            .NATIVE_TRAY_ICON_EVENT_TYPE_RIGHT_CLICKED
            .value) {
      return TrayIconRightClickedEvent(
        trayIconId: raw.data.right_clicked.tray_icon_id,
      );
    }
    if (raw.typeAsInt ==
        c
            .native_tray_icon_event_type_t
            .NATIVE_TRAY_ICON_EVENT_TYPE_DOUBLE_CLICKED
            .value) {
      return TrayIconDoubleClickedEvent(
        trayIconId: raw.data.double_clicked.tray_icon_id,
      );
    }
    return null;
  }
}

final class TrayIconClickedEvent extends TrayIconEvent {
  const TrayIconClickedEvent({required this.trayIconId});

  final TrayIconId trayIconId;
}

final class TrayIconRightClickedEvent extends TrayIconEvent {
  const TrayIconRightClickedEvent({required this.trayIconId});

  final TrayIconId trayIconId;
}

final class TrayIconDoubleClickedEvent extends TrayIconEvent {
  const TrayIconDoubleClickedEvent({required this.trayIconId});

  final TrayIconId trayIconId;
}

class TrayIcon {
  /// Adopts a handle returned by the C API and releases it when this
  /// object becomes unreachable.
  TrayIcon.fromHandle(this.nativeHandle) {
    _finalizer.attach(this, nativeHandle, detach: this);
  }

  /// Wraps a handle owned elsewhere; releasing it stays the owner's job.
  TrayIcon.borrowed(this.nativeHandle);

  /// The underlying handle-table entry.
  final int nativeHandle;

  static final Finalizer<int> _finalizer = Finalizer<int>(
    (handle) => c.native_tray_icon_free(handle),
  );

  /// Releases the handle now instead of at collection.
  void dispose() {
    _finalizer.detach(this);
    c.native_tray_icon_free(nativeHandle);
  }

  /// Creates a new `TrayIcon`; returns null if the native side failed.
  static TrayIcon? create() {
    final handle = c.native_tray_icon_create();
    if (handle == 0) return null;
    return TrayIcon.fromHandle(handle);
  }

  /// Creates a new `TrayIcon`; returns null if the native side failed.
  static TrayIcon? createWithTray(ffi.Pointer<ffi.Void> tray) {
    final handle = c.native_tray_icon_create_with_tray(tray);
    if (handle == 0) return null;
    return TrayIcon.fromHandle(handle);
  }

  TrayIconId getId() {
    return c.native_tray_icon_get_id(nativeHandle);
  }

  set icon(Image? value) {
    c.native_tray_icon_set_icon(nativeHandle, value?.nativeHandle ?? 0);
  }

  Image? get icon {
    final handle = c.native_tray_icon_get_icon(nativeHandle);
    if (handle == 0) return null;
    return Image.fromHandle(handle);
  }

  set isIconTemplate(bool value) {
    c.native_tray_icon_set_icon_template(nativeHandle, value);
  }

  bool get isIconTemplate {
    return c.native_tray_icon_is_icon_template(nativeHandle);
  }

  set iconSize(Size value) {
    final valuePointer = value.allocNative();
    c.native_tray_icon_set_icon_size(nativeHandle, valuePointer.ref);
    Size.freeNative(valuePointer);
  }

  Size get iconSize {
    final raw = c.native_tray_icon_get_icon_size(nativeHandle);
    return Size.fromNative(raw);
  }

  set iconPosition(TrayIconPosition value) {
    c.native_tray_icon_set_icon_position(nativeHandle, value.raw);
  }

  TrayIconPosition get iconPosition {
    final raw = c.native_tray_icon_get_icon_position(nativeHandle);
    return TrayIconPosition.fromValue(raw.value);
  }

  void setTitle(String? title) {
    final titleNative = title == null
        ? ffi.nullptr
        : title.toNativeUtf8().cast<ffi.Char>();
    c.native_tray_icon_set_title(nativeHandle, titleNative);
    if (titleNative != ffi.nullptr) pkg_ffi.calloc.free(titleNative);
  }

  String? getTitle() {
    final resultPointer = c.native_tray_icon_get_title(nativeHandle);
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    c.free_c_str(resultPointer);
    return result;
  }

  void setTooltip(String? tooltip) {
    final tooltipNative = tooltip == null
        ? ffi.nullptr
        : tooltip.toNativeUtf8().cast<ffi.Char>();
    c.native_tray_icon_set_tooltip(nativeHandle, tooltipNative);
    if (tooltipNative != ffi.nullptr) pkg_ffi.calloc.free(tooltipNative);
  }

  String? getTooltip() {
    final resultPointer = c.native_tray_icon_get_tooltip(nativeHandle);
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    c.free_c_str(resultPointer);
    return result;
  }

  void setContextMenu(Menu? menu) {
    c.native_tray_icon_set_context_menu(nativeHandle, menu?.nativeHandle ?? 0);
  }

  Menu? getContextMenu() {
    final handle = c.native_tray_icon_get_context_menu(nativeHandle);
    if (handle == 0) return null;
    return Menu.fromHandle(handle);
  }

  void setContextMenuTrigger(ContextMenuTrigger trigger) {
    c.native_tray_icon_set_context_menu_trigger(nativeHandle, trigger.raw);
  }

  ContextMenuTrigger getContextMenuTrigger() {
    final raw = c.native_tray_icon_get_context_menu_trigger(nativeHandle);
    return ContextMenuTrigger.fromValue(raw.value);
  }

  Rectangle getBounds() {
    final raw = c.native_tray_icon_get_bounds(nativeHandle);
    return Rectangle.fromNative(raw);
  }

  bool setVisible(bool visible) {
    return c.native_tray_icon_set_visible(nativeHandle, visible);
  }

  bool isVisible() {
    return c.native_tray_icon_is_visible(nativeHandle);
  }

  bool openContextMenu() {
    return c.native_tray_icon_open_context_menu(nativeHandle);
  }

  bool closeContextMenu() {
    return c.native_tray_icon_close_context_menu(nativeHandle);
  }

  /// Platform-specific native object behind this handle.
  ffi.Pointer<ffi.Void> get nativeObject =>
      c.native_tray_icon_get_native_object(nativeHandle);

  /// Registers [callback] for every `TrayIconEvent` this `TrayIcon` emits.
  ///
  /// The callback runs synchronously on whichever thread the native side
  /// dispatches from, because the event struct is freed as soon as it
  /// returns. That thread must therefore be this isolate's own; see the
  /// package README for what that means under Flutter.
  ListenerId addListener(void Function(TrayIconEvent) callback) {
    final callable =
        ffi.NativeCallable<
          ffi.Void Function(
            ffi.Pointer<c.native_tray_icon_event_t>,
            ffi.Pointer<ffi.Void>,
          )
        >.isolateLocal((
          ffi.Pointer<c.native_tray_icon_event_t> event,
          ffi.Pointer<ffi.Void> _,
        ) {
          if (event == ffi.nullptr) return;
          final value = TrayIconEvent.fromNative(event.ref);
          if (value != null) callback(value);
        });
    return c.native_tray_icon_add_listener(
      nativeHandle,
      callable.nativeFunction,
      NativeCallbacks.userData(callable),
      NativeCallbacks.release,
    );
  }

  /// Unregisters a listener. Returns false if unknown.
  bool removeListener(ListenerId listenerId) =>
      c.native_tray_icon_remove_listener(nativeHandle, listenerId);
}
