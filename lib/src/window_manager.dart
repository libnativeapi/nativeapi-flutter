import 'package:nativeapi/src/ffi/bindings.dart';
import 'package:nativeapi/src/ffi/bindings_generated.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart' as ffi;

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
    final windowIdList = _bindings.window_manager_get_all();
    final List<int> idList = List.generate(
      windowIdList.count,
      (index) => windowIdList.ids[index],
    );
    ffi.malloc.free(windowIdList.ids);
    return idList.map((id) => Window(id: id)).toList();
  }

  /// Get the current window.
  ///
  /// Returns the current window.
  Window getCurrent() {
    final nativeWindowId = _bindings.window_manager_get_current();
    return Window(id: nativeWindowId);
  }
}
