import 'dart:ffi' as ffi;

import 'package:cnativeapi/cnativeapi.dart';

abstract class MenuItemType {
  static const String normal = 'normal';
  static const String separator = 'separator';
  static const String submenu = 'submenu';
  static const String checkbox = 'checkbox';
  static const String radio = 'radio';
}

class MenuItem {
  MenuItem({
    required this.id,
    this.type = MenuItemType.normal,
    this.label,
    this.enabled = true,
    this.checked = false,
    this.accelerator,
    this.submenu,
    this.onClicked,
  });

  final String id;
  final String type;
  final String? label;
  final bool enabled;
  final bool checked;
  final String? accelerator;
  final Menu? submenu;
  final void Function()? onClicked;

  MenuItem copyWith({
    String? id,
    String? type,
    String? label,
    bool? enabled,
    bool? checked,
    String? accelerator,
    Menu? submenu,
    void Function()? onClicked,
  }) {
    return MenuItem(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      enabled: enabled ?? this.enabled,
      checked: checked ?? this.checked,
      accelerator: accelerator ?? this.accelerator,
      submenu: submenu ?? this.submenu,
      onClicked: onClicked ?? this.onClicked,
    );
  }

  @override
  String toString() => 'MenuItem(id: $id, label: $label)';
}

class Menu {
  Menu({this.items = const []}) : _handle = ffi.nullptr;

  Menu._(this._handle, {this.items = const []});

  final ffi.Pointer<ffi.Void> _handle;
  final List<MenuItem> items;

  Menu copyWith({List<MenuItem>? items}) {
    return Menu(items: items ?? this.items);
  }

  void addItem(MenuItem item) {
    items.add(item);
  }

  void removeItem(String id) {
    items.removeWhere((item) => item.id == id);
  }

  MenuItem? findItem(String id) {
    for (final item in items) {
      if (item.id == id) {
        return item;
      }
      if (item.submenu != null) {
        final found = item.submenu!.findItem(id);
        if (found != null) {
          return found;
        }
      }
    }
    return null;
  }

  void dispose() {
    if (_handle != ffi.nullptr) {
      // TODO: Call native menu free function when available
      // cnativeApiBindings.native_menu_free(_handle);
    }
  }

  @override
  String toString() => 'Menu(items: ${items.length})';
}
