import 'dart:ffi';

import 'package:ffi/ffi.dart' as ffi;
import 'package:nativeapi/src/foundation/event_emitter.dart';
import 'package:nativeapi/src/foundation/cnativeapi_bindings_mixin.dart';
import 'package:nativeapi/src/foundation/geometry.dart';
import 'package:nativeapi/src/foundation/native_handle_wrapper.dart';
import 'package:nativeapi/src/image.dart';
import 'package:nativeapi/src/menu.dart';
import 'package:nativeapi/src/tray_icon_event.dart';

/// Defines how the context menu is triggered for a tray icon.
///
/// This enum specifies which mouse interactions should display the tray icon's
/// context menu. The values align with tray icon event types for consistency.
enum ContextMenuTrigger {
  /// Context menu is not automatically triggered by mouse events.
  ///
  /// The application must call [TrayIcon.openContextMenu] explicitly to display
  /// the menu. Use this when you want full control over when the menu appears.
  none,

  /// Context menu is triggered on [TrayIconClickedEvent].
  ///
  /// Automatically opens the context menu when the tray icon is left-clicked.
  /// This is common on some Linux desktop environments.
  clicked,

  /// Context menu is triggered on [TrayIconRightClickedEvent].
  ///
  /// Automatically opens the context menu when the tray icon is right-clicked.
  /// This follows the convention on Windows and most desktop environments.
  rightClicked,

  /// Context menu is triggered on [TrayIconDoubleClickedEvent].
  ///
  /// Automatically opens the context menu when the tray icon is double-clicked.
  /// Less common but useful for applications that use single-click for another action.
  doubleClicked,
}

/// Extension methods for ContextMenuTrigger conversion
extension ContextMenuTriggerExtension on ContextMenuTrigger {
  /// Convert this ContextMenuTrigger to a native enum value.
  native_context_menu_trigger_t toNative() {
    switch (this) {
      case ContextMenuTrigger.none:
        return native_context_menu_trigger_t.NATIVE_CONTEXT_MENU_TRIGGER_NONE;
      case ContextMenuTrigger.clicked:
        return native_context_menu_trigger_t
            .NATIVE_CONTEXT_MENU_TRIGGER_CLICKED;
      case ContextMenuTrigger.rightClicked:
        return native_context_menu_trigger_t
            .NATIVE_CONTEXT_MENU_TRIGGER_RIGHT_CLICKED;
      case ContextMenuTrigger.doubleClicked:
        return native_context_menu_trigger_t
            .NATIVE_CONTEXT_MENU_TRIGGER_DOUBLE_CLICKED;
    }
  }

