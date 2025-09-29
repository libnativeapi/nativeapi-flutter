import 'package:ffi/ffi.dart' as ffi;
import 'dart:ffi';

import 'package:cnativeapi/cnativeapi.dart';

import 'display.dart';

class DisplayManager {
  DisplayManager._();

  static final DisplayManager _instance = DisplayManager._();
  static DisplayManager get instance => _instance;

  List<Display> getAllDisplays() {
    final displayList = cnativeApiBindings.native_display_manager_get_all();
    final displays = <Display>[];

    for (int i = 0; i < displayList.count; i++) {
      final displayPtr = displayList.displays.elementAt(i).value;
      displays.add(Display.fromHandle(displayPtr));
    }

    return displays;
  }

  Display? getPrimaryDisplay() {
    final primaryDisplay = cnativeApiBindings
        .native_display_manager_get_primary();
    if (primaryDisplay == nullptr) {
      return null;
    }
    return Display.fromHandle(primaryDisplay);
  }

  Point getCursorPosition() {
    final nativePoint = cnativeApiBindings
        .native_display_manager_get_cursor_position();
    return Point(nativePoint.x, nativePoint.y);
  }
}
