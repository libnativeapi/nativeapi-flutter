import 'dart:ui';

import 'package:ffi/ffi.dart';
import 'package:nativeapi/src/nativeapi_bindings_generated.dart';

import 'display.dart';
import 'nativeapi_bindings.dart';

class DisplayManager {
  DisplayManager();

  NativeApiBindings get _bindings => nativeApiBindings;

  Offset getCursorPosition() {
    return _bindings.display_manager_get_cursor_position().dartify();
  }

  Display getPrimary() {
    return _bindings.display_manager_get_primary().dartify();
  }

  List<Display> getAll() {
    return _bindings.display_manager_get_all().dartify();
  }
}

extension on NativeDisplay {
  Display dartify() {
    return Display(
      id: id.cast<Utf8>().toDartString(),
      name: name.cast<Utf8>().toDartString(),
      size: Size(width, height),
      scaleFactor: scaleFactor,
    );
  }
}

extension on NativeDisplayList {
  List<Display> dartify() {
    return [];
  }
}

extension on NativePoint {
  Offset dartify() {
    return Offset(x, y);
  }
}
