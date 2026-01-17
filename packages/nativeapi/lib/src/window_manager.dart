import 'dart:ffi' hide Size;
import 'package:flutter/widgets.dart';
import 'package:nativeapi/src/foundation/cnativeapi_bindings_mixin.dart';
import 'package:nativeapi/src/foundation/event_emitter.dart';
import 'package:nativeapi/src/foundation/geometry.dart';
import 'package:nativeapi/src/window.dart';
import 'package:nativeapi/src/window_event.dart';

/// WindowManager is a singleton that manages all windows in the application.
///
/// The WindowManager provides a centralized interface for creating, managing, and
/// monitoring windows across the entire application. It follows the singleton pattern
/// to ensure there's only one instance managing all windows, and provides event
/// notifications for various window state changes.
///
/// Example:
/// ```dart
/// // Get the singleton instance
/// final windowManager = WindowManager.instance;
///
/// // Listen to window events
/// windowManager.addListener<WindowFocusedEvent>((event) {
///   print('Window focused: ${event.windowId}');
/// });
///
/// // Create a window
/// final window = windowManager.create(
///   title: 'My Window',
///   width: 800,
///   height: 600,
///   centered: true,
/// );
///
/// // Get a window by ID
/// final existingWindow = windowManager.getById(windowId);
///
/// // Get all windows
/// final allWindows = windowManager.getAll();
///
/// // Get the currently focused window
/// final currentWindow = windowManager.getCurrent();
/// ```
class WindowManager with EventEmitter, CNativeApiBindingsMixin {
  static final WindowManager _instance = WindowManager._();

  /// Returns the singleton instance of [WindowManager].
  static WindowManager get instance => _instance;

  // Native callable for window event callbacks
  static late final NativeCallable<
    Void Function(Pointer<native_window_event_t>, Pointer<Void>)
  >
  _eventCallback;

  static bool _callbackInitialized = false;
  static int? _eventListenerId;

  // Native callables for pre-show/hide hooks
  static NativeCallable<Void Function(native_window_id_t, Pointer<Void>)>?
  _willShowCallback;
  static NativeCallable<Void Function(native_window_id_t, Pointer<Void>)>?
  _willHideCallback;

  // Dart-side hook handlers
  bool Function(int windowId)? _onWillShowHook;
  bool Function(int windowId)? _onWillHideHook;

  /// Private constructor for singleton pattern.
  WindowManager._();

  @override
  void startEventListening() {
    // Initialize callback once
    if (!_callbackInitialized) {
      _eventCallback =
          NativeCallable<
            Void Function(Pointer<native_window_event_t>, Pointer<Void>)
          >.listener(_nativeOnWindowEvent);
      _callbackInitialized = true;
    }

    // Register the callback with the native window manager
    _eventListenerId = bindings.native_window_manager_register_event_callback(
      _eventCallback.nativeFunction,
      nullptr,
    );
  }

  @override
  void stopEventListening() {
    // Unregister the callback
    if (_eventListenerId != null) {
      bindings.native_window_manager_unregister_event_callback(
        _eventListenerId!,
      );
      _eventListenerId = null;
    }
  }

  // Static callback function for FFI
  static void _nativeOnWindowEvent(
    Pointer<native_window_event_t> eventPtr,
    Pointer<Void> userData,
  ) {
    final event = eventPtr.ref;
    final windowId = event.window_id;
    final eventType = native_window_event_type_t.fromValue(event.type);

    switch (eventType) {
      case native_window_event_type_t.NATIVE_WINDOW_EVENT_FOCUSED:
        _instance.emitSync(WindowFocusedEvent(windowId));
        break;
      case native_window_event_type_t.NATIVE_WINDOW_EVENT_BLURRED:
        _instance.emitSync(WindowBlurredEvent(windowId));
        break;
      case native_window_event_type_t.NATIVE_WINDOW_EVENT_MINIMIZED:
        _instance.emitSync(WindowMinimizedEvent(windowId));
        break;
      case native_window_event_type_t.NATIVE_WINDOW_EVENT_MAXIMIZED:
        _instance.emitSync(WindowMaximizedEvent(windowId));
        break;
      case native_window_event_type_t.NATIVE_WINDOW_EVENT_RESTORED:
        _instance.emitSync(WindowRestoredEvent(windowId));
        break;
      case native_window_event_type_t.NATIVE_WINDOW_EVENT_MOVED:
        final position = Offset(
          event.data.moved.position.x,
          event.data.moved.position.y,
        );
        _instance.emitSync(WindowMovedEvent(windowId, position));
        break;
      case native_window_event_type_t.NATIVE_WINDOW_EVENT_RESIZED:
        final size = Size(
          event.data.resized.size.width,
          event.data.resized.size.height,
        );
        _instance.emitSync(WindowResizedEvent(windowId, size));
        break;
    }
  }

