import 'dart:ffi' hide Size;
import 'package:ffi/ffi.dart' as ffi;
import 'package:nativeapi/src/foundation/cnativeapi_bindings_mixin.dart';
import 'package:nativeapi/src/foundation/event_emitter.dart';
import 'package:nativeapi/src/foundation/geometry.dart';
import 'package:nativeapi/src/window.dart';
import 'package:nativeapi/src/window_event.dart';

/// Options for creating a window.
class WindowOptions {
  /// The window title.
  final String title;

  /// The initial window size.
  final Size size;

  /// The minimum window size (optional).
  final Size? minimumSize;

  /// The maximum window size (optional).
  final Size? maximumSize;

  /// Whether to center the window on screen.
  final bool centered;

  const WindowOptions({
    this.title = '',
    this.size = const Size(800, 600),
    this.minimumSize,
    this.maximumSize,
    this.centered = false,
  });
}

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
/// windowManager.addListener<WindowCreatedEvent>((event) {
///   print('Window created: ${event.windowId}');
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
///
/// // Destroy a window
/// windowManager.destroy(windowId);
/// ```
class WindowManager with EventEmitter, CNativeApiBindingsMixin {
  static final WindowManager _instance = WindowManager._();

  /// Returns the singleton instance of [WindowManager].
  static WindowManager get instance => _instance;

  // Native callable for window event callbacks
  static late final NativeCallable<
      Void Function(
        Pointer<native_window_event_t>,
        Pointer<Void>,
      )> _eventCallback;

  static bool _callbackInitialized = false;
  static int? _eventListenerId;

  /// Private constructor for singleton pattern.
  WindowManager._();

  @override
  void startEventListening() {
    // Initialize callback once
    if (!_callbackInitialized) {
      _eventCallback = NativeCallable<
          Void Function(
            Pointer<native_window_event_t>,
            Pointer<Void>,
          )>.listener(
        _nativeOnWindowEvent,
      );
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
      case native_window_event_type_t.NATIVE_WINDOW_EVENT_CREATED:
        _instance.emitSync(WindowCreatedEvent(windowId));
        break;
      case native_window_event_type_t.NATIVE_WINDOW_EVENT_CLOSED:
        _instance.emitSync(WindowClosedEvent(windowId));
        break;
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

  /// Creates a new window with the specified title, size, and options.
  ///
  /// Returns the created [Window] instance, or null if creation failed.
  Window? create({
    String title = '',
    double width = 800,
    double height = 600,
    double? minWidth,
    double? minHeight,
    double? maxWidth,
    double? maxHeight,
    bool centered = false,
  }) {
    return createWithOptions(
      WindowOptions(
        title: title,
        size: Size(width, height),
        minimumSize:
            minWidth != null && minHeight != null ? Size(minWidth, minHeight) : null,
        maximumSize:
            maxWidth != null && maxHeight != null ? Size(maxWidth, maxHeight) : null,
        centered: centered,
      ),
    );
  }

  /// Creates a new window with the specified options.
  ///
  /// Returns the created [Window] instance, or null if creation failed.
  Window? createWithOptions(WindowOptions options) {
    // Create native window options
    final nativeOptions = bindings.native_window_options_create();
    if (nativeOptions == nullptr) {
      return null;
    }

    try {
      // Set title
      if (options.title.isNotEmpty) {
        final titleUtf8 = options.title.toNativeUtf8();
        try {
          bindings.native_window_options_set_title(
            nativeOptions,
            titleUtf8.cast<Char>(),
          );
        } finally {
          ffi.malloc.free(titleUtf8);
        }
      }

      // Set size
      bindings.native_window_options_set_size(
        nativeOptions,
        options.size.width,
        options.size.height,
      );

      // Set minimum size if provided
      if (options.minimumSize != null) {
        bindings.native_window_options_set_minimum_size(
          nativeOptions,
          options.minimumSize!.width,
          options.minimumSize!.height,
        );
      }

      // Set maximum size if provided
      if (options.maximumSize != null) {
        bindings.native_window_options_set_maximum_size(
          nativeOptions,
          options.maximumSize!.width,
          options.maximumSize!.height,
        );
      }

      // Set centered flag
      bindings.native_window_options_set_centered(
        nativeOptions,
        options.centered,
      );

      // Create the window
      final nativeWindow = bindings.native_window_manager_create(nativeOptions);
      if (nativeWindow == nullptr) {
        return null;
      }

      return Window(nativeWindow);
    } finally {
      // Clean up options
      bindings.native_window_options_destroy(nativeOptions);
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

  /// Destroys a window by its ID.
  ///
  /// Returns true if the window was found and destroyed, false otherwise.
  bool destroy(int windowId) {
    return bindings.native_window_manager_destroy(windowId);
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
}

