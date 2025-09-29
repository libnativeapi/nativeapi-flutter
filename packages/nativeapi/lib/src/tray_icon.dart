import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:cnativeapi/cnativeapi.dart';

import 'menu.dart';

class TrayIcon {
  TrayIcon({
    required this.id,
    this.iconPath,
    this.iconData,
    this.tooltip,
    this.menu,
    this.onClicked,
    this.onDoubleClicked,
    this.onRightClicked,
  }) : _handle = ffi.nullptr;

  TrayIcon._(
    this._handle, {
    required this.id,
    this.iconPath,
    this.iconData,
    this.tooltip,
    this.menu,
    this.onClicked,
    this.onDoubleClicked,
    this.onRightClicked,
  });

  final ffi.Pointer<ffi.Void> _handle;
  final String id;
  final String? iconPath;
  final Uint8List? iconData;
  final String? tooltip;
  final Menu? menu;
  final void Function()? onClicked;
  final void Function()? onDoubleClicked;
  final void Function()? onRightClicked;

  TrayIcon copyWith({
    String? id,
    String? iconPath,
    Uint8List? iconData,
    String? tooltip,
    Menu? menu,
    void Function()? onClicked,
    void Function()? onDoubleClicked,
    void Function()? onRightClicked,
  }) {
    return TrayIcon(
      id: id ?? this.id,
      iconPath: iconPath ?? this.iconPath,
      iconData: iconData ?? this.iconData,
      tooltip: tooltip ?? this.tooltip,
      menu: menu ?? this.menu,
      onClicked: onClicked ?? this.onClicked,
      onDoubleClicked: onDoubleClicked ?? this.onDoubleClicked,
      onRightClicked: onRightClicked ?? this.onRightClicked,
    );
  }

  void dispose() {
    if (_handle != ffi.nullptr) {
      // TODO: Call native tray icon free function when available
      // cnativeApiBindings.native_tray_icon_free(_handle);
    }
  }

  @override
  String toString() => 'TrayIcon(id: $id, tooltip: $tooltip)';
}