  /// Gets a window by its ID.
  ///
  /// Returns the [Window] instance, or null if not found.
  Window? getById(int windowId) {
    final nativeWindow = bindings.native_window_manager_get(windowId);
    if (nativeWindow == nullptr) {
      return null;
    }
    return Window(nativeWindow);
  }

  /// Gets all managed windows.
  ///
  /// Returns a list of all [Window] instances.
  List<Window> getAll() {
    final windowList = bindings.native_window_manager_get_all();
    final windows = <Window>[];

    for (int i = 0; i < windowList.count; i++) {
      final nativeHandle = (windowList.windows + i).value;
      if (nativeHandle != nullptr) {
        windows.add(Window(nativeHandle));
      }
    }

    // Note: Memory management for window list is handled by native code
    // We don't need to manually free it here

    return windows;
  }

  /// Gets the currently active/focused window.
  ///
  /// Returns the [Window] instance, or null if no window is active.
  Window? getCurrent() {
    final nativeWindow = bindings.native_window_manager_get_current();
    if (nativeWindow == nullptr) {
      return null;
    }
    return Window(nativeWindow);
  }

  /// Shuts down the window manager and cleans up resources.
  ///
  /// This should typically be called when the application is exiting.
  void shutdown() {
    // Dispose event emitter (will call stopEventListening if needed)
    disposeEventEmitter();

    // Shutdown the native window manager
    bindings.native_window_manager_shutdown();
  }

  /// Set (or clear) the hook invoked BEFORE a native window is shown.
  /// Passing null clears the hook.
  void setWillShowHook(bool Function(int windowId)? callback) {
    _onWillShowHook = callback;

    // Clear current hook if requested
    if (callback == null) {
      bindings.native_window_manager_set_will_show_hook(nullptr, nullptr);
      _willShowCallback?.close();
      _willShowCallback = null;
      return;
    }

    // Use isolateLocal for synchronous execution on the same thread
    // This works because Flutter 3.22+ merges Dart isolate with platform thread
    _willShowCallback?.close();
    _willShowCallback =
        NativeCallable<
          Void Function(native_window_id_t, Pointer<Void>)
        >.listener(_nativeOnWillShow);
    bindings.native_window_manager_set_will_show_hook(
      _willShowCallback!.nativeFunction,
      nullptr,
    );
  }

  /// Set (or clear) the hook invoked BEFORE a native window is hidden.
  /// Passing null clears the hook.
  void setWillHideHook(bool Function(int windowId)? callback) {
    _onWillHideHook = callback;

    if (callback == null) {
      bindings.native_window_manager_set_will_hide_hook(nullptr, nullptr);
      _willHideCallback?.close();
      _willHideCallback = null;
      return;
    }

    // Use isolateLocal for synchronous execution on the same thread
    // This works because Flutter 3.22+ merges Dart isolate with platform thread
    _willHideCallback?.close();
    _willHideCallback =
        NativeCallable<
          Void Function(native_window_id_t, Pointer<Void>)
        >.listener(_nativeOnWillHide);
    bindings.native_window_manager_set_will_hide_hook(
      _willHideCallback!.nativeFunction,
      nullptr,
    );
  }

  // Native -> Dart bridge for pre-show hook
  static void _nativeOnWillShow(
    Dartnative_window_id_t windowId,
    Pointer<Void> userData,
  ) {
    final cb = _instance._onWillShowHook;
    if (cb != null) {
      bool result = cb(windowId);
      if (result) {
        _instance.bindings.native_window_manager_call_original_show(windowId);
      }
    }
  }

  // Native -> Dart bridge for pre-hide hook
  static void _nativeOnWillHide(
    Dartnative_window_id_t windowId,
    Pointer<Void> userData,
  ) {
    final cb = _instance._onWillHideHook;
    if (cb != null) {
      bool result = cb(windowId);
      if (result) {
        _instance.bindings.native_window_manager_call_original_hide(windowId);
      }
    }
  }
}
