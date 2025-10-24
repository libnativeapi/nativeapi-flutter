import 'dart:ffi';

import 'package:ffi/ffi.dart' as ffi;
import 'package:nativeapi/src/foundation/cnativeapi_bindings_mixin.dart';
import 'package:nativeapi/src/foundation/event_emitter.dart';
import 'package:nativeapi/src/foundation/geometry.dart';
import 'package:nativeapi/src/foundation/native_handle_wrapper.dart';
import 'package:nativeapi/src/foundation/positioning_strategy.dart';
import 'package:nativeapi/src/image.dart';
import 'package:nativeapi/src/menu_event.dart';

enum MenuItemType { normal, separator, submenu, checkbox, radio }

enum MenuItemState { unchecked, checked, mixed }

class MenuItem
    with EventEmitter, CNativeApiBindingsMixin
    implements NativeHandleWrapper<native_menu_item_t> {
  // Static map to track instances by their native handle address
  static final Map<int, MenuItem> _instances = {};

  // Native callables for event callbacks
  static late final NativeCallable<Void Function(Pointer<Void>, Pointer<Void>)>
  _clickedCallback;
  static late final NativeCallable<Void Function(Pointer<Void>, Pointer<Void>)>
  _submenuOpenedCallback;
  static late final NativeCallable<Void Function(Pointer<Void>, Pointer<Void>)>
  _submenuClosedCallback;

  static bool _callbacksInitialized = false;

  late final native_menu_item_t _nativeHandle;

  MenuItem(String label, [MenuItemType type = MenuItemType.normal]) {
    final labelPtr = label.toNativeUtf8().cast<Char>();
    _nativeHandle = bindings.native_menu_item_create(
      labelPtr,
      _convertMenuItemType(type),
    );
    ffi.calloc.free(labelPtr);

    // Initialize callbacks once
    if (!_callbacksInitialized) {
      _clickedCallback =
          NativeCallable<Void Function(Pointer<Void>, Pointer<Void>)>.listener(
            _nativeOnClickedEvent,
          );
      _submenuOpenedCallback =
          NativeCallable<Void Function(Pointer<Void>, Pointer<Void>)>.listener(
            _nativeOnSubmenuOpenedEvent,
          );
      _submenuClosedCallback =
          NativeCallable<Void Function(Pointer<Void>, Pointer<Void>)>.listener(
            _nativeOnSubmenuClosedEvent,
          );
      _callbacksInitialized = true;
    }

    // Store instance in static map using handle address as key
    _instances[_nativeHandle.address] = this;

    // Register listeners for each event type with native callbacks
    bindings.native_menu_item_add_listener(
      _nativeHandle,
      native_menu_item_event_type_t.NATIVE_MENU_ITEM_EVENT_CLICKED,
      _clickedCallback.nativeFunction,
      _nativeHandle,
    );
    bindings.native_menu_item_add_listener(
      _nativeHandle,
      native_menu_item_event_type_t.NATIVE_MENU_ITEM_EVENT_SUBMENU_OPENED,
      _submenuOpenedCallback.nativeFunction,
      _nativeHandle,
    );
    bindings.native_menu_item_add_listener(
      _nativeHandle,
      native_menu_item_event_type_t.NATIVE_MENU_ITEM_EVENT_SUBMENU_CLOSED,
      _submenuClosedCallback.nativeFunction,
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
      print('Menu item clicked: ${instance.id}');
      instance.emitSync(MenuItemClickedEvent(instance.id));
    }
  }

  static void _nativeOnSubmenuOpenedEvent(
    Pointer<Void> event,
    Pointer<Void> userData,
  ) {
    final instance = _instances[userData.address];
    if (instance != null) {
      print('Menu item submenu opened: ${instance.id}');
      instance.emitSync(MenuItemSubmenuOpenedEvent(instance.id));
    }
  }

  static void _nativeOnSubmenuClosedEvent(
    Pointer<Void> event,
    Pointer<Void> userData,
  ) {
    final instance = _instances[userData.address];
    if (instance != null) {
      print('Menu item submenu closed: ${instance.id}');
      instance.emitSync(MenuItemSubmenuClosedEvent(instance.id));
    }
  }

  // Helper method to convert MenuItemType to native enum
  static native_menu_item_type_t _convertMenuItemType(MenuItemType type) {
    switch (type) {
      case MenuItemType.normal:
        return native_menu_item_type_t.NATIVE_MENU_ITEM_TYPE_NORMAL;
      case MenuItemType.separator:
        return native_menu_item_type_t.NATIVE_MENU_ITEM_TYPE_SEPARATOR;
      case MenuItemType.submenu:
        return native_menu_item_type_t.NATIVE_MENU_ITEM_TYPE_SUBMENU;
      case MenuItemType.checkbox:
        return native_menu_item_type_t.NATIVE_MENU_ITEM_TYPE_CHECKBOX;
      case MenuItemType.radio:
        return native_menu_item_type_t.NATIVE_MENU_ITEM_TYPE_RADIO;
    }
  }

  int get id {
    return bindings.native_menu_item_get_id(_nativeHandle);
  }

  MenuItemType get type {
    final type = bindings.native_menu_item_get_type(_nativeHandle);
    switch (type) {
      case native_menu_item_type_t.NATIVE_MENU_ITEM_TYPE_NORMAL:
        return MenuItemType.normal;
      case native_menu_item_type_t.NATIVE_MENU_ITEM_TYPE_SEPARATOR:
        return MenuItemType.separator;
      case native_menu_item_type_t.NATIVE_MENU_ITEM_TYPE_SUBMENU:
        return MenuItemType.submenu;
      case native_menu_item_type_t.NATIVE_MENU_ITEM_TYPE_CHECKBOX:
        return MenuItemType.checkbox;
      case native_menu_item_type_t.NATIVE_MENU_ITEM_TYPE_RADIO:
        return MenuItemType.radio;
    }
  }

  String get label {
    final labelPtr = bindings.native_menu_item_get_label(_nativeHandle);
    final label = labelPtr.cast<ffi.Utf8>().toDartString();
    bindings.free_c_str(labelPtr);
    return label;
  }

  set label(String label) {
    final labelPtr = label.toNativeUtf8().cast<Char>();
    bindings.native_menu_item_set_label(_nativeHandle, labelPtr);
    ffi.calloc.free(labelPtr);
  }

  Image? get icon {
    final iconHandle = bindings.native_menu_item_get_icon(_nativeHandle);
    if (iconHandle == nullptr) {
      return null;
    }
    return Image(iconHandle);
  }

  set icon(Image? icon) {
    bindings.native_menu_item_set_icon(
      _nativeHandle,
      icon?.nativeHandle ?? nullptr,
    );
  }

  String get tooltip {
    final tooltipPtr = bindings.native_menu_item_get_tooltip(_nativeHandle);
    final tooltip = tooltipPtr.cast<ffi.Utf8>().toDartString();
    bindings.free_c_str(tooltipPtr);
    return tooltip;
  }

  set tooltip(String tooltip) {
    final tooltipPtr = tooltip.toNativeUtf8().cast<Char>();
    bindings.native_menu_item_set_tooltip(_nativeHandle, tooltipPtr);
    ffi.calloc.free(tooltipPtr);
  }

  @override
  native_menu_item_t get nativeHandle => _nativeHandle;

  @override
  void dispose() {
    // Remove instance from static map
    _instances.remove(_nativeHandle.address);

    // // Remove native listeners
    // bindings.native_menu_item_remove_listener(
    //   _nativeHandle,
    //   native_menu_item_event_type_t.NATIVE_MENU_ITEM_EVENT_CLICKED,
    //   _clickedCallback.nativeFunction,
    // );
    // bindings.native_menu_item_remove_listener(
    //   _nativeHandle,
    //   native_menu_item_event_type_t.NATIVE_MENU_ITEM_EVENT_SUBMENU_OPENED,
    //   _submenuOpenedCallback.nativeFunction,
    // );
    // bindings.native_menu_item_remove_listener(
    //   _nativeHandle,
    //   native_menu_item_event_type_t.NATIVE_MENU_ITEM_EVENT_SUBMENU_CLOSED,
    //   _submenuClosedCallback.nativeFunction,
    // );

    // Dispose event emitter
    disposeEventEmitter();

    // Destroy native handle
    bindings.native_menu_item_destroy(_nativeHandle);
  }
}

