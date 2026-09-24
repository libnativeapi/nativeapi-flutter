// Prints what the C API reports about this machine. Run with
// `dart run example/cnativeapi_example.dart`; the build hook compiles the
// native library first.

import 'dart:ffi';

import 'package:cnativeapi/cnativeapi.dart';
import 'package:ffi/ffi.dart';

void main() {
  print(
    'OS:           ${_take(native_device_info_get_os_name())} '
    '${_take(native_device_info_get_os_version())}',
  );
  print('Architecture: ${_take(native_device_info_get_architecture())}');
  print('Device:       ${_take(native_device_info_get_model())}');
}

/// Reads a string the C API allocated and frees it.
String _take(Pointer<Char> pointer) {
  if (pointer == nullptr) return '(unknown)';
  final value = pointer.cast<Utf8>().toDartString();
  free_c_str(pointer);
  return value;
}
