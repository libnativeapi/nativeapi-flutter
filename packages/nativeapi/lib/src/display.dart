import 'package:ffi/ffi.dart' as ffi;
import 'dart:ffi';

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

class Point {
  const Point(this.x, this.y);
  final double x;
  final double y;

  @override
  String toString() => 'Point($x, $y)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

class Size {
  const Size(this.width, this.height);
  final double width;
  final double height;

  @override
  String toString() => 'Size($width, $height)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Size &&
          runtimeType == other.runtimeType &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => width.hashCode ^ height.hashCode;
}

class Rectangle {
  const Rectangle(this.x, this.y, this.width, this.height);
  final double x;
  final double y;
  final double width;
  final double height;

  Point get position => Point(x, y);
  Size get size => Size(width, height);

  @override
  String toString() => 'Rectangle($x, $y, $width, $height)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Rectangle &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode =>
      x.hashCode ^ y.hashCode ^ width.hashCode ^ height.hashCode;
}

class Display {
  Display._(this._handle);

  Display.fromHandle(native_display_t handle) : _handle = handle;

  final native_display_t _handle;

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

  Point get position {
    final nativePoint = cnativeApiBindings.native_display_get_position(_handle);
    return Point(nativePoint.x, nativePoint.y);
  }

  Size get size {
    final nativeSize = cnativeApiBindings.native_display_get_size(_handle);
    return Size(nativeSize.width, nativeSize.height);
  }

  Rectangle get workArea {
    final nativeRect = cnativeApiBindings.native_display_get_work_area(_handle);
    return Rectangle(
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
