import 'dart:ffi';

import 'package:ffi/ffi.dart' as ffi;
import 'package:nativeapi/src/foundation/event_emitter.dart';
import 'package:nativeapi/src/foundation/cnativeapi_bindings_mixin.dart';
import 'package:nativeapi/src/foundation/geometry.dart';
import 'package:nativeapi/src/foundation/native_handle_wrapper.dart';
import 'package:nativeapi/src/image.dart';
import 'package:nativeapi/src/menu.dart';
import 'package:nativeapi/src/tray_icon_event.dart';

class TrayIcon
    with EventEmitter, CNativeApiBindingsMixin
    implements NativeHandleWrapper<native_tray_icon_t> {
  // Static map to track instances by their native handle address
  static final Map<int, TrayIcon> _instances = {};

  // Native callables for event callbacks
  static late final NativeCallable<Void Function(Pointer<Void>, Pointer<Void>)>
  _clickedCallback;
  static late final NativeCallable<Void Function(Pointer<Void>, Pointer<Void>)>
  _rightClickedCallback;
  static late final NativeCallable<Void Function(Pointer<Void>, Pointer<Void>)>
  _doubleClickedCallback;

  static bool _callbacksInitialized = false;

  late final native_tray_icon_t _nativeHandle;

  TrayIcon() {
    _nativeHandle = bindings.native_tray_icon_create();
    // Initialize callbacks once
    if (!_callbacksInitialized) {
      _clickedCallback =
          NativeCallable<Void Function(Pointer<Void>, Pointer<Void>)>.listener(
            _nativeOnClickedEvent,
          );
      _rightClickedCallback =
          NativeCallable<Void Function(Pointer<Void>, Pointer<Void>)>.listener(
            _nativeOnRightClickedEvent,
          );
      _doubleClickedCallback =
          NativeCallable<Void Function(Pointer<Void>, Pointer<Void>)>.listener(
            _nativeOnDoubleClickedEvent,
          );
      _callbacksInitialized = true;
    }

    // Store instance in static map using handle address as key
    _instances[nativeHandle.address] = this;

    // Register listeners for each event type with native callbacks
    // Pass the native handle as userData so callbacks can find the instance
    bindings.native_tray_icon_add_listener(
      _nativeHandle,
      native_tray_icon_event_type_t.NATIVE_TRAY_ICON_EVENT_CLICKED,
      _clickedCallback.nativeFunction,
      _nativeHandle,
    );
    bindings.native_tray_icon_add_listener(
      _nativeHandle,
      native_tray_icon_event_type_t.NATIVE_TRAY_ICON_EVENT_RIGHT_CLICKED,
      _rightClickedCallback.nativeFunction,
      _nativeHandle,
    );
    bindings.native_tray_icon_add_listener(
      _nativeHandle,
      native_tray_icon_event_type_t.NATIVE_TRAY_ICON_EVENT_DOUBLE_CLICKED,
      _doubleClickedCallback.nativeFunction,
      _nativeHandle,
    );
  }

  // Static callback functions for FFI
  static void _nativeOnClickedEvent(
    Pointer<Void> event,
    Pointer<Void> userData,
  ) {
    final instance = _instances[userData.address];
    if (instance != null) {
      print('Tray icon clicked');
      instance.emitSync(TrayIconClickedEvent());
    }
  }

  static void _nativeOnDoubleClickedEvent(
    Pointer<Void> event,
    Pointer<Void> userData,
  ) {
    final instance = _instances[userData.address];
    if (instance != null) {
      print('Tray icon double clicked');
      instance.emitSync(TrayIconDoubleClickedEvent());
    }
  }

  static void _nativeOnRightClickedEvent(
    Pointer<Void> event,
    Pointer<Void> userData,
  ) {
    final instance = _instances[userData.address];
    if (instance != null) {
      print('Tray icon right clicked');
      instance.emitSync(TrayIconRightClickedEvent());
    }
  }

  int get id => bindings.native_tray_icon_get_id(_nativeHandle);

  Image? get icon {
    final iconHandle = bindings.native_tray_icon_get_icon(_nativeHandle);
    if (iconHandle == nullptr) {
      return null;
    }
    return Image(iconHandle);
  }

  set icon(Image? icon) {
    bindings.native_tray_icon_set_icon(
      _nativeHandle,
      icon?.nativeHandle ?? nullptr,
    );
  }

  String? get title {
    final titlePtr = bindings.native_tray_icon_get_title(_nativeHandle);
    final title = titlePtr.cast<ffi.Utf8>().toDartString();
    bindings.free_c_str(titlePtr);
    return title;
  }

  set title(String? title) {
    final titlePtr = title != null
        ? title.toNativeUtf8().cast<Char>()
        : nullptr;
    bindings.native_tray_icon_set_title(_nativeHandle, titlePtr);
    bindings.free_c_str(titlePtr);
  }

  String? get tooltip {
    final tooltipPtr = bindings.native_tray_icon_get_tooltip(_nativeHandle);
    final tooltip = tooltipPtr.cast<ffi.Utf8>().toDartString();
    bindings.free_c_str(tooltipPtr);
    return tooltip;
  }

  set tooltip(String? tooltip) {
    final tooltipPtr = tooltip != null
        ? tooltip.toNativeUtf8().cast<Char>()
        : nullptr;
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
    return Menu(menuHandle);
  }

  set contextMenu(Menu? menu) {
    bindings.native_tray_icon_set_context_menu(
      _nativeHandle,
      menu?.nativeHandle ?? nullptr,
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

  bool get isVisible {
    return bindings.native_tray_icon_is_visible(_nativeHandle);
  }

  set isVisible(bool value) {
    bindings.native_tray_icon_set_visible(_nativeHandle, value);
  }

  void openContextMenu({Offset? at}) {
    if (at != null) {
      bindings.native_tray_icon_open_context_menu_at(
        _nativeHandle,
        at.dx,
        at.dy,
      );
    } else {
      bindings.native_tray_icon_open_context_menu(_nativeHandle);
    }
  }

  void closeContextMenu() {
    bindings.native_tray_icon_close_context_menu(_nativeHandle);
  }

  @override
  native_tray_icon_t get nativeHandle => _nativeHandle;

  @override
  void dispose() {
    // Remove instance from static map
    _instances.remove(_nativeHandle.address);

    if (contextMenu != null) {
      contextMenu!.dispose();
    }
    bindings.native_tray_icon_destroy(_nativeHandle);
  }
}
