// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;
import 'dart:ui';

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

import 'tray_icon.dart';

final _bindings = c.cnativeApiBindings;

class TrayManager {
  const TrayManager._();

  /// The shared instance backed by the native singleton.
  static const TrayManager instance = TrayManager._();

  bool isSupported() {
    return _bindings.native_tray_manager_is_supported();
  }

  TrayIcon? get(TrayIconId id) {
    final handle = _bindings.native_tray_manager_get(id);
    if (handle == 0) return null;
    return TrayIcon.fromHandle(handle);
  }

  List<TrayIcon> getAll() {
    final list = _bindings.native_tray_manager_get_all();
    final items = <TrayIcon>[];
    for (var i = 0; i < list.count; i++) {
      items.add(TrayIcon.fromHandle(list.tray_icons[i]));
    }
    final listPointer = pkg_ffi.calloc<c.native_tray_icon_list_t>();
    listPointer.ref = list;
    // The handles now belong to `items`; free just the array.
    _bindings.native_tray_icon_list_release(listPointer);
    pkg_ffi.calloc.free(listPointer);
    return items;
  }

}

