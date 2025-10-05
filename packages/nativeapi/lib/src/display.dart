import 'package:ffi/ffi.dart' as ffi;
import 'dart:ffi' hide Size;

import 'foundation/cnativeapi_bindings_mixin.dart';
import 'foundation/geometry.dart';
import 'foundation/native_handle_wrapper.dart';

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

class Display
    with CNativeApiBindingsMixin
    implements NativeHandleWrapper<native_display_t> {
  final native_display_t _nativeHandle;

  Display(native_display_t nativeHandle) : _nativeHandle = nativeHandle;

  @override
  native_display_t get nativeHandle => _nativeHandle;

  @override
  void dispose() {
    bindings.native_display_free(_nativeHandle);
  }

  String get id {
    final idPtr = bindings.native_display_get_id(_nativeHandle);
    final id = idPtr.cast<ffi.Utf8>().toDartString();
    bindings.native_display_free_string(idPtr);
    return id;
  }

  String get name {
    final namePtr = bindings.native_display_get_name(_nativeHandle);
    final name = namePtr.cast<ffi.Utf8>().toDartString();
    bindings.native_display_free_string(namePtr);
    return name;
  }

  Offset get position {
    final nativePoint = bindings.native_display_get_position(_nativeHandle);
    return Offset(nativePoint.x, nativePoint.y);
  }

  Size get size {
    final nativeSize = bindings.native_display_get_size(_nativeHandle);
    return Size(nativeSize.width, nativeSize.height);
  }

  Rect get workArea {
    final nativeRect = bindings.native_display_get_work_area(_nativeHandle);
    return Rect.fromLTWH(
      nativeRect.x,
      nativeRect.y,
      nativeRect.width,
      nativeRect.height,
    );
  }

  double get scaleFactor {
    return bindings.native_display_get_scale_factor(_nativeHandle);
  }

  bool get isPrimary {
    return bindings.native_display_is_primary(_nativeHandle);
  }

  DisplayOrientation get orientation {
    final nativeOrientation = bindings.native_display_get_orientation(
      _nativeHandle,
    );
    return DisplayOrientation.fromValue(nativeOrientation.value);
  }

  int get refreshRate {
    return bindings.native_display_get_refresh_rate(_nativeHandle);
  }

  int get bitDepth {
    return bindings.native_display_get_bit_depth(_nativeHandle);
  }

  String get manufacturer {
    final ptr = bindings.native_display_get_manufacturer(_nativeHandle);
    final manufacturer = ptr.cast<ffi.Utf8>().toDartString();
    bindings.native_display_free_string(ptr);
    return manufacturer;
  }

  String get model {
    final ptr = bindings.native_display_get_model(_nativeHandle);
    final model = ptr.cast<ffi.Utf8>().toDartString();
    bindings.native_display_free_string(ptr);
    return model;
  }

  String get serialNumber {
    final ptr = bindings.native_display_get_serial_number(_nativeHandle);
    final serialNumber = ptr.cast<ffi.Utf8>().toDartString();
    bindings.native_display_free_string(ptr);
    return serialNumber;
  }

  Pointer<Void> get nativeObject {
    return bindings.native_display_get_native_object(_nativeHandle);
  }

  @override
  String toString() => 'Display(id: $id, name: $name)';
}
