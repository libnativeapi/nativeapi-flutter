import 'dart:ui';

import 'package:ffi/ffi.dart' as ffi;
import 'dart:ffi' hide Size;

import 'package:cnativeapi/cnativeapi.dart';

enum DisplayOrientation {
  portrait(0),
  landscape(90),
  portraitFlipped(180),
  landscapeFlipped(270);

  const DisplayOrientation(this.value);
  final int value;

  static DisplayOrientation fromValue(int value) {
    switch (value) {
      case 0:
        return DisplayOrientation.portrait;
      case 90:
        return DisplayOrientation.landscape;
      case 180:
        return DisplayOrientation.portraitFlipped;
      case 270:
        return DisplayOrientation.landscapeFlipped;
      default:
        throw ArgumentError('Unknown display orientation value: $value');
    }
  }
}

class Display {
  final native_display_t _handle;

  Display(native_display_t handle) : _handle = handle;

  native_display_t get handle => _handle;

  String get id {
    final ptr = cnativeApiBindings.native_display_get_id(_handle);
    final id = ptr.cast<ffi.Utf8>().toDartString();
    cnativeApiBindings.native_display_free_string(ptr);
    return id;
  }

  String get name {
    final ptr = cnativeApiBindings.native_display_get_name(_handle);
    final name = ptr.cast<ffi.Utf8>().toDartString();
    cnativeApiBindings.native_display_free_string(ptr);
    return name;
  }

  Offset get position {
    final nativePoint = cnativeApiBindings.native_display_get_position(_handle);
    return Offset(nativePoint.x, nativePoint.y);
  }

  Size get size {
    final nativeSize = cnativeApiBindings.native_display_get_size(_handle);
    return Size(nativeSize.width, nativeSize.height);
  }

  Rect get workArea {
    final nativeRect = cnativeApiBindings.native_display_get_work_area(_handle);
    return Rect.fromLTWH(
      nativeRect.x,
      nativeRect.y,
      nativeRect.width,
      nativeRect.height,
    );
  }

  double get scaleFactor {
    return cnativeApiBindings.native_display_get_scale_factor(_handle);
  }

  bool get isPrimary {
    return cnativeApiBindings.native_display_is_primary(_handle);
  }

  DisplayOrientation get orientation {
    final nativeOrientation = cnativeApiBindings.native_display_get_orientation(
      _handle,
    );
    return DisplayOrientation.fromValue(nativeOrientation.value);
  }

  int get refreshRate {
    return cnativeApiBindings.native_display_get_refresh_rate(_handle);
  }

  int get bitDepth {
    return cnativeApiBindings.native_display_get_bit_depth(_handle);
  }

  String get manufacturer {
    final ptr = cnativeApiBindings.native_display_get_manufacturer(_handle);
    final manufacturer = ptr.cast<ffi.Utf8>().toDartString();
    cnativeApiBindings.native_display_free_string(ptr);
    return manufacturer;
  }

  String get model {
    final ptr = cnativeApiBindings.native_display_get_model(_handle);
    final model = ptr.cast<ffi.Utf8>().toDartString();
    cnativeApiBindings.native_display_free_string(ptr);
    return model;
  }

  String get serialNumber {
    final ptr = cnativeApiBindings.native_display_get_serial_number(_handle);
    final serialNumber = ptr.cast<ffi.Utf8>().toDartString();
    cnativeApiBindings.native_display_free_string(ptr);
    return serialNumber;
  }

  Pointer<Void> get nativeObject {
    return cnativeApiBindings.native_display_get_native_object(_handle);
  }

  void dispose() {
    cnativeApiBindings.native_display_free(_handle);
  }

  @override
  String toString() => 'Display(id: $id, name: $name)';
}
