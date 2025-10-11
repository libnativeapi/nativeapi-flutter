import 'dart:ffi';

import 'package:cnativeapi/cnativeapi.dart';
import 'package:nativeapi/src/foundation/cnativeapi_bindings_mixin.dart';
import 'package:nativeapi/src/tray_icon.dart';

class TrayManager with CNativeApiBindingsMixin {
  static final TrayManager _instance = TrayManager._();

  /// Returns the singleton instance of [TrayManager].
  static TrayManager get instance => _instance;

  /// Creates a new instance of [TrayManager].
  ///
  /// This constructor is private to ensure that only one instance of [TrayManager]
  /// can be created. It initializes the native tray manager API bindings.
  TrayManager._();

  bool get isSupported {
    return cnativeApiBindings.native_tray_manager_is_supported();
  }

  TrayIcon create() {
    final handle = cnativeApiBindings.native_tray_manager_create();
    if (handle == nullptr) {
      throw Exception('Failed to create tray icon');
    }
    return TrayIcon(handle);
  }

  TrayIcon? get(int trayIconId) {
    final handle = cnativeApiBindings.native_tray_manager_get(trayIconId);
    if (handle == nullptr) {
      return null;
    }
    return TrayIcon(handle);
  }

  /// Returns a list of all tray icons.
  ///
  /// This method retrieves a list of all available tray icons using the native
  /// tray manager API. It then converts each tray icon handle into a Dart
  /// [TrayIcon] object and returns the list.
  List<TrayIcon> getAll() {
    final trayIconList = bindings.native_tray_manager_get_all();
    final trayIcons = <TrayIcon>[];

    for (int i = 0; i < trayIconList.count; i++) {
      final nativeHandle = (trayIconList.tray_icons + i).value;
      trayIcons.add(TrayIcon(nativeHandle));
    }

    bindings.native_tray_icon_list_free(trayIconList);

    return trayIcons;
  }

  bool destroy(int trayIconId) {
    return cnativeApiBindings.native_tray_manager_destroy(trayIconId);
  }

  @override
  String toString() => 'TrayManager()';
}
