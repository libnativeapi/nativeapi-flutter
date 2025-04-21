import 'dart:ffi';
import 'dart:ui';

import 'package:ffi/ffi.dart';
import 'package:nativeapi/src/ffi/bindings.dart';
import 'package:nativeapi/src/ffi/bindings_generated.dart';

/// A class for representing a tray.
///
/// This class provides methods for setting the icon, title, and tooltip of a tray.
class Tray {
  /// The native API bindings.
  NativeApiBindings get _bindings => nativeApiBindings;

  /// The ID of the tray.
  final int id;

  /// Creates a new tray.
  Tray({required this.id});

  /// Sets the icon of the tray.
  void setIcon(String icon) {
    _bindings.tray_set_icon(id, icon.toNativeUtf8().cast<Char>());
  }

  /// Sets the title of the tray.
  void setTitle(String title) {
    _bindings.tray_set_title(id, title.toNativeUtf8().cast<Char>());
  }

  /// Gets the title of the tray.
  String getTitle() {
    return _bindings.tray_get_title(id).cast<Utf8>().toDartString();
  }

  /// Sets the tooltip of the tray.
  void setTooltip(String tooltip) {
    _bindings.tray_set_tooltip(id, tooltip.toNativeUtf8().cast<Char>());
  }

  /// Gets the tooltip of the tray.
  String getTooltip() {
    return _bindings.tray_get_tooltip(id).cast<Utf8>().toDartString();
  }

  void addListener(VoidCallback listener) {}

  @override
  int get hashCode => id.hashCode;

  @override
  operator ==(Object other) {
    return other is Tray && other.id == id;
  }
}
