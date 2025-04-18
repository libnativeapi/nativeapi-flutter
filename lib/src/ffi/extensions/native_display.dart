import 'dart:ui';

import 'package:ffi/ffi.dart';
import 'package:nativeapi/src/display.dart';
import 'package:nativeapi/src/ffi/bindings_generated.dart';

extension DisplayDartify on NativeDisplay {
  Display dartify() {
    String id, name;
    try {
      id = this.id.cast<Utf8>().toDartString();
    } catch (e) {
      id = '';
    }
    try {
      name = this.name.cast<Utf8>().toDartString();
    } catch (e) {
      name = '';
    }

    return Display(
      id: id,
      name: name,
      size: Size(width, height),
      scaleFactor: scaleFactor,
    );
  }
}

extension DisplayListDartify on NativeDisplayList {
  List<Display> dartify() {
    return [];
  }
}