  /// Convert a native enum value to ContextMenuTrigger.
  static ContextMenuTrigger fromNative(native_context_menu_trigger_t native) {
    switch (native) {
      case native_context_menu_trigger_t.NATIVE_CONTEXT_MENU_TRIGGER_NONE:
        return ContextMenuTrigger.none;
      case native_context_menu_trigger_t.NATIVE_CONTEXT_MENU_TRIGGER_CLICKED:
        return ContextMenuTrigger.clicked;
      case native_context_menu_trigger_t
          .NATIVE_CONTEXT_MENU_TRIGGER_RIGHT_CLICKED:
        return ContextMenuTrigger.rightClicked;
      case native_context_menu_trigger_t
          .NATIVE_CONTEXT_MENU_TRIGGER_DOUBLE_CLICKED:
        return ContextMenuTrigger.doubleClicked;
    }
  }
}

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

  // Store listener IDs for cleanup
  int? _clickedListenerId;
  int? _rightClickedListenerId;
  int? _doubleClickedListenerId;

  TrayIcon() {
    _nativeHandle = bindings.native_tray_icon_create();

    // Store instance in static map using handle address as key
    _instances[nativeHandle.address] = this;
  }

  @override
  void startEventListening() {
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

    // Register listeners for each event type with native callbacks and store IDs
    // Pass the native handle as userData so callbacks can find the instance
    _clickedListenerId = bindings.native_tray_icon_add_listener(
      _nativeHandle,
      native_tray_icon_event_type_t.NATIVE_TRAY_ICON_EVENT_CLICKED,
      _clickedCallback.nativeFunction,
      _nativeHandle,
    );
    _rightClickedListenerId = bindings.native_tray_icon_add_listener(
      _nativeHandle,
      native_tray_icon_event_type_t.NATIVE_TRAY_ICON_EVENT_RIGHT_CLICKED,
      _rightClickedCallback.nativeFunction,
      _nativeHandle,
    );
    _doubleClickedListenerId = bindings.native_tray_icon_add_listener(
      _nativeHandle,
      native_tray_icon_event_type_t.NATIVE_TRAY_ICON_EVENT_DOUBLE_CLICKED,
      _doubleClickedCallback.nativeFunction,
      _nativeHandle,
    );
  }

  @override
  void stopEventListening() {
    // Remove native listeners using stored IDs
    if (_clickedListenerId != null) {
      bindings.native_tray_icon_remove_listener(
        _nativeHandle,
        _clickedListenerId!,
      );
      _clickedListenerId = null;
    }
    if (_rightClickedListenerId != null) {
      bindings.native_tray_icon_remove_listener(
        _nativeHandle,
        _rightClickedListenerId!,
      );
      _rightClickedListenerId = null;
    }
    if (_doubleClickedListenerId != null) {
      bindings.native_tray_icon_remove_listener(
        _nativeHandle,
        _doubleClickedListenerId!,
      );
      _doubleClickedListenerId = null;
    }
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
    if (title != null) {
      final titleUtf8 = title.toNativeUtf8();
      try {
        bindings.native_tray_icon_set_title(
          _nativeHandle,
          titleUtf8.cast<Char>(),
        );
      } finally {
        ffi.malloc.free(titleUtf8);
      }
    } else {
      bindings.native_tray_icon_set_title(_nativeHandle, nullptr);
    }
  }

  String? get tooltip {
    final tooltipPtr = bindings.native_tray_icon_get_tooltip(_nativeHandle);
    final tooltip = tooltipPtr.cast<ffi.Utf8>().toDartString();
    bindings.free_c_str(tooltipPtr);
    return tooltip;
  }

  set tooltip(String? tooltip) {
    if (tooltip != null) {
      final tooltipUtf8 = tooltip.toNativeUtf8();
      try {
        bindings.native_tray_icon_set_tooltip(
          _nativeHandle,
          tooltipUtf8.cast<Char>(),
        );
      } finally {
        ffi.malloc.free(tooltipUtf8);
      }
    } else {
      bindings.native_tray_icon_set_tooltip(_nativeHandle, nullptr);
    }
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

  /// Get the current context menu trigger behavior.
  ///
  /// Returns the current [ContextMenuTrigger] setting that determines
  /// which mouse interactions will automatically display the context menu.
  ContextMenuTrigger get contextMenuTrigger {
    final native = bindings.native_tray_icon_get_context_menu_trigger(
      _nativeHandle,
    );
    return ContextMenuTriggerExtension.fromNative(native);
  }

  /// Set the context menu trigger behavior.
  ///
  /// Determines which mouse interactions will automatically display the
  /// context menu. By default, the trigger is set to [ContextMenuTrigger.none],
  /// requiring explicit control via [openContextMenu] or by setting a trigger mode.
  ///
  /// Example:
  /// ```dart
  /// // Right click shows menu (common on Windows/Linux)
  /// trayIcon.contextMenuTrigger = ContextMenuTrigger.rightClicked;
  ///
  /// // Left click shows menu (common on some Linux environments and macOS)
  /// trayIcon.contextMenuTrigger = ContextMenuTrigger.clicked;
  ///
  /// // Double click shows menu
  /// trayIcon.contextMenuTrigger = ContextMenuTrigger.doubleClicked;
  ///
  /// // Manual control (default) - handle events yourself
  /// trayIcon.contextMenuTrigger = ContextMenuTrigger.none;
  /// trayIcon.addListener<TrayIconRightClickedEvent>((event) {
  ///   // Custom logic before showing menu
  ///   trayIcon.openContextMenu();
  /// });
  /// ```
  set contextMenuTrigger(ContextMenuTrigger trigger) {
    bindings.native_tray_icon_set_context_menu_trigger(
      _nativeHandle,
      trigger.toNative(),
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

  void openContextMenu() {
    bindings.native_tray_icon_open_context_menu(_nativeHandle);
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

    // Dispose event emitter (will call stopEventListening if needed)
    disposeEventEmitter();

    bindings.native_tray_icon_destroy(_nativeHandle);
  }
}
