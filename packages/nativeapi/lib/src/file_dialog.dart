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

enum FileDialogMode {
  openFile(0),
  openFiles(1),
  saveFile(2),
  selectFolder(3);

  const FileDialogMode(this.value);
  final int value;

  static FileDialogMode fromValue(int value) => switch (value) {
    0 => FileDialogMode.openFile,
    1 => FileDialogMode.openFiles,
    2 => FileDialogMode.saveFile,
    3 => FileDialogMode.selectFolder,
    _ => FileDialogMode.openFile,
  };

  c.native_file_dialog_mode_t get raw =>
      c.native_file_dialog_mode_t.fromValue(value);
}

enum FileDialogResult {
  none(0),
  accepted(1),
  cancelled(2),
  failed(3);

  const FileDialogResult(this.value);
  final int value;

  static FileDialogResult fromValue(int value) => switch (value) {
    0 => FileDialogResult.none,
    1 => FileDialogResult.accepted,
    2 => FileDialogResult.cancelled,
    3 => FileDialogResult.failed,
    _ => FileDialogResult.none,
  };

  c.native_file_dialog_result_t get raw =>
      c.native_file_dialog_result_t.fromValue(value);
}

class FileDialog {
  /// Adopts a handle returned by the C API and releases it when this
  /// object becomes unreachable.
  FileDialog.fromHandle(this.nativeHandle) {
    _finalizer.attach(this, nativeHandle, detach: this);
  }

  /// Wraps a handle owned elsewhere; releasing it stays the owner's job.
  FileDialog.borrowed(this.nativeHandle);

  /// The underlying handle-table entry.
  final int nativeHandle;

  static final Finalizer<int> _finalizer = Finalizer<int>(
    (handle) => _bindings.native_file_dialog_free(handle),
  );

  /// Releases the handle now instead of at collection.
  void dispose() {
    _finalizer.detach(this);
    _bindings.native_file_dialog_free(nativeHandle);
  }

  /// Creates a new `FileDialog`; returns null if the native side failed.
  static FileDialog? create(FileDialogMode mode) {
    final handle = _bindings.native_file_dialog_create(mode.raw);
    if (handle == 0) return null;
    return FileDialog.fromHandle(handle);
  }

  static bool isSupported() {
    return _bindings.native_file_dialog_is_supported();
  }

  bool setParentWindow(Window? window) {
    return _bindings.native_file_dialog_set_parent_window(
      nativeHandle,
      window?.nativeHandle ?? 0,
    );
  }

  bool setFileTypes(List<String> extensions) {
    final extensionsItems = pkg_ffi.calloc<ffi.Pointer<ffi.Char>>(
      extensions.length,
    );
    for (var i = 0; i < extensions.length; i++) {
      extensionsItems[i] = extensions[i].toNativeUtf8().cast<ffi.Char>();
    }
    final extensionsList = pkg_ffi.calloc<c.native_string_list_t>();
    extensionsList.ref.items = extensionsItems;
    extensionsList.ref.count = extensions.length;
    final result = _bindings.native_file_dialog_set_file_types(
      nativeHandle,
      extensionsList.ref,
    );
    for (var i = 0; i < extensions.length; i++) {
      pkg_ffi.calloc.free(extensionsItems[i]);
    }
    pkg_ffi.calloc.free(extensionsItems);
    pkg_ffi.calloc.free(extensionsList);
    return result;
  }

  bool setSuggestedFileName(String name) {
    final nameNative = name.toNativeUtf8().cast<ffi.Char>();
    final result = _bindings.native_file_dialog_set_suggested_file_name(
      nativeHandle,
      nameNative,
    );
    pkg_ffi.calloc.free(nameNative);
    return result;
  }

  DialogModality get modality {
    final raw = _bindings.native_file_dialog_get_modality(nativeHandle);
    return DialogModality.fromValue(raw.value);
  }

  set modality(DialogModality value) {
    _bindings.native_file_dialog_set_modality(nativeHandle, value.raw);
  }

  bool open() {
    return _bindings.native_file_dialog_open(nativeHandle);
  }

  bool close() {
    return _bindings.native_file_dialog_close(nativeHandle);
  }

  FileDialogResult get result {
    final raw = _bindings.native_file_dialog_get_result(nativeHandle);
    return FileDialogResult.fromValue(raw.value);
  }

  List<String> get paths {
    final list = _bindings.native_file_dialog_get_paths(nativeHandle);
    final items = <String>[];
    for (var i = 0; i < list.count; i++) {
      final item = list.items[i];
      if (item == ffi.nullptr) continue;
      items.add(item.cast<pkg_ffi.Utf8>().toDartString());
    }
    final listPointer = pkg_ffi.calloc<c.native_string_list_t>();
    listPointer.ref = list;
    _bindings.native_string_list_free(listPointer);
    pkg_ffi.calloc.free(listPointer);
    return items;
  }

  String? get lastError {
    final resultPointer = _bindings.native_file_dialog_get_last_error(
      nativeHandle,
    );
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }
}
