// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;
import 'dart:ui';

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

import 'foundation/geometry.dart';

final _bindings = c.cnativeApiBindings;

class Image {
  /// Adopts a handle returned by the C API and releases it when this
  /// object becomes unreachable.
  Image.fromHandle(this.nativeHandle) {
    _finalizer.attach(this, nativeHandle, detach: this);
  }

  /// Wraps a handle owned elsewhere; releasing it stays the owner's job.
  Image.borrowed(this.nativeHandle);

  /// The underlying handle-table entry.
  final int nativeHandle;

  static final Finalizer<int> _finalizer = Finalizer<int>(
    (handle) => _bindings.native_image_free(handle),
  );

  /// Releases the handle now instead of at collection.
  void dispose() {
    _finalizer.detach(this);
    _bindings.native_image_free(nativeHandle);
  }

  static Image? fromFile(String filePath) {
    final filePathNative = filePath.toNativeUtf8().cast<ffi.Char>();
    final handle = _bindings.native_image_from_file(filePathNative);
    pkg_ffi.calloc.free(filePathNative);
    if (handle == 0) return null;
    return Image.fromHandle(handle);
  }

  static Image? fromBase64(String base64Data) {
    final base64DataNative = base64Data.toNativeUtf8().cast<ffi.Char>();
    final handle = _bindings.native_image_from_base64(base64DataNative);
    pkg_ffi.calloc.free(base64DataNative);
    if (handle == 0) return null;
    return Image.fromHandle(handle);
  }

  Size get size {
    final raw = _bindings.native_image_get_size(nativeHandle);
    return Size(raw.width, raw.height);
  }

  String? get format {
    final resultPointer = _bindings.native_image_get_format(nativeHandle);
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }

  String? toBase64() {
    final resultPointer = _bindings.native_image_to_base64(nativeHandle);
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }

  bool saveToFile(String filePath) {
    final filePathNative = filePath.toNativeUtf8().cast<ffi.Char>();
    final result = _bindings.native_image_save_to_file(nativeHandle, filePathNative);
    pkg_ffi.calloc.free(filePathNative);
    return result;
  }

  /// Platform-specific native object behind this handle.
  ffi.Pointer<ffi.Void> get nativeObject =>
      _bindings.native_image_get_native_object(nativeHandle);

}

