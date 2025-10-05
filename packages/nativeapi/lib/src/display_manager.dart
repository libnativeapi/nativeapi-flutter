import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:nativeapi/src/foundation/cnativeapi_bindings_mixin.dart';

import 'display.dart';

class DisplayManager with CNativeApiBindingsMixin {
  static final DisplayManager _instance = DisplayManager._();

  /// Returns the singleton instance of [DisplayManager].
  static DisplayManager get instance => _instance;

  /// Creates a new instance of [DisplayManager].
  ///
  /// This constructor is private to ensure that only one instance of [DisplayManager]
  /// can be created. It initializes the native display manager API bindings.
  DisplayManager._();

  /// Returns a list of all displays.
  ///
  /// This method retrieves a list of all available displays using the native
  /// display manager API. It then converts each display handle into a Dart
  /// [Display] object and returns the list.
  List<Display> getAll() {
    final displayList = bindings.native_display_manager_get_all();
    final displays = <Display>[];

    for (int i = 0; i < displayList.count; i++) {
      final nativeHandle = (displayList.displays + i).value;
      displays.add(Display(nativeHandle));
    }

    return displays;
  }

  /// Returns the current cursor position.
  ///
  /// This method retrieves the current cursor position using the native display
  /// manager API. It then converts the position into a Dart [Point] object and
  /// returns it.
  Offset getCursorPosition() {
    final nativePoint = bindings.native_display_manager_get_cursor_position();
    return Offset(nativePoint.x, nativePoint.y);
  }

  /// Returns the primary display.
  ///
  /// This method retrieves the primary display using the native display manager
  /// API. It then converts the display handle into a Dart [Display] object and
  /// returns it.
  Display? getPrimary() {
    final nativeHandle = bindings.native_display_manager_get_primary();
    if (nativeHandle == nullptr) {
      return null;
    }
    return Display(nativeHandle);
  }
}
