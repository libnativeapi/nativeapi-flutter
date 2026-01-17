import 'dart:ffi';

import 'package:cnativeapi/cnativeapi.dart';
import 'package:ffi/ffi.dart' as ffi;
import 'package:nativeapi/src/dialog.dart';
import 'package:nativeapi/src/foundation/cnativeapi_bindings_mixin.dart';
import 'package:nativeapi/src/foundation/native_handle_wrapper.dart';

/// Dialog for displaying messages and simple prompts.
///
/// MessageDialog is used to display information, warnings, errors, or
/// questions to the user. It can be shown modally or non-modally.
///
/// This class inherits from [Dialog] and provides message-specific
/// functionality such as message text.
///
/// Example:
/// ```dart
/// // Simple message dialog
/// final dialog = MessageDialog(
///   'Update Available',
///   'A new version is available. Would you like to update?',
/// );
/// dialog.modality = DialogModality.application;
/// dialog.open();
/// ```
class MessageDialog extends Dialog
    with CNativeApiBindingsMixin
    implements NativeHandleWrapper<native_message_dialog_t> {
  final native_message_dialog_t _nativeHandle;

  /// Current modality setting.
  DialogModality _modality = DialogModality.none;

  /// Creates a message dialog with title and message.
  ///
  /// [title] is the dialog title.
  /// [message] is the dialog message.
  ///
  /// Example:
  /// ```dart
  /// final dialog = MessageDialog(
  ///   'Update Available',
  ///   'A new version is available. Would you like to update?',
  /// );
  /// dialog.modality = DialogModality.application;
  /// dialog.open();
  /// ```
  MessageDialog(String title, String message)
    : _nativeHandle = _createNative(title, message);

  static native_message_dialog_t _createNative(String title, String message) {
    final titlePtr = title.toNativeUtf8();
    final messagePtr = message.toNativeUtf8();
    try {
      return cnativeApiBindings.native_message_dialog_create(
        titlePtr.cast<Char>(),
        messagePtr.cast<Char>(),
      );
    } finally {
      ffi.malloc.free(titlePtr);
      ffi.malloc.free(messagePtr);
    }
  }

  @override
  native_message_dialog_t get nativeHandle => _nativeHandle;

  /// Sets the dialog title.
  set title(String value) {
    final titlePtr = value.toNativeUtf8();
    try {
      bindings.native_message_dialog_set_title(
        _nativeHandle,
        titlePtr.cast<Char>(),
      );
    } finally {
      ffi.malloc.free(titlePtr);
    }
  }

  /// Gets the dialog title.
  String get title {
    final titlePtr = bindings.native_message_dialog_get_title(_nativeHandle);
    if (titlePtr == nullptr) {
      return '';
    }
    final title = titlePtr.cast<ffi.Utf8>().toDartString();
    bindings.free_c_str(titlePtr);
    return title;
  }

  /// Sets the dialog message.
  set message(String value) {
    final messagePtr = value.toNativeUtf8();
    try {
      bindings.native_message_dialog_set_message(
        _nativeHandle,
        messagePtr.cast<Char>(),
      );
    } finally {
      ffi.malloc.free(messagePtr);
    }
  }

  /// Gets the dialog message.
  String get message {
    final messagePtr = bindings.native_message_dialog_get_message(
      _nativeHandle,
    );
    if (messagePtr == nullptr) {
      return '';
    }
    final message = messagePtr.cast<ffi.Utf8>().toDartString();
    bindings.free_c_str(messagePtr);
    return message;
  }

  @override
  DialogModality get modality {
    // Update internal state from native dialog
    final nativeModality = bindings.native_message_dialog_get_modality(
      _nativeHandle,
    );
    _modality = DialogModality.fromNative(nativeModality);
    return _modality;
  }

  @override
  set modality(DialogModality value) {
    _modality = value;
    bindings.native_message_dialog_set_modality(
      _nativeHandle,
      value.toNative(),
    );
  }

  @override
  bool open() {
    return bindings.native_message_dialog_open(_nativeHandle);
  }

  @override
  bool close() {
    return bindings.native_message_dialog_close(_nativeHandle);
  }

  @override
  void dispose() {
    bindings.native_message_dialog_destroy(_nativeHandle);
  }
}
