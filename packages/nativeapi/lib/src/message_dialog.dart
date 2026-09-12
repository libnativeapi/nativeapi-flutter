// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;
import 'dart:ui';

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

import 'dialog.dart';
import 'window.dart';

final _bindings = c.cnativeApiBindings;

enum MessageDialogResult {
  none(0),
  primary(1),
  secondary(2),
  close(3);

  const MessageDialogResult(this.value);
  final int value;

  static MessageDialogResult fromValue(int value) => switch (value) {
    0 => MessageDialogResult.none,
    1 => MessageDialogResult.primary,
    2 => MessageDialogResult.secondary,
    3 => MessageDialogResult.close,
    _ => MessageDialogResult.none,
  };

  c.native_message_dialog_result_t get raw => c.native_message_dialog_result_t.fromValue(value);
}

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

  static bool isExtendedSupported() {
    return _bindings.native_message_dialog_is_extended_supported();
  }

  bool setButtons(String primary, String secondary, String close) {
    final primaryNative = primary.toNativeUtf8().cast<ffi.Char>();
    final secondaryNative = secondary.toNativeUtf8().cast<ffi.Char>();
    final closeNative = close.toNativeUtf8().cast<ffi.Char>();
    final result = _bindings.native_message_dialog_set_buttons(nativeHandle, primaryNative, secondaryNative, closeNative);
    pkg_ffi.calloc.free(primaryNative);
    pkg_ffi.calloc.free(secondaryNative);
    pkg_ffi.calloc.free(closeNative);
    return result;
  }

  bool setDefaultButton(MessageDialogResult button) {
    return _bindings.native_message_dialog_set_default_button(nativeHandle, button.raw);
  }

  bool setParentWindow(Window? window) {
    return _bindings.native_message_dialog_set_parent_window(nativeHandle, window?.nativeHandle ?? 0);
  }

  MessageDialogResult get result {
    final raw = _bindings.native_message_dialog_get_result(nativeHandle);
    return MessageDialogResult.fromValue(raw.value);
  }

  bool get isOpen {
    return _bindings.native_message_dialog_is_open(nativeHandle);
  }

  bool setInputEnabled(bool enabled) {
    return _bindings.native_message_dialog_set_input_enabled(nativeHandle, enabled);
  }

  bool setInputText(String text) {
    final textNative = text.toNativeUtf8().cast<ffi.Char>();
    final result = _bindings.native_message_dialog_set_input_text(nativeHandle, textNative);
    pkg_ffi.calloc.free(textNative);
    return result;
  }

  String? get inputText {
    final resultPointer = _bindings.native_message_dialog_get_input_text(nativeHandle);
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }

  bool setCheckbox(String label, bool checked) {
    final labelNative = label.toNativeUtf8().cast<ffi.Char>();
    final result = _bindings.native_message_dialog_set_checkbox(nativeHandle, labelNative, checked);
    pkg_ffi.calloc.free(labelNative);
    return result;
  }

  bool get isCheckboxChecked {
    return _bindings.native_message_dialog_is_checkbox_checked(nativeHandle);
  }

  bool setProgress(double value) {
    return _bindings.native_message_dialog_set_progress(nativeHandle, value);
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

