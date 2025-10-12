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

  TrayIcon? get(int trayIconId) {
    throw Exception('Method not implemented');
  }

  /// Returns a list of all tray icons.
  ///
  /// This method retrieves a list of all available tray icons using the native
  /// tray manager API. It then converts each tray icon handle into a Dart
  /// [TrayIcon] object and returns the list.
  List<TrayIcon> getAll() {
    throw Exception('Method not implemented');
  }

  @override
  String toString() => 'TrayManager()';
}
