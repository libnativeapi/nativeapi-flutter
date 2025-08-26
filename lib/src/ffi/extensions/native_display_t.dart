import 'dart:ui';

import 'package:ffi/ffi.dart';
import 'package:nativeapi/src/display.dart';
import 'package:nativeapi/src/ffi/bindings_generated.dart';

extension DisplayDartify on native_display_t {
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
      position: Offset(0, 0),
      size: Size(0, 0),
      workArea: Rect.fromLTWH(0, 0, 0, 0),
      scaleFactor: scale_factor.toDouble(),
      isPrimary: is_primary,
    );
  }
}

extension DisplayListDartify on native_display_list_t {
  List<Display> dartify() {
    return [];
  }
}