class Menu
    with EventEmitter, CNativeApiBindingsMixin
    implements NativeHandleWrapper<native_menu_t> {
  late final native_menu_t _nativeHandle;

  // Static map to track instances by their native handle address
  static final Map<int, Menu> _instances = {};

  // Native callables for event callbacks
  static late final NativeCallable<Void Function(Pointer<Void>, Pointer<Void>)>
  _openedCallback;
  static late final NativeCallable<Void Function(Pointer<Void>, Pointer<Void>)>
  _closedCallback;

  static bool _callbacksInitialized = false;

  Menu([native_menu_t? nativeHandle]) {
    _nativeHandle = nativeHandle ?? bindings.native_menu_create();

    // Initialize callbacks once
    if (!_callbacksInitialized) {
      _openedCallback =
          NativeCallable<Void Function(Pointer<Void>, Pointer<Void>)>.listener(
            _nativeOnOpenedEvent,
          );
      _closedCallback =
          NativeCallable<Void Function(Pointer<Void>, Pointer<Void>)>.listener(
            _nativeOnClosedEvent,
          );
      _callbacksInitialized = true;
    }

    // Store instance in static map using handle address as key
    _instances[_nativeHandle.address] = this;

    // Register listeners for each event type with native callbacks
    bindings.native_menu_add_listener(
      _nativeHandle,
      native_menu_event_type_t.NATIVE_MENU_EVENT_OPENED,
      _openedCallback.nativeFunction,
      _nativeHandle,
    );
    bindings.native_menu_add_listener(
      _nativeHandle,
      native_menu_event_type_t.NATIVE_MENU_EVENT_CLOSED,
      _closedCallback.nativeFunction,
      _nativeHandle,
    );
  }

  // Static callback functions for FFI
  static void _nativeOnOpenedEvent(
    Pointer<Void> event,
    Pointer<Void> userData,
  ) {
    final instance = _instances[userData.address];
    if (instance != null) {
      print('Menu opened: ${instance.id}');
      instance.emitSync(MenuOpenedEvent(instance.id));
    }
  }

  static void _nativeOnClosedEvent(
    Pointer<Void> event,
    Pointer<Void> userData,
  ) {
    final instance = _instances[userData.address];
    if (instance != null) {
      print('Menu closed: ${instance.id}');
      instance.emitSync(MenuClosedEvent(instance.id));
    }
  }

  int get id {
    return bindings.native_menu_get_id(_nativeHandle);
  }

  void addItem(MenuItem item) {
    bindings.native_menu_add_item(_nativeHandle, item.nativeHandle);
  }

  void insertItem(int index, MenuItem item) {
    bindings.native_menu_insert_item(_nativeHandle, item.nativeHandle, index);
  }

  void addSeparator() {
    bindings.native_menu_add_separator(_nativeHandle);
  }

  void insertSeparator(int index) {
    bindings.native_menu_insert_separator(_nativeHandle, index);
  }

  int get itemCount {
    return bindings.native_menu_get_item_count(_nativeHandle);
  }

  /// Display the menu as a context menu using the specified positioning strategy.
  ///
  /// Shows the menu according to the provided positioning strategy and waits for
  /// user interaction. The menu will close when the user clicks outside of it or
  /// selects an item.
  ///
  /// Example:
  /// ```dart
  /// // Open context menu at cursor position
  /// menu.open(PositioningStrategy.cursorPosition());
  ///
  /// // Open context menu at specific coordinates
  /// menu.open(PositioningStrategy.absolute(Offset(100, 200)));
  ///
  /// // Open context menu relative to a button with offset
  /// final buttonRect = button.getBounds();
  /// menu.open(PositioningStrategy.relative(buttonRect, Offset(0, 10)));
  /// ```
  bool open(PositioningStrategy strategy) {
    // Convert Dart strategy to native strategy
    final nativeStrategy = strategy.toNative();

    // Open menu with native strategy
    final result = bindings.native_menu_open(_nativeHandle, nativeStrategy);

    // Free the native strategy
    bindings.native_positioning_strategy_free(nativeStrategy);

    return result;
  }

  bool close() {
    return bindings.native_menu_close(_nativeHandle);
  }

  @override
  native_menu_t get nativeHandle => _nativeHandle;

  @override
  void dispose() {
    // Remove instance from static map
    _instances.remove(_nativeHandle.address);

    // // Remove native listeners
    // bindings.native_menu_remove_listener(
    //   _nativeHandle,
    //   _openedCallback.nativeFunction,
    // );

    // Dispose event emitter
    disposeEventEmitter();

    // Destroy native handle
    bindings.native_menu_destroy(_nativeHandle);
  }
}
