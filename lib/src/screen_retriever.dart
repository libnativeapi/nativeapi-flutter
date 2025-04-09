import 'dart:ui';

import 'package:ffi/ffi.dart';
import 'package:nativeapi/src/nativeapi_bindings_generated.dart';

import 'display.dart';
import 'nativeapi_bindings.dart';

class ScreenRetriever {
  ScreenRetriever();

  NativeApiBindings get _bindings => nativeApiBindings;

  Offset getCursorScreenPoint() {
    return _bindings.screen_retriever_get_cursor_screen_point().dartify();
  }

  Display getPrimaryDisplay() {
    return _bindings.screen_retriever_get_primary_display().dartify();
  }

  List<Display> getAllDisplays() {
    return _bindings.screen_retriever_get_all_displays().dartify();
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
