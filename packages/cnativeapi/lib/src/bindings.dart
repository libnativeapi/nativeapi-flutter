import 'dart:ffi';
import 'dart:io';

import 'bindings_generated.dart';

const String _libName = 'cnativeapi';

/// The dynamic library in which the symbols for [NativeApiBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.process();
  }
  if (Platform.isAndroid || Platform.isLinux || Platform.isOhos) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final CNativeApiBindings cnativeApiBindings = CNativeApiBindings(_dylib);
