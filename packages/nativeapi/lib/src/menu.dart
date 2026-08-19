// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;
import 'dart:ui';

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

import 'foundation/keyboard.dart';
import 'image.dart';
import 'placement.dart';
import 'positioning_strategy.dart';

import 'support.dart';

final _bindings = c.cnativeApiBindings;

typedef MenuId = int;

typedef MenuItemId = int;

enum MenuItemType {
  normal(0),
  checkbox(1),
  radio(2),
  separator(3),
  submenu(4);

  const MenuItemType(this.value);
  final int value;

  static MenuItemType fromValue(int value) => switch (value) {
    0 => MenuItemType.normal,
    1 => MenuItemType.checkbox,
    2 => MenuItemType.radio,
    3 => MenuItemType.separator,
    4 => MenuItemType.submenu,
    _ => MenuItemType.normal,
  };

  c.native_menu_item_type_t get raw => c.native_menu_item_type_t.fromValue(value);
}

enum MenuItemState {
  unchecked(0),
  checked(1),
  mixed(2);

  const MenuItemState(this.value);
  final int value;

  static MenuItemState fromValue(int value) => switch (value) {
    0 => MenuItemState.unchecked,
    1 => MenuItemState.checked,
    2 => MenuItemState.mixed,
    _ => MenuItemState.unchecked,
  };

  c.native_menu_item_state_t get raw => c.native_menu_item_state_t.fromValue(value);
}

/// One `MenuEvent`, in its concrete form.
sealed class MenuEvent {
  const MenuEvent();

  /// Reads the event out of its C form. Returns null for a variant this
  /// binding does not know about.
  static MenuEvent? fromNative(c.native_menu_event_t raw) {
    if (raw.type == c.native_menu_event_type_t.NATIVE_MENU_EVENT_TYPE_OPENED.value) {
      return MenuOpenedEvent(menuId: raw.data.opened.menu_id);
    }
    if (raw.type == c.native_menu_event_type_t.NATIVE_MENU_EVENT_TYPE_CLOSED.value) {
      return MenuClosedEvent(menuId: raw.data.closed.menu_id);
    }
    if (raw.type == c.native_menu_event_type_t.NATIVE_MENU_EVENT_TYPE_ITEM_CLICKED.value) {
      return MenuItemClickedEvent(itemId: raw.data.item_clicked.item_id);
    }
    if (raw.type == c.native_menu_event_type_t.NATIVE_MENU_EVENT_TYPE_ITEM_SUBMENU_OPENED.value) {
      return MenuItemSubmenuOpenedEvent(itemId: raw.data.item_submenu_opened.item_id);
    }
    if (raw.type == c.native_menu_event_type_t.NATIVE_MENU_EVENT_TYPE_ITEM_SUBMENU_CLOSED.value) {
      return MenuItemSubmenuClosedEvent(itemId: raw.data.item_submenu_closed.item_id);
    }
    return null;
  }
}

final class MenuOpenedEvent extends MenuEvent {
  const MenuOpenedEvent({required this.menuId, });

  final MenuId menuId;
}

final class MenuClosedEvent extends MenuEvent {
  const MenuClosedEvent({required this.menuId, });

  final MenuId menuId;
}

final class MenuItemClickedEvent extends MenuEvent {
  const MenuItemClickedEvent({required this.itemId, });

  final MenuItemId itemId;
}

final class MenuItemSubmenuOpenedEvent extends MenuEvent {
  const MenuItemSubmenuOpenedEvent({required this.itemId, });

  final MenuItemId itemId;
}

final class MenuItemSubmenuClosedEvent extends MenuEvent {
  const MenuItemSubmenuClosedEvent({required this.itemId, });

  final MenuItemId itemId;
}

class MenuItem {
  /// Adopts a handle returned by the C API and releases it when this
  /// object becomes unreachable.
  MenuItem.fromHandle(this.nativeHandle) {
    _finalizer.attach(this, nativeHandle, detach: this);
  }

  /// Wraps a handle owned elsewhere; releasing it stays the owner's job.
  MenuItem.borrowed(this.nativeHandle);

  /// The underlying handle-table entry.
  final int nativeHandle;

  static final Finalizer<int> _finalizer = Finalizer<int>(
    (handle) => _bindings.native_menu_item_free(handle),
  );

  /// Releases the handle now instead of at collection.
  void dispose() {
    _finalizer.detach(this);
    _bindings.native_menu_item_free(nativeHandle);
  }

  /// Creates a new `MenuItem`; returns null if the native side failed.
  static MenuItem? createWithLabelAndType(String label, MenuItemType type) {
    final labelNative = label.toNativeUtf8().cast<ffi.Char>();
    final handle = _bindings.native_menu_item_create_with_label_and_type(labelNative, type.raw);
    pkg_ffi.calloc.free(labelNative);
    if (handle == 0) return null;
    return MenuItem.fromHandle(handle);
  }

