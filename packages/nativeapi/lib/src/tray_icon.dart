import 'dart:ffi';
import 'package:ffi/ffi.dart' as ffi;

import 'menu.dart';
import 'foundation/geometry.dart';
import 'foundation/native_handle_wrapper.dart';
import 'foundation/cnativeapi_bindings_mixin.dart';

typedef TrayIconClickedCallback = void Function(String button);
typedef TrayIconDoubleClickedCallback = void Function();
typedef TrayIconRightClickedCallback = void Function();

class TrayIcon
    with CNativeApiBindingsMixin
    implements NativeHandleWrapper<native_tray_icon_t> {
  final native_tray_icon_t _nativeHandle;

  TrayIcon(native_tray_icon_t nativeHandle) : _nativeHandle = nativeHandle;

  @override
  native_display_t get nativeHandle => _nativeHandle;

  @override
  void dispose() {
    // TODO: Implement dispose method
  }

  final Map<native_tray_icon_event_type_t, int> _listeners = {};

  TrayIconClickedCallback? onClicked;
  TrayIconDoubleClickedCallback? onDoubleClicked;
  TrayIconRightClickedCallback? onRightClicked;

  int get id => bindings.native_tray_icon_get_id(_nativeHandle);

  set icon(String icon) {
    final iconPtr = icon.toNativeUtf8().cast<Char>();
    bindings.native_tray_icon_set_icon(_nativeHandle, iconPtr);
    ffi.calloc.free(iconPtr);
  }

  String? get title {
    const bufferSize = 256;
    final buffer = ffi.calloc.allocate<Char>(bufferSize);
    final length = bindings.native_tray_icon_get_title(
      _nativeHandle,
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

  set title(String title) {
    final titlePtr = title.toNativeUtf8().cast<Char>();
    bindings.native_tray_icon_set_title(_nativeHandle, titlePtr);
    ffi.calloc.free(titlePtr);
  }

  String? get tooltip {
    const bufferSize = 256;
    final buffer = ffi.calloc.allocate<Char>(bufferSize);
    final length = bindings.native_tray_icon_get_tooltip(
      _nativeHandle,
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

  set tooltip(String tooltip) {
    final tooltipPtr = tooltip.toNativeUtf8().cast<Char>();
    bindings.native_tray_icon_set_tooltip(_nativeHandle, tooltipPtr);
    ffi.calloc.free(tooltipPtr);
  }

  Menu? get contextMenu {
    final menuHandle = bindings.native_tray_icon_get_context_menu(
      _nativeHandle,
    );
    if (menuHandle == nullptr) {
      return null;
    }
    // return Menu(menuHandle);
  }

  set contextMenu(Menu? menu) {
    bindings.native_tray_icon_set_context_menu(
      _nativeHandle,
      menu?.handle ?? nullptr,
    );
  }

  Rect? get bounds {
    final boundsPtr = ffi.calloc<native_rectangle_t>();
    final success = bindings.native_tray_icon_get_bounds(
      _nativeHandle,
      boundsPtr,
    );

    if (!success) {
      ffi.calloc.free(boundsPtr);
      return null;
    }

    final bounds = Rect.fromLTWH(
      boundsPtr.ref.x,
      boundsPtr.ref.y,
      boundsPtr.ref.width,
      boundsPtr.ref.height,
    );

    ffi.calloc.free(boundsPtr);
    return bounds;
  }

  bool show() {
    return bindings.native_tray_icon_show(_nativeHandle);
  }

  bool hide() {
    return bindings.native_tray_icon_hide(_nativeHandle);
  }

  bool get isVisible {
    return bindings.native_tray_icon_is_visible(_nativeHandle);
  }

  void showContextMenu({double? x, double? y}) {
    if (x != null && y != null) {
      bindings.native_tray_icon_show_context_menu(_nativeHandle, x, y);
    } else {
      bindings.native_tray_icon_show_context_menu_default(_nativeHandle);
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
      bindings.native_tray_icon_remove_listener(_nativeHandle, listenerId);
      _listeners.remove(eventType);
    }
  }

  @override
  String toString() => 'TrayIcon(id: $id)';
}
