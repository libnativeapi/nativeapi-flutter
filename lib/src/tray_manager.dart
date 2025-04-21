import 'package:nativeapi/src/ffi/bindings.dart';
import 'package:nativeapi/src/ffi/bindings_generated.dart';

import 'tray.dart';

/// A class for managing trays.
///
/// This class provides methods for getting all trays and creating a new tray.
/// It is a singleton class.
class TrayManager {
  TrayManager._();

  /// The singleton instance of the TrayManager.
  static final TrayManager instance = TrayManager._();

  /// The native API bindings.
  NativeApiBindings get _bindings => nativeApiBindings;

  /// Create a new tray.
  ///
  /// Returns the new tray.
  Tray create() {
    final nativeTrayId = _bindings.tray_manager_create();
    return Tray(id: nativeTrayId);
  }

  /// Get a tray by its ID.
  ///
  /// Returns the tray.
  Tray get(int id) {
    return Tray(id: id);
  }

  /// Get all trays.
  ///
  /// Returns a list of all trays.
  List<Tray> getAll() {
    return [];
  }
}