  /// Creates a new `MenuItem`; returns null if the native side failed.
  static MenuItem? createWithNativeItem(ffi.Pointer<ffi.Void> nativeItem) {
    final handle = _bindings.native_menu_item_create_with_native_item(nativeItem);
    if (handle == 0) return null;
    return MenuItem.fromHandle(handle);
  }

  MenuItemId get id {
    return _bindings.native_menu_item_get_id(nativeHandle);
  }

  MenuItemType get type {
    final raw = _bindings.native_menu_item_get_type(nativeHandle);
    return MenuItemType.fromValue(raw.value);
  }

  set label(String? value) {
    final valueNative = value == null
        ? ffi.nullptr
        : value.toNativeUtf8().cast<ffi.Char>();
    _bindings.native_menu_item_set_label(nativeHandle, valueNative);
    if (valueNative != ffi.nullptr) pkg_ffi.calloc.free(valueNative);
  }

  String? get label {
    final resultPointer = _bindings.native_menu_item_get_label(nativeHandle);
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }

  set icon(Image? value) {
    _bindings.native_menu_item_set_icon(nativeHandle, value?.nativeHandle ?? 0);
  }

  Image? get icon {
    final handle = _bindings.native_menu_item_get_icon(nativeHandle);
    if (handle == 0) return null;
    return Image.fromHandle(handle);
  }

  set tooltip(String? value) {
    final valueNative = value == null
        ? ffi.nullptr
        : value.toNativeUtf8().cast<ffi.Char>();
    _bindings.native_menu_item_set_tooltip(nativeHandle, valueNative);
    if (valueNative != ffi.nullptr) pkg_ffi.calloc.free(valueNative);
  }

  String? get tooltip {
    final resultPointer = _bindings.native_menu_item_get_tooltip(nativeHandle);
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }

  set accelerator(KeyboardAccelerator? value) {
    final valuePointer = value?.allocNative() ?? ffi.nullptr;
    _bindings.native_menu_item_set_accelerator(nativeHandle, valuePointer.cast());
    if (valuePointer != ffi.nullptr) {
      KeyboardAccelerator.freeNative(valuePointer.cast());
    }
  }

  KeyboardAccelerator get accelerator {
    final raw = _bindings.native_menu_item_get_accelerator(nativeHandle);
    return KeyboardAccelerator.fromNative(raw);
  }

  set isEnabled(bool value) {
    _bindings.native_menu_item_set_enabled(nativeHandle, value);
  }

  bool get isEnabled {
    return _bindings.native_menu_item_is_enabled(nativeHandle);
  }

  set state(MenuItemState value) {
    _bindings.native_menu_item_set_state(nativeHandle, value.raw);
  }

  MenuItemState get state {
    final raw = _bindings.native_menu_item_get_state(nativeHandle);
    return MenuItemState.fromValue(raw.value);
  }

  set radioGroup(int value) {
    _bindings.native_menu_item_set_radio_group(nativeHandle, value);
  }

  int get radioGroup {
    return _bindings.native_menu_item_get_radio_group(nativeHandle);
  }

  set submenu(Menu? value) {
    _bindings.native_menu_item_set_submenu(nativeHandle, value?.nativeHandle ?? 0);
  }

  Menu? get submenu {
    final handle = _bindings.native_menu_item_get_submenu(nativeHandle);
    if (handle == 0) return null;
    return Menu.fromHandle(handle);
  }

  /// Platform-specific native object behind this handle.
  ffi.Pointer<ffi.Void> get nativeObject =>
      _bindings.native_menu_item_get_native_object(nativeHandle);

  /// Registers [callback] for every `MenuEvent` this `MenuItem` emits.
  ///
  /// The callback runs synchronously on whichever thread the native side
  /// dispatches from, because the event struct is freed as soon as it
  /// returns. That thread must therefore be this isolate's own; see the
  /// package README for what that means under Flutter.
  ListenerId addListener(void Function(MenuEvent) callback) {
    final callable = ffi.NativeCallable<
        ffi.Void Function(ffi.Pointer<c.native_menu_event_t>, ffi.Pointer<ffi.Void>)>.isolateLocal(
      (ffi.Pointer<c.native_menu_event_t> event, ffi.Pointer<ffi.Void> _) {
        if (event == ffi.nullptr) return;
        final value = MenuEvent.fromNative(event.ref);
        if (value != null) callback(value);
      },
    );
    _listeners.add(callable);  // keeps the trampoline alive
    return _bindings.native_menu_item_add_listener(nativeHandle, callable.nativeFunction, ffi.nullptr);
  }

  /// Unregisters a listener. Returns false if unknown.
  bool removeListener(ListenerId listenerId) =>
      _bindings.native_menu_item_remove_listener(nativeHandle, listenerId);

  /// Trampolines stay reachable for as long as the C side may call them.
  static final List<Object> _listeners = <Object>[];

}

class Menu {
  /// Adopts a handle returned by the C API and releases it when this
  /// object becomes unreachable.
  Menu.fromHandle(this.nativeHandle) {
    _finalizer.attach(this, nativeHandle, detach: this);
  }

