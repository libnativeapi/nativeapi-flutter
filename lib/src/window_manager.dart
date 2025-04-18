import 'package:nativeapi/src/ffi/bindings.dart';
import 'package:nativeapi/src/ffi/bindings_generated.dart';

import 'window.dart';

/// A class for managing windows.
///
/// This class provides methods for getting all windows and the current window.
/// It is a singleton class.
class WindowManager {
  WindowManager._();

  /// The singleton instance of the WindowManager.
  static final WindowManager instance = WindowManager._();

  /// The native API bindings.
  NativeApiBindings get _bindings => nativeApiBindings;

  /// Get all windows.
  ///
  /// Returns a list of all windows.
  List<Window> getAll() {
    return [];
  }

  /// Get the current window.
  ///
  /// Returns the current window.
  Window getCurrent() {
    final nativeWindowId = _bindings.window_manager_get_current();
    return Window(id: nativeWindowId);
  }
}
