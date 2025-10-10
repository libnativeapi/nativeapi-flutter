import 'dart:ffi';

import 'package:ffi/ffi.dart' as ffi;
import 'package:nativeapi/src/foundation/event_emitter.dart';
import 'package:nativeapi/src/foundation/cnativeapi_bindings_mixin.dart';
import 'package:nativeapi/src/foundation/native_handle_wrapper.dart';

enum MenuItemType { normal, separator, submenu, checkbox, radio }

enum MenuItemState { unchecked, checked, mixed }

class MenuItem
    with EventEmitter, CNativeApiBindingsMixin
    implements NativeHandleWrapper<native_menu_item_t> {
  late final native_menu_t _nativeHandle;

  MenuItem(String label, [MenuItemType type = MenuItemType.normal]) {
    _nativeHandle = bindings.native_menu_item_create(
      label.toNativeUtf8().cast<Char>(),
      native_menu_item_type_t.NATIVE_MENU_ITEM_TYPE_NORMAL,
    );
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

  String get icon {
    final iconPtr = bindings.native_menu_item_get_icon(_nativeHandle);
    final icon = iconPtr.cast<ffi.Utf8>().toDartString();
    bindings.free_c_str(iconPtr);
    return icon;
  }

  set icon(String icon) {
    final iconPtr = icon.toNativeUtf8().cast<Char>();
    bindings.native_menu_item_set_icon(_nativeHandle, iconPtr);
    ffi.calloc.free(iconPtr);
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
    // TODO: Implement dispose method
  }
}

class Menu
    with CNativeApiBindingsMixin
    implements NativeHandleWrapper<native_menu_t> {
  late final native_menu_t _nativeHandle;

  Menu([native_menu_t? nativeHandle]) {
    _nativeHandle = nativeHandle ?? bindings.native_menu_create();
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

  bool showAsContextMenu(double x, double y) {
    return bindings.native_menu_show_as_context_menu(_nativeHandle, x, y);
  }

  bool close() {
    return bindings.native_menu_close(_nativeHandle);
  }

  @override
  native_menu_t get nativeHandle => _nativeHandle;

  @override
  void dispose() {
    // TODO: Implement dispose method
  }
}
