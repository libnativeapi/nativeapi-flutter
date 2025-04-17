import 'package:nativeapi/src/nativeapi_bindings.dart';
import 'package:nativeapi/src/nativeapi_bindings_generated.dart';

import 'window.dart';

class WindowManager {
  WindowManager._();

  static final WindowManager instance = WindowManager._();

  NativeApiBindings get _bindings => nativeApiBindings;

  List<Window> getAll() {
    return [];
  }

  Window getCurrent() {
    final nativeWindowId = _bindings.window_manager_get_current();
    return Window(id: nativeWindowId);
  }
}
