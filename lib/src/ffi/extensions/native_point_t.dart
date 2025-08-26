import 'dart:ui';

import 'package:nativeapi/src/ffi/bindings_generated.dart';

extension PointDartify on NativePoint {
  Offset dartify() {
    return Offset(x, y);
  }
}

extension PointDartify2 on native_point_t {
  Offset dartify() {
    return Offset(x, y);
  }
}
