import 'dart:ffi';
import 'package:cnativeapi/cnativeapi.dart';
import 'package:ffi/ffi.dart' as ffi;

import 'menu.dart';

typedef TrayIconClickedCallback = void Function(String button);
typedef TrayIconDoubleClickedCallback = void Function();
typedef TrayIconRightClickedCallback = void Function();

class TrayIconBounds {
  const TrayIconBounds({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;

  @override
  String toString() =>
      'TrayIconBounds(x: $x, y: $y, width: $width, height: $height)';
}

class TrayIcon {
  TrayIcon._internal(this._handle, this._id);

  TrayIcon(native_tray_icon_t handle)
    : _handle = handle,
      _id = cnativeApiBindings.native_tray_icon_get_id(handle);

  static TrayIcon? create() {
    final handle = cnativeApiBindings.native_tray_icon_create();
    if (handle == nullptr) {
      return null;
    }
    final id = cnativeApiBindings.native_tray_icon_get_id(handle);
    return TrayIcon._internal(handle, id);
  }

  static TrayIcon? createFromNative(Pointer<Void> nativeTray) {
    final handle = cnativeApiBindings.native_tray_icon_create_from_native(
      nativeTray,
    );
    if (handle == nullptr) {
      return null;
    }
    final id = cnativeApiBindings.native_tray_icon_get_id(handle);
    return TrayIcon._internal(handle, id);
  }

  final native_tray_icon_t _handle;
  final int _id;
  final Map<native_tray_icon_event_type_t, int> _listeners = {};

  TrayIconClickedCallback? onClicked;
  TrayIconDoubleClickedCallback? onDoubleClicked;
  TrayIconRightClickedCallback? onRightClicked;

  int get id => _id;

  void setIcon(String iconPath) {
    final iconPtr = iconPath.toNativeUtf8().cast<Char>();
    cnativeApiBindings.native_tray_icon_set_icon(_handle, iconPtr);
    ffi.calloc.free(iconPtr);
  }

  void setTitle(String title) {
    final titlePtr = title.toNativeUtf8().cast<Char>();
    cnativeApiBindings.native_tray_icon_set_title(_handle, titlePtr);
    ffi.calloc.free(titlePtr);
  }

  String? getTitle() {
    const bufferSize = 256;
    final buffer = ffi.calloc.allocate<Char>(bufferSize);
    final length = cnativeApiBindings.native_tray_icon_get_title(
      _handle,
      buffer,
      bufferSize,
    );

    if (length < 0) {
      ffi.calloc.free(buffer);
      return null;
    }

    final result = buffer.cast<ffi.Utf8>().toDartString();
    ffi.calloc.free(buffer);
    return result;
  }

  void setTooltip(String tooltip) {
    final tooltipPtr = tooltip.toNativeUtf8().cast<Char>();
    cnativeApiBindings.native_tray_icon_set_tooltip(_handle, tooltipPtr);
    ffi.calloc.free(tooltipPtr);
  }

  String? getTooltip() {
    const bufferSize = 256;
    final buffer = ffi.calloc.allocate<Char>(bufferSize);
    final length = cnativeApiBindings.native_tray_icon_get_tooltip(
      _handle,
      buffer,
      bufferSize,
    );

    if (length < 0) {
      ffi.calloc.free(buffer);
      return null;
    }

    final result = buffer.cast<ffi.Utf8>().toDartString();
    ffi.calloc.free(buffer);
    return result;
  }

  void setContextMenu(Menu? menu) {
    if (menu != null) {
      cnativeApiBindings.native_tray_icon_set_context_menu(
        _handle,
        menu.handle,
      );
    } else {
      cnativeApiBindings.native_tray_icon_set_context_menu(_handle, nullptr);
    }
  }

  Menu? getContextMenu() {
    final menuHandle = cnativeApiBindings.native_tray_icon_get_context_menu(
      _handle,
    );
    if (menuHandle == nullptr) {
      return null;
    }
    // return Menu(menuHandle);
  }

  TrayIconBounds? getBounds() {
    final boundsPtr = ffi.calloc<native_rectangle_t>();
    final success = cnativeApiBindings.native_tray_icon_get_bounds(
      _handle,
      boundsPtr,
    );

    if (!success) {
      ffi.calloc.free(boundsPtr);
      return null;
    }

    final bounds = TrayIconBounds(
      x: boundsPtr.ref.x,
      y: boundsPtr.ref.y,
      width: boundsPtr.ref.width,
      height: boundsPtr.ref.height,
    );

    ffi.calloc.free(boundsPtr);
    return bounds;
  }

  bool show() {
    return cnativeApiBindings.native_tray_icon_show(_handle);
  }

  bool hide() {
    return cnativeApiBindings.native_tray_icon_hide(_handle);
  }

  bool get isVisible {
    return cnativeApiBindings.native_tray_icon_is_visible(_handle);
  }

  void showContextMenu({double? x, double? y}) {
    if (x != null && y != null) {
      cnativeApiBindings.native_tray_icon_show_context_menu(_handle, x, y);
    } else {
      cnativeApiBindings.native_tray_icon_show_context_menu_default(_handle);
    }
  }

  void _setupEventListener() {
    if (onClicked != null) {
      _addListener(
        native_tray_icon_event_type_t.NATIVE_TRAY_ICON_EVENT_CLICKED,
        _onClickedCallback,
      );
    }
    if (onDoubleClicked != null) {
      _addListener(
        native_tray_icon_event_type_t.NATIVE_TRAY_ICON_EVENT_DOUBLE_CLICKED,
        _onDoubleClickedCallback,
      );
    }
    if (onRightClicked != null) {
      _addListener(
        native_tray_icon_event_type_t.NATIVE_TRAY_ICON_EVENT_RIGHT_CLICKED,
        _onRightClickedCallback,
      );
    }
  }

  void _onClickedCallback(Pointer<Void> event, Pointer<Void> userData) {
    if (onClicked != null) {
      // final clickedEvent = event.cast<native_tray_icon_clicked_event_t>();
      // final button = clickedEvent.ref.button.asTypedList(16);
      // final buttonStr = String.fromCharCodes(button.takeWhile((c) => c != 0));
      // onClicked!(buttonStr);
    }
  }

  void _onDoubleClickedCallback(Pointer<Void> event, Pointer<Void> userData) {
    onDoubleClicked?.call();
  }

  void _onRightClickedCallback(Pointer<Void> event, Pointer<Void> userData) {
    onRightClicked?.call();
  }

  void _addListener(
    native_tray_icon_event_type_t eventType,
    void Function(Pointer<Void>, Pointer<Void>) callback,
  ) {
    if (_listeners.containsKey(eventType)) {
      return; // Already has listener for this event type
    }

    // final nativeCallback =
    //     Pointer.fromFunction<Void Function(Pointer<Void>, Pointer<Void>)>(
    //       callback,
    //     );

    // final listenerId = cnativeApiBindings.native_tray_icon_add_listener(
    //   _handle,
    //   eventType,
    //   nativeCallback,
    //   nullptr,
    // );

    // if (listenerId >= 0) {
    //   _listeners[eventType] = listenerId;
    // }
  }

  void _removeListener(native_tray_icon_event_type_t eventType) {
    final listenerId = _listeners[eventType];
    if (listenerId != null) {
      cnativeApiBindings.native_tray_icon_remove_listener(_handle, listenerId);
      _listeners.remove(eventType);
    }
  }

  void dispose() {
    // Remove all listeners
    for (final eventType in _listeners.keys.toList()) {
      _removeListener(eventType);
    }

    if (_handle != nullptr) {
      cnativeApiBindings.native_tray_icon_destroy(_handle);
    }
  }

  @override
  String toString() => 'TrayIcon(id: $_id)';
}
