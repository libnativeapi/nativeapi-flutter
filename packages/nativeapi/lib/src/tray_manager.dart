import 'dart:ffi';
import 'package:ffi/ffi.dart' as ffi;
import 'dart:typed_data';

import 'package:cnativeapi/cnativeapi.dart';
import 'tray_icon.dart';

class TrayManager {
  TrayManager._();

  static final TrayManager _instance = TrayManager._();
  static TrayManager get instance => _instance;

  static bool get isSupported {
    return cnativeApiBindings.native_tray_manager_is_supported();
  }

  TrayIcon? createTrayIcon() {
    final handle = cnativeApiBindings.native_tray_manager_create();
    if (handle == nullptr) {
      return null;
    }
    return TrayIcon(handle);
  }

  TrayIcon? getTrayIcon(int trayIconId) {
    final handle = cnativeApiBindings.native_tray_manager_get(trayIconId);
    if (handle == nullptr) {
      return null;
    }
    return TrayIcon(handle);
  }

  List<TrayIcon> getAllTrayIcons() {
    final trayIconList = cnativeApiBindings.native_tray_manager_get_all();
    final result = <TrayIcon>[];

    if (trayIconList.count > 0 && trayIconList.tray_icons != nullptr) {
      for (int i = 0; i < trayIconList.count; i++) {
        final handle = trayIconList.tray_icons.elementAt(i).value;
        if (handle != nullptr) {
          result.add(TrayIcon(handle));
        }
      }
    }

    // Free the native list
    cnativeApiBindings.native_tray_icon_list_free(trayIconList);

    return result;
  }

  bool destroyTrayIcon(int trayIconId) {
    return cnativeApiBindings.native_tray_manager_destroy(trayIconId);
  }

  @override
  String toString() => 'TrayManager()';
}
