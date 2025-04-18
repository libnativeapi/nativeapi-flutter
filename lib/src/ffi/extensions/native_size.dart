import 'dart:ui';

import 'package:nativeapi/src/ffi/bindings_generated.dart';

extension SizeDartify on NativeSize {
  Size dartify() {
    return Size(width, height);
  }
}
