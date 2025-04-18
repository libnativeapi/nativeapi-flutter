import 'dart:ui';

import 'package:nativeapi/src/ffi/bindings_generated.dart';

extension PointDartify on NativePoint {
  Offset dartify() {
    return Offset(x, y);
  }
}