  /// Wraps a handle owned elsewhere; releasing it stays the owner's job.
  Menu.borrowed(this.nativeHandle);

  /// The underlying handle-table entry.
  final int nativeHandle;

  static final Finalizer<int> _finalizer = Finalizer<int>(
    (handle) => _bindings.native_menu_free(handle),
  );

  /// Releases the handle now instead of at collection.
  void dispose() {
    _finalizer.detach(this);
    _bindings.native_menu_free(nativeHandle);
  }

  /// Creates a new `Menu`; returns null if the native side failed.
  static Menu? create() {
    final handle = _bindings.native_menu_create();
    if (handle == 0) return null;
    return Menu.fromHandle(handle);
  }

  /// Creates a new `Menu`; returns null if the native side failed.
  static Menu? createWithNativeMenu(ffi.Pointer<ffi.Void> nativeMenu) {
    final handle = _bindings.native_menu_create_with_native_menu(nativeMenu);
    if (handle == 0) return null;
    return Menu.fromHandle(handle);
  }

  MenuId get id {
    return _bindings.native_menu_get_id(nativeHandle);
  }

  void addItem(MenuItem? item) {
    _bindings.native_menu_add_item(nativeHandle, item?.nativeHandle ?? 0);
  }

  void insertItem(int index, MenuItem? item) {
    _bindings.native_menu_insert_item(nativeHandle, index, item?.nativeHandle ?? 0);
  }

  bool removeItem(MenuItem? item) {
    return _bindings.native_menu_remove_item(nativeHandle, item?.nativeHandle ?? 0);
  }

  bool removeItemById(MenuItemId itemId) {
    return _bindings.native_menu_remove_item_by_id(nativeHandle, itemId);
  }

  bool removeItemAt(int index) {
    return _bindings.native_menu_remove_item_at(nativeHandle, index);
  }

  void clear() {
    _bindings.native_menu_clear(nativeHandle);
  }

  void addSeparator() {
    _bindings.native_menu_add_separator(nativeHandle);
  }

  void insertSeparator(int index) {
    _bindings.native_menu_insert_separator(nativeHandle, index);
  }

  int get itemCount {
    return _bindings.native_menu_get_item_count(nativeHandle);
  }

  MenuItem? getItemAt(int index) {
    final handle = _bindings.native_menu_get_item_at(nativeHandle, index);
    if (handle == 0) return null;
    return MenuItem.fromHandle(handle);
  }

  MenuItem? getItemById(MenuItemId itemId) {
    final handle = _bindings.native_menu_get_item_by_id(nativeHandle, itemId);
    if (handle == 0) return null;
    return MenuItem.fromHandle(handle);
  }

  List<MenuItem> get allItems {
    final list = _bindings.native_menu_get_all_items(nativeHandle);
    final items = <MenuItem>[];
    for (var i = 0; i < list.count; i++) {
      items.add(MenuItem.fromHandle(list.menu_items[i]));
    }
    final listPointer = pkg_ffi.calloc<c.native_menu_item_list_t>();
    listPointer.ref = list;
    // The handles now belong to `items`; free just the array.
    _bindings.native_menu_item_list_release(listPointer);
    pkg_ffi.calloc.free(listPointer);
    return items;
  }

  bool open(PositioningStrategy strategy, Placement placement) {
    return _bindings.native_menu_open(nativeHandle, strategy.nativeHandle, placement.raw);
  }

  bool close() {
    return _bindings.native_menu_close(nativeHandle);
  }

  /// Platform-specific native object behind this handle.
  ffi.Pointer<ffi.Void> get nativeObject =>
      _bindings.native_menu_get_native_object(nativeHandle);

  /// Registers [callback] for every `MenuEvent` this `Menu` emits.
  ///
  /// The callback runs synchronously on whichever thread the native side
  /// dispatches from, because the event struct is freed as soon as it
  /// returns. That thread must therefore be this isolate's own; see the
  /// package README for what that means under Flutter.
  ListenerId addListener(void Function(MenuEvent) callback) {
    final callable = ffi.NativeCallable<
        ffi.Void Function(ffi.Pointer<c.native_menu_event_t>, ffi.Pointer<ffi.Void>)>.isolateLocal(
      (ffi.Pointer<c.native_menu_event_t> event, ffi.Pointer<ffi.Void> _) {
        if (event == ffi.nullptr) return;
        final value = MenuEvent.fromNative(event.ref);
        if (value != null) callback(value);
      },
    );
    _listeners.add(callable);  // keeps the trampoline alive
    return _bindings.native_menu_add_listener(nativeHandle, callable.nativeFunction, ffi.nullptr);
  }

  /// Unregisters a listener. Returns false if unknown.
  bool removeListener(ListenerId listenerId) =>
      _bindings.native_menu_remove_listener(nativeHandle, listenerId);

  /// Trampolines stay reachable for as long as the C side may call them.
  static final List<Object> _listeners = <Object>[];

}

