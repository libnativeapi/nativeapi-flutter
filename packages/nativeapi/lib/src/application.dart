// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;
import 'dart:ui';

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

import 'menu.dart';
import 'window.dart';

import 'support.dart';

final _bindings = c.cnativeApiBindings;

/// One `ApplicationEvent`, in its concrete form.
sealed class ApplicationEvent {
  const ApplicationEvent();

  /// Reads the event out of its C form. Returns null for a variant this
  /// binding does not know about.
  static ApplicationEvent? fromNative(c.native_application_event_t raw) {
    if (raw.type == c.native_application_event_type_t.NATIVE_APPLICATION_EVENT_TYPE_STARTED.value) {
      return ApplicationStartedEvent();
    }
    if (raw.type == c.native_application_event_type_t.NATIVE_APPLICATION_EVENT_TYPE_EXITING.value) {
      return ApplicationExitingEvent(exitCode: raw.data.exiting.exit_code);
    }
    if (raw.type == c.native_application_event_type_t.NATIVE_APPLICATION_EVENT_TYPE_ACTIVATED.value) {
      return ApplicationActivatedEvent();
    }
    if (raw.type == c.native_application_event_type_t.NATIVE_APPLICATION_EVENT_TYPE_DEACTIVATED.value) {
      return ApplicationDeactivatedEvent();
    }
    if (raw.type == c.native_application_event_type_t.NATIVE_APPLICATION_EVENT_TYPE_QUIT_REQUESTED.value) {
      return ApplicationQuitRequestedEvent();
    }
    return null;
  }
}

final class ApplicationStartedEvent extends ApplicationEvent {
  const ApplicationStartedEvent();
}

final class ApplicationExitingEvent extends ApplicationEvent {
  const ApplicationExitingEvent({required this.exitCode, });

  final int exitCode;
}

final class ApplicationActivatedEvent extends ApplicationEvent {
  const ApplicationActivatedEvent();
}

final class ApplicationDeactivatedEvent extends ApplicationEvent {
  const ApplicationDeactivatedEvent();
}

final class ApplicationQuitRequestedEvent extends ApplicationEvent {
  const ApplicationQuitRequestedEvent();
}

class Application {
  const Application._();

  /// The shared instance backed by the native singleton.
  static const Application instance = Application._();

  int run() {
    return _bindings.native_application_run();
  }

  int runWithWindow(Window? window) {
    return _bindings.native_application_run_with_window(window?.nativeHandle ?? 0);
  }

  void quit(int exitCode) {
    _bindings.native_application_quit(exitCode);
  }

  bool isRunning() {
    return _bindings.native_application_is_running();
  }

  bool isSingleInstance() {
    return _bindings.native_application_is_single_instance();
  }

  bool setIcon(String iconPath) {
    final iconPathNative = iconPath.toNativeUtf8().cast<ffi.Char>();
    final result = _bindings.native_application_set_icon(iconPathNative);
    pkg_ffi.calloc.free(iconPathNative);
    return result;
  }

  bool setDockIconVisible(bool visible) {
    return _bindings.native_application_set_dock_icon_visible(visible);
  }

  bool setMenuBar(Menu? menu) {
    return _bindings.native_application_set_menu_bar(menu?.nativeHandle ?? 0);
  }

  Window? getPrimaryWindow() {
    final handle = _bindings.native_application_get_primary_window();
    if (handle == 0) return null;
    return Window.fromHandle(handle);
  }

  void setPrimaryWindow(Window? window) {
    _bindings.native_application_set_primary_window(window?.nativeHandle ?? 0);
  }

  List<Window> getAllWindows() {
    final list = _bindings.native_application_get_all_windows();
    final items = <Window>[];
    for (var i = 0; i < list.count; i++) {
      items.add(Window.fromHandle(list.windows[i]));
    }
    final listPointer = pkg_ffi.calloc<c.native_window_list_t>();
    listPointer.ref = list;
    // The handles now belong to `items`; free just the array.
    _bindings.native_window_list_release(listPointer);
    pkg_ffi.calloc.free(listPointer);
    return items;
  }

  /// Registers [callback] for every `ApplicationEvent` this `Application` emits.
  ///
  /// The callback runs synchronously on whichever thread the native side
  /// dispatches from, because the event struct is freed as soon as it
  /// returns. That thread must therefore be this isolate's own; see the
  /// package README for what that means under Flutter.
  ListenerId addListener(void Function(ApplicationEvent) callback) {
    final callable = ffi.NativeCallable<
        ffi.Void Function(ffi.Pointer<c.native_application_event_t>, ffi.Pointer<ffi.Void>)>.isolateLocal(
      (ffi.Pointer<c.native_application_event_t> event, ffi.Pointer<ffi.Void> _) {
        if (event == ffi.nullptr) return;
        final value = ApplicationEvent.fromNative(event.ref);
        if (value != null) callback(value);
      },
    );
    _listeners.add(callable);  // keeps the trampoline alive
    return _bindings.native_application_add_listener(callable.nativeFunction, ffi.nullptr);
  }

  /// Unregisters a listener. Returns false if unknown.
  bool removeListener(ListenerId listenerId) =>
      _bindings.native_application_remove_listener(listenerId);

  /// Trampolines stay reachable for as long as the C side may call them.
  static final List<Object> _listeners = <Object>[];

}

