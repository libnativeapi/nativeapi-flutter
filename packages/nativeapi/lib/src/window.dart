import 'dart:ffi' hide Size;
import 'package:ffi/ffi.dart' as ffi;
import 'package:nativeapi/src/display_manager.dart';
import 'package:nativeapi/src/foundation/cnativeapi_bindings_mixin.dart';
import 'package:nativeapi/src/foundation/geometry.dart';
import 'package:nativeapi/src/foundation/native_handle_wrapper.dart';

/// A cross-platform window abstraction.
///
/// This class provides a unified interface for creating and managing windows
/// across different operating systems. It encapsulates all window-related
/// functionality including size, position, visibility, focus, and appearance.
///
/// Example:
/// ```dart
/// // Create a window through WindowManager
/// final windowManager = WindowManager.instance;
/// final window = windowManager.create(
///   title: 'My App',
///   width: 800,
///   height: 600,
///   centered: true,
/// );
///
/// // Show the window
/// window?.show();
///
/// // Maximize the window
/// window?.maximize();
///
/// // Get window properties
/// final title = window?.title;
/// final size = window?.size;
/// final position = window?.position;
/// ```
class Window
    with CNativeApiBindingsMixin
    implements NativeHandleWrapper<native_window_t> {
  final native_window_t _nativeHandle;

  /// Creates a Window instance from a native handle.
  ///
  /// This constructor is typically called internally by WindowManager.
  Window(this._nativeHandle);

  @override
  native_window_t get nativeHandle => _nativeHandle;

  /// Gets the unique identifier for this window.
  int get id => bindings.native_window_get_id(_nativeHandle);

  // === Focus Management ===

  /// Brings the window to the front and gives it keyboard focus.
  void focus() {
    bindings.native_window_focus(_nativeHandle);
  }

  /// Removes keyboard focus from the window.
  void blur() {
    bindings.native_window_blur(_nativeHandle);
  }

  /// Checks if the window currently has keyboard focus.
  bool get isFocused {
    return bindings.native_window_is_focused(_nativeHandle);
  }

  // === Visibility Management ===

  /// Shows the window and brings it to the front.
  void show() {
    bindings.native_window_show(_nativeHandle);
  }

  /// Shows the window without giving it focus.
  void showInactive() {
    bindings.native_window_show_inactive(_nativeHandle);
  }

  /// Hides the window from view.
  void hide() {
    bindings.native_window_hide(_nativeHandle);
  }

  /// Checks if the window is currently visible.
  bool get isVisible {
    return bindings.native_window_is_visible(_nativeHandle);
  }

  // === Window State Management ===

  /// Maximizes the window to fill the available screen space.
  void maximize() {
    bindings.native_window_maximize(_nativeHandle);
  }

  /// Restores the window from maximized state to its previous size.
  void unmaximize() {
    bindings.native_window_unmaximize(_nativeHandle);
  }

  /// Checks if the window is currently maximized.
  bool get isMaximized {
    return bindings.native_window_is_maximized(_nativeHandle);
  }

  /// Minimizes the window, hiding it from the desktop.
  void minimize() {
    bindings.native_window_minimize(_nativeHandle);
  }

  /// Restores the window from minimized or maximized state.
  void restore() {
    bindings.native_window_restore(_nativeHandle);
  }

  /// Checks if the window is currently minimized.
  bool get isMinimized {
    return bindings.native_window_is_minimized(_nativeHandle);
  }

  /// Sets the window's fullscreen state.
  set isFullscreen(bool value) {
    bindings.native_window_set_fullscreen(_nativeHandle, value);
  }

  /// Checks if the window is currently in fullscreen mode.
  bool get isFullscreen {
    return bindings.native_window_is_fullscreen(_nativeHandle);
  }

  // === Window Geometry Operations ===

  /// Sets the window's bounds (position and size).
  set bounds(Rect bounds) {
    final nativeBounds = ffi.calloc<native_rectangle_t>();
    nativeBounds.ref.x = bounds.left;
    nativeBounds.ref.y = bounds.top;
    nativeBounds.ref.width = bounds.width;
    nativeBounds.ref.height = bounds.height;

    try {
      bindings.native_window_set_bounds(_nativeHandle, nativeBounds.ref);
    } finally {
      ffi.calloc.free(nativeBounds);
    }
  }

  /// Gets the window's bounds (position and size).
  Rect get bounds {
    final nativeBounds = bindings.native_window_get_bounds(_nativeHandle);
    return Rect.fromLTWH(
      nativeBounds.x,
      nativeBounds.y,
      nativeBounds.width,
      nativeBounds.height,
    );
  }

  /// Sets the window's content bounds (position and size).
  set contentBounds(Rect bounds) {
    final nativeBounds = ffi.calloc<native_rectangle_t>();
    nativeBounds.ref.x = bounds.left;
    nativeBounds.ref.y = bounds.top;
    nativeBounds.ref.width = bounds.width;
    nativeBounds.ref.height = bounds.height;
  }

  /// Gets the window's content bounds (position and size).
  Rect get contentBounds {
    final nativeBounds = bindings.native_window_get_content_bounds(
      _nativeHandle,
    );
    return Rect.fromLTWH(
      nativeBounds.x,
      nativeBounds.y,
      nativeBounds.width,
      nativeBounds.height,
    );
  }

  /// Sets the window's size.
  ///
  /// If [animate] is true, the resize will be animated (platform-dependent).
  void setSize(double width, double height, {bool animate = false}) {
    bindings.native_window_set_size(_nativeHandle, width, height, animate);
  }

  /// Gets the window's size.
  Size get size {
    final nativeSize = bindings.native_window_get_size(_nativeHandle);
    return Size(nativeSize.width, nativeSize.height);
  }

  /// Sets the window's content size (excludes frame/titlebar).
  void setContentSize(double width, double height) {
    bindings.native_window_set_content_size(_nativeHandle, width, height);
  }

  /// Gets the window's content size (excludes frame/titlebar).
  Size get contentSize {
    final nativeSize = bindings.native_window_get_content_size(_nativeHandle);
    return Size(nativeSize.width, nativeSize.height);
  }

  /// Sets the window's minimum size.
  void setMinimumSize(double width, double height) {
    bindings.native_window_set_minimum_size(_nativeHandle, width, height);
  }

  /// Gets the window's minimum size.
  Size get minimumSize {
    final nativeSize = bindings.native_window_get_minimum_size(_nativeHandle);
    return Size(nativeSize.width, nativeSize.height);
  }

  /// Sets the window's maximum size.
  void setMaximumSize(double width, double height) {
    bindings.native_window_set_maximum_size(_nativeHandle, width, height);
  }

  /// Gets the window's maximum size.
  Size get maximumSize {
    final nativeSize = bindings.native_window_get_maximum_size(_nativeHandle);
    return Size(nativeSize.width, nativeSize.height);
  }

  /// Sets the window's position.
  void setPosition(double x, double y) {
    bindings.native_window_set_position(_nativeHandle, x, y);
  }

  /// Gets the window's position.
  Offset get position {
    final nativePoint = bindings.native_window_get_position(_nativeHandle);
    return Offset(nativePoint.x, nativePoint.y);
  }

  /// Centers the window on the primary screen.
  ///
  /// This method calculates the center position based on the primary display's
  /// size and the window's current size, then sets the window position accordingly.
  void center() {
    final primaryDisplay = DisplayManager.instance.getPrimary();
    if (primaryDisplay == null) {
      return;
    }

    final screenSize = primaryDisplay.size;
    final windowSize = size;

    final centerX = (screenSize.width - windowSize.width) / 2;
    final centerY = (screenSize.height - windowSize.height) / 2;

    setPosition(centerX, centerY);
  }

  // === Window Properties ===

  /// Sets whether the window can be resized.
  set isResizable(bool value) {
    bindings.native_window_set_resizable(_nativeHandle, value);
  }

  /// Checks if the window can be resized.
  bool get isResizable {
    return bindings.native_window_is_resizable(_nativeHandle);
  }

  /// Sets whether the window can be moved.
  set isMovable(bool value) {
    bindings.native_window_set_movable(_nativeHandle, value);
  }

  /// Checks if the window can be moved.
  bool get isMovable {
    return bindings.native_window_is_movable(_nativeHandle);
  }

  /// Sets whether the window can be minimized.
  set isMinimizable(bool value) {
    bindings.native_window_set_minimizable(_nativeHandle, value);
  }

  /// Checks if the window can be minimized.
  bool get isMinimizable {
    return bindings.native_window_is_minimizable(_nativeHandle);
  }

  /// Sets whether the window can be maximized.
  set isMaximizable(bool value) {
    bindings.native_window_set_maximizable(_nativeHandle, value);
  }

  /// Checks if the window can be maximized.
  bool get isMaximizable {
    return bindings.native_window_is_maximizable(_nativeHandle);
  }

  /// Sets whether the window can enter fullscreen.
  set isFullscreenable(bool value) {
    bindings.native_window_set_fullscreenable(_nativeHandle, value);
  }

  /// Checks if the window can enter fullscreen.
  bool get isFullscreenable {
    return bindings.native_window_is_fullscreenable(_nativeHandle);
  }

  /// Sets whether the window can be closed.
  set isClosable(bool value) {
    bindings.native_window_set_closable(_nativeHandle, value);
  }

  /// Checks if the window can be closed.
  bool get isClosable {
    return bindings.native_window_is_closable(_nativeHandle);
  }

  /// Sets whether the window is always on top.
  set isAlwaysOnTop(bool value) {
    bindings.native_window_set_always_on_top(_nativeHandle, value);
  }

  /// Checks if the window is always on top.
  bool get isAlwaysOnTop {
    return bindings.native_window_is_always_on_top(_nativeHandle);
  }

  /// Sets the window's title.
  set title(String value) {
    final titleUtf8 = value.toNativeUtf8();
    try {
      bindings.native_window_set_title(_nativeHandle, titleUtf8.cast<Char>());
    } finally {
      ffi.malloc.free(titleUtf8);
    }
  }

  /// Gets the window's title.
  String get title {
    final titlePtr = bindings.native_window_get_title(_nativeHandle);
    if (titlePtr == nullptr) {
      return '';
    }
    final title = titlePtr.cast<ffi.Utf8>().toDartString();
    bindings.native_window_free_string(titlePtr);
    return title;
  }

  /// Sets whether the window has a shadow.
  set hasShadow(bool value) {
    bindings.native_window_set_has_shadow(_nativeHandle, value);
  }

  /// Checks if the window has a shadow.
  bool get hasShadow {
    return bindings.native_window_has_shadow(_nativeHandle);
  }

  /// Sets the window's opacity (0.0 to 1.0).
  set opacity(double value) {
    bindings.native_window_set_opacity(_nativeHandle, value);
  }

  /// Gets the window's opacity (0.0 to 1.0).
  double get opacity {
    return bindings.native_window_get_opacity(_nativeHandle);
  }

  /// Sets whether the window is visible on all workspaces.
  set isVisibleOnAllWorkspaces(bool value) {
    bindings.native_window_set_visible_on_all_workspaces(_nativeHandle, value);
  }

  /// Checks if the window is visible on all workspaces.
  bool get isVisibleOnAllWorkspaces {
    return bindings.native_window_is_visible_on_all_workspaces(_nativeHandle);
  }

  /// Sets whether the window ignores mouse events.
  set ignoreMouseEvents(bool value) {
    bindings.native_window_set_ignore_mouse_events(_nativeHandle, value);
  }

  /// Checks if the window ignores mouse events.
  bool get ignoreMouseEvents {
    return bindings.native_window_is_ignore_mouse_events(_nativeHandle);
  }

  /// Sets whether the window is focusable.
  set isFocusable(bool value) {
    bindings.native_window_set_focusable(_nativeHandle, value);
  }

  /// Checks if the window is focusable.
  bool get isFocusable {
    return bindings.native_window_is_focusable(_nativeHandle);
  }

  // === Window Interactions ===

  /// Starts dragging the window.
  void startDragging() {
    bindings.native_window_start_dragging(_nativeHandle);
  }

  /// Starts resizing the window.
  void startResizing() {
    bindings.native_window_start_resizing(_nativeHandle);
  }

  // === Platform-specific ===

  /// Gets the native platform-specific object.
  ///
  /// Platform-specific return types:
  /// - macOS: NSWindow*
  /// - Windows: HWND
  /// - Linux: GtkWidget* (GtkWindow)
  Pointer<Void> get nativeObject {
    return bindings.native_window_get_native_object(_nativeHandle);
  }

  @override
  void dispose() {
    // Note: Windows are managed by WindowManager, so we don't call
    // any destroy function here. The manager handles cleanup.
  }
}
