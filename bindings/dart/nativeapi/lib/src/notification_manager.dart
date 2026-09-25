// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

import 'support.dart';

import 'callbacks.dart';

/// One `NotificationEvent`, in its concrete form.
sealed class NotificationEvent {
  const NotificationEvent();

  /// Reads the event out of its C form. Returns null for a variant this
  /// binding does not know about.
  static NotificationEvent? fromNative(c.native_notification_event_t raw) {
    if (raw.typeAsInt ==
        c
            .native_notification_event_type_t
            .NATIVE_NOTIFICATION_EVENT_TYPE_ACTIVATED
            .value) {
      return NotificationActivatedEvent(
        argument: raw.data.activated.argument == ffi.nullptr
            ? null
            : raw.data.activated.argument.cast<pkg_ffi.Utf8>().toDartString(),
      );
    }
    return null;
  }
}

final class NotificationActivatedEvent extends NotificationEvent {
  const NotificationActivatedEvent({required this.argument});

  final String? argument;
}

class NotificationManager {
  const NotificationManager._();

  /// The shared instance backed by the native singleton.
  static const NotificationManager instance = NotificationManager._();

  bool isSupported() {
    return c.native_notification_manager_is_supported();
  }

  bool initialize() {
    return c.native_notification_manager_initialize();
  }

  void shutdown() {
    c.native_notification_manager_shutdown();
  }

  bool show(String title, String message, String tag, String buttonLabel) {
    final titleNative = title.toNativeUtf8().cast<ffi.Char>();
    final messageNative = message.toNativeUtf8().cast<ffi.Char>();
    final tagNative = tag.toNativeUtf8().cast<ffi.Char>();
    final buttonLabelNative = buttonLabel.toNativeUtf8().cast<ffi.Char>();
    final result = c.native_notification_manager_show(
      titleNative,
      messageNative,
      tagNative,
      buttonLabelNative,
    );
    pkg_ffi.calloc.free(titleNative);
    pkg_ffi.calloc.free(messageNative);
    pkg_ffi.calloc.free(tagNative);
    pkg_ffi.calloc.free(buttonLabelNative);
    return result;
  }

  bool remove(String tag) {
    final tagNative = tag.toNativeUtf8().cast<ffi.Char>();
    final result = c.native_notification_manager_remove(tagNative);
    pkg_ffi.calloc.free(tagNative);
    return result;
  }

  String? getLastError() {
    final resultPointer = c.native_notification_manager_get_last_error();
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    c.free_c_str(resultPointer);
    return result;
  }

  /// Registers [callback] for every `NotificationEvent` this `NotificationManager` emits.
  ///
  /// The callback runs synchronously on whichever thread the native side
  /// dispatches from, because the event struct is freed as soon as it
  /// returns. That thread must therefore be this isolate's own; see the
  /// package README for what that means under Flutter.
  ListenerId addListener(void Function(NotificationEvent) callback) {
    final callable =
        ffi.NativeCallable<
          ffi.Void Function(
            ffi.Pointer<c.native_notification_event_t>,
            ffi.Pointer<ffi.Void>,
          )
        >.isolateLocal((
          ffi.Pointer<c.native_notification_event_t> event,
          ffi.Pointer<ffi.Void> _,
        ) {
          if (event == ffi.nullptr) return;
          final value = NotificationEvent.fromNative(event.ref);
          if (value != null) callback(value);
        });
    return c.native_notification_manager_add_listener(
      callable.nativeFunction,
      NativeCallbacks.userData(callable),
      NativeCallbacks.release,
    );
  }

  /// Unregisters a listener. Returns false if unknown.
  bool removeListener(ListenerId listenerId) =>
      c.native_notification_manager_remove_listener(listenerId);
}
