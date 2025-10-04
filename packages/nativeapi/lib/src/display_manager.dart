import 'dart:ffi';

import 'package:cnativeapi/cnativeapi.dart';
import 'package:flutter/material.dart';

import 'display.dart';

class DisplayManager {
  DisplayManager._();

  static final DisplayManager _instance = DisplayManager._();
  static DisplayManager get instance => _instance;

  /// Returns a list of all displays.
  ///
  /// This method retrieves a list of all available displays using the native
  /// display manager API. It then converts each display handle into a Dart
  /// [Display] object and returns the list.
  List<Display> getAll() {
    final displayList = cnativeApiBindings.native_display_manager_get_all();
    final displays = <Display>[];

    for (int i = 0; i < displayList.count; i++) {
      final displayPtr = displayList.displays.elementAt(i).value;
      displays.add(Display(displayPtr));
    }

    return displays;
  }

  /// Returns the primary display.
  ///
  /// This method retrieves the primary display using the native display manager
  /// API. It then converts the display handle into a Dart [Display] object and
  /// returns it.
  Display? getPrimary() {
    final primaryDisplay = cnativeApiBindings
        .native_display_manager_get_primary();
    if (primaryDisplay == nullptr) {
      return null;
    }
    return Display(primaryDisplay);
  }

  /// Returns the current cursor position.
  ///
  /// This method retrieves the current cursor position using the native display
  /// manager API. It then converts the position into a Dart [Point] object and
  /// returns it.
  Offset getCursorPosition() {
    final nativePoint = cnativeApiBindings
        .native_display_manager_get_cursor_position();
    return Offset(nativePoint.x, nativePoint.y);
  }
}
