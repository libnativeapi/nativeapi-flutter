// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;
import 'dart:ui';

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

import 'dialog.dart';

final _bindings = c.cnativeApiBindings;

class MessageDialog {
  /// Adopts a handle returned by the C API and releases it when this
  /// object becomes unreachable.
  MessageDialog.fromHandle(this.nativeHandle) {
    _finalizer.attach(this, nativeHandle, detach: this);
  }

  /// Wraps a handle owned elsewhere; releasing it stays the owner's job.
  MessageDialog.borrowed(this.nativeHandle);

  /// The underlying handle-table entry.
  final int nativeHandle;

  static final Finalizer<int> _finalizer = Finalizer<int>(
    (handle) => _bindings.native_message_dialog_free(handle),
  );

  /// Releases the handle now instead of at collection.
  void dispose() {
    _finalizer.detach(this);
    _bindings.native_message_dialog_free(nativeHandle);
  }

  /// Creates a new `MessageDialog`; returns null if the native side failed.
  static MessageDialog? create(String title, String message) {
    final titleNative = title.toNativeUtf8().cast<ffi.Char>();
    final messageNative = message.toNativeUtf8().cast<ffi.Char>();
    final handle = _bindings.native_message_dialog_create(titleNative, messageNative);
    pkg_ffi.calloc.free(titleNative);
    pkg_ffi.calloc.free(messageNative);
    if (handle == 0) return null;
    return MessageDialog.fromHandle(handle);
  }

  set title(String value) {
    final valueNative = value.toNativeUtf8().cast<ffi.Char>();
    _bindings.native_message_dialog_set_title(nativeHandle, valueNative);
    pkg_ffi.calloc.free(valueNative);
  }

  String? get title {
    final resultPointer = _bindings.native_message_dialog_get_title(nativeHandle);
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }

  set message(String value) {
    final valueNative = value.toNativeUtf8().cast<ffi.Char>();
    _bindings.native_message_dialog_set_message(nativeHandle, valueNative);
    pkg_ffi.calloc.free(valueNative);
  }

  String? get message {
    final resultPointer = _bindings.native_message_dialog_get_message(nativeHandle);
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }

  DialogModality get modality {
    final raw = _bindings.native_message_dialog_get_modality(nativeHandle);
    return DialogModality.fromValue(raw.value);
  }

  set modality(DialogModality value) {
    _bindings.native_message_dialog_set_modality(nativeHandle, value.raw);
  }

  bool open() {
    return _bindings.native_message_dialog_open(nativeHandle);
  }

  bool close() {
    return _bindings.native_message_dialog_close(nativeHandle);
  }

}

