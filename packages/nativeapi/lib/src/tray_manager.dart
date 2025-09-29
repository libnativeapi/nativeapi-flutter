import 'dart:ffi' as ffi;

import 'package:cnativeapi/cnativeapi.dart';

import 'tray_icon.dart';

class TrayManager {
  TrayManager._();

  static final TrayManager _instance = TrayManager._();
  static TrayManager get instance => _instance;

  final Map<String, TrayIcon> _trayIcons = {};

  Future<void> createTrayIcon(TrayIcon trayIcon) async {
    // TODO: Call native tray manager create function when available
    // final handle = cnativeApiBindings.native_tray_manager_create(trayIcon.id, ...);
    // final nativeTrayIcon = TrayIcon._(handle, ...);
    _trayIcons[trayIcon.id] = trayIcon;
  }

  Future<void> updateTrayIcon(String id, TrayIcon trayIcon) async {
    if (_trayIcons.containsKey(id)) {
      // TODO: Call native tray manager update function when available
      // cnativeApiBindings.native_tray_manager_update(id, ...);
      _trayIcons[id] = trayIcon;
    } else {
      throw ArgumentError('Tray icon with id "$id" not found');
    }
  }

  Future<void> removeTrayIcon(String id) async {
    final trayIcon = _trayIcons[id];
    if (trayIcon != null) {
      // TODO: Call native tray manager remove function when available
      // cnativeApiBindings.native_tray_manager_remove(id);
      trayIcon.dispose();
      _trayIcons.remove(id);
    }
  }

  TrayIcon? getTrayIcon(String id) {
    return _trayIcons[id];
  }

  List<TrayIcon> getAllTrayIcons() {
    return _trayIcons.values.toList();
  }

  bool hasTrayIcon(String id) {
    return _trayIcons.containsKey(id);
  }

  Future<void> showTrayIcon(String id) async {
    final trayIcon = _trayIcons[id];
    if (trayIcon == null) {
      throw ArgumentError('Tray icon with id "$id" not found');
    }
  }

  Future<void> hideTrayIcon(String id) async {
    final trayIcon = _trayIcons[id];
    if (trayIcon == null) {
      throw ArgumentError('Tray icon with id "$id" not found');
    }
  }

  Future<void> setTooltip(String id, String tooltip) async {
    final trayIcon = _trayIcons[id];
    if (trayIcon == null) {
      throw ArgumentError('Tray icon with id "$id" not found');
    }
    _trayIcons[id] = trayIcon.copyWith(tooltip: tooltip);
  }

  Future<void> clearAll() async {
    // TODO: Call native tray manager clear function when available
    // cnativeApiBindings.native_tray_manager_clear();
    for (final trayIcon in _trayIcons.values) {
      trayIcon.dispose();
    }
    _trayIcons.clear();
  }
}
