import 'dart:ui';

import 'package:nativeapi/src/nativeapi_bindings.dart';
import 'package:nativeapi/src/nativeapi_bindings_generated.dart';

class Window {
  NativeApiBindings get _bindings => nativeApiBindings;

  final int id;

  Window({required this.id});

  // Get the size of the window.
  Size get size {
    final nativeSize = _bindings.window_get_size(id);
    return Size(nativeSize.width, nativeSize.height);
  }

  void addListener(VoidCallback listener) {}
}
