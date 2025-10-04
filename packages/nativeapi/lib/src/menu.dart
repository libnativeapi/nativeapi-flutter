import 'dart:ffi';

import 'package:cnativeapi/cnativeapi.dart';
import 'package:ffi/ffi.dart' as ffi;

class Menu {
  final native_menu_t _handle;

  final List<MenuItem> items;

  Menu({List<MenuItem>? items})
    : _handle = cnativeApiBindings.native_menu_create(),
      items = items ?? [];

  native_menu_t get handle => _handle;

  bool get isEnabled {
    return cnativeApiBindings.native_menu_is_enabled(_handle);
  }

  bool get isVisible {
    return cnativeApiBindings.native_menu_is_visible(_handle);
  }

  int get itemCount => items.length;

  void addItem(MenuItem item) {
    items.add(item);
    cnativeApiBindings.native_menu_add_item(_handle, item._handle);
  }

  void addSeparator() {
    final separator = MenuItem(
      id: 'separator_${DateTime.now().millisecondsSinceEpoch}',
      type: MenuItemType.separator,
    );
    addItem(separator);
  }

  void clear() {
    items.clear();
    cnativeApiBindings.native_menu_clear(_handle);
  }

  void close() {
    cnativeApiBindings.native_menu_close(_handle);
  }

  void dispose() {
    if (_handle != nullptr) {
      cnativeApiBindings.native_menu_destroy(_handle);
    }
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

  MenuItem? getItemAt(int index) {
    if (index >= 0 && index < items.length) {
      return items[index];
    }
    return null;
  }

  void insertItem(int index, MenuItem item) {
    items.insert(index, item);
    // cnativeApiBindings.native_menu_insert_item(_handle, index, item._handle);
  }

  void insertSeparator(int index) {
    final separator = MenuItem(
      id: 'separator_${DateTime.now().millisecondsSinceEpoch}',
      type: MenuItemType.separator,
    );
    insertItem(index, separator);
  }

  void removeItem(String id) {
    items.removeWhere((item) => item.id == id);
    // final idPtr = id.toNativeUtf8().cast<Char>();
    // cnativeApiBindings.native_menu_remove_item_by_id(_handle, idPtr);
  }

  void removeItemAt(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      cnativeApiBindings.native_menu_remove_item_at(_handle, index);
    }
  }

  void setEnabled(bool enabled) {
    cnativeApiBindings.native_menu_set_enabled(_handle, enabled);
  }

  void showAsContextMenu({int? x, int? y}) {
    if (x != null && y != null) {
      cnativeApiBindings.native_menu_show_as_context_menu(
        _handle,
        x.toDouble(),
        y.toDouble(),
      );
    } else {
      cnativeApiBindings.native_menu_show_as_context_menu_default(_handle);
    }
  }

  @override
  String toString() => 'Menu(items: ${items.length})';
}

class MenuItem {
  final native_menu_item_t _handle;

  final String? id;

  final String type;
  final String? label;
  final bool enabled;
  final bool checked;
  final String? accelerator;
  final Menu? submenu;
  final void Function()? onClicked;
  MenuItem({
    this.id,
    this.type = MenuItemType.normal,
    this.label,
    this.enabled = true,
    this.checked = false,
    this.accelerator,
    this.submenu,
    this.onClicked,
  }) : _handle = _createNativeMenuItem(type, label);
  MenuItem._(
    this._handle, {
    required this.id,
    this.type = MenuItemType.normal,
    this.label,
    this.enabled = true,
    this.checked = false,
    this.accelerator,
    this.submenu,
    this.onClicked,
  });

  native_menu_item_t get handle => _handle;

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

  void dispose() {
    if (_handle != nullptr) {
      cnativeApiBindings.native_menu_item_destroy(_handle);
    }
  }

  void setAccelerator(String? accelerator) {
    if (accelerator != null) {
      // final accelPtr = accelerator.toNativeUtf8().cast<Char>();
      // cnativeApiBindings.native_menu_item_set_accelerator(_handle, accelPtr);
    } else {
      cnativeApiBindings.native_menu_item_remove_accelerator(_handle);
    }
  }

  void setChecked(bool checked) {
    final state = checked
        ? native_menu_item_state_t.NATIVE_MENU_ITEM_STATE_CHECKED
        : native_menu_item_state_t.NATIVE_MENU_ITEM_STATE_UNCHECKED;
    cnativeApiBindings.native_menu_item_set_state(_handle, state);
  }

  void setEnabled(bool enabled) {
    cnativeApiBindings.native_menu_item_set_enabled(_handle, enabled);
  }

  void setLabel(String? newLabel) {
    if (newLabel != null) {
      final labelPtr = newLabel.toNativeUtf8().cast<Char>();
      cnativeApiBindings.native_menu_item_set_label(_handle, labelPtr);
    }
  }

  void setSubmenu(Menu? submenu) {
    if (submenu != null) {
      cnativeApiBindings.native_menu_item_set_submenu(_handle, submenu._handle);
    } else {
      cnativeApiBindings.native_menu_item_remove_submenu(_handle);
    }
  }

  @override
  String toString() => 'MenuItem(id: $id, label: $label)';

  void trigger() {
    cnativeApiBindings.native_menu_item_trigger(_handle);
  }

  static native_menu_item_t _createNativeMenuItem(String type, String? label) {
    if (type == MenuItemType.separator) {
      return cnativeApiBindings.native_menu_item_create_separator();
    } else {
      final labelPtr = label != null
          ? label.toNativeUtf8().cast<Char>()
          : nullptr.cast<Char>();

      final nativeType = switch (type) {
        MenuItemType.normal =>
          native_menu_item_type_t.NATIVE_MENU_ITEM_TYPE_NORMAL,
        MenuItemType.checkbox =>
          native_menu_item_type_t.NATIVE_MENU_ITEM_TYPE_CHECKBOX,
        MenuItemType.radio =>
          native_menu_item_type_t.NATIVE_MENU_ITEM_TYPE_RADIO,
        MenuItemType.submenu =>
          native_menu_item_type_t.NATIVE_MENU_ITEM_TYPE_SUBMENU,
        _ => native_menu_item_type_t.NATIVE_MENU_ITEM_TYPE_NORMAL,
      };

      final handle = cnativeApiBindings.native_menu_item_create(
        labelPtr,
        nativeType,
      );

      if (labelPtr != nullptr) {
        // Free the allocated string
        // Note: We need to manage memory properly here
      }

      return handle;
    }
  }
}

abstract class MenuItemType {
  static const String normal = 'normal';
  static const String separator = 'separator';
  static const String submenu = 'submenu';
  static const String checkbox = 'checkbox';
  static const String radio = 'radio';
}
