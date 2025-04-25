import 'dart:ui';
import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';
import 'package:nativeapi/src/ffi/bindings.dart';
import 'package:nativeapi/src/ffi/bindings_generated.dart';

/// A class for representing a window.
///
/// This class provides methods for managing a window.
class Window {
  /// The native API bindings.
  NativeApiBindings get _bindings => nativeApiBindings;

  /// The ID of the window.
  final int id;

  /// Creates a new window.
  Window({required this.id});

  /// Focuses the window.
  void focus() {
    _bindings.window_focus(id);
  }

  /// Blurs the window.
  void blur() {
    _bindings.window_blur(id);
  }

  /// Checks if the window is focused.
  bool isFocused() {
    return _bindings.window_is_focused(id);
  }

  /// Shows the window.
  void show() {
    _bindings.window_show(id);
  }

  /// Hides the window.
  void hide() {
    _bindings.window_hide(id);
  }

  /// Checks if the window is visible.
  bool isVisible() {
    return _bindings.window_is_visible(id);
  }

  /// Maximizes the window.
  void maximize() {
    _bindings.window_maximize(id);
  }

  /// Unmaximizes the window.
  void unmaximize() {
    _bindings.window_unmaximize(id);
  }

  /// Checks if the window is maximized.
  bool isMaximized() {
    return _bindings.window_is_maximized(id);
  }

  /// Minimizes the window.
  void minimize() {
    _bindings.window_minimize(id);
  }

  /// Restores the window.
  void restore() {
    _bindings.window_restore(id);
  }

  /// Checks if the window is minimized.
  bool isMinimized() {
    return _bindings.window_is_minimized(id);
  }

  /// Sets the window to full screen.
  void setFullScreen(bool isFullScreen) {
    _bindings.window_set_full_screen(id, isFullScreen);
  }

  /// Checks if the window is full screen.
  bool isFullScreen() {
    return _bindings.window_is_full_screen(id);
  }

  // void SetBackgroundColor(Color color);
  // Color GetBackgroundColor() const;

  /// Sets the bounds of the window.
  void setBounds(Rect bounds) {}

  /// Gets the bounds of the window.
  Rect get bounds {
    final nativeRectangle = _bindings.window_get_bounds(id);
    return Rect.fromLTRB(
      nativeRectangle.x,
      nativeRectangle.y,
      nativeRectangle.x + nativeRectangle.width,
      nativeRectangle.y + nativeRectangle.height,
    );
  }

  /// Sets the size of the window.
  void setSize(Size size) {}

  /// Gets the size of the window.
  Size getSize() {
    final nativeSize = _bindings.window_get_size(id);
    return Size(nativeSize.width, nativeSize.height);
  }

  /// Sets the content size of the window.
  void setContentSize(Size size) {}

  /// Gets the content size of the window.
  Size getContentSize() {
    final nativeSize = _bindings.window_get_content_size(id);
    return Size(nativeSize.width, nativeSize.height);
  }

  /// Sets the minimum size of the window.
  void setMinimumSize(Size size) {}

  /// Gets the minimum size of the window.
  Size getMinimumSize() {
    final nativeSize = _bindings.window_get_minimum_size(id);
    return Size(nativeSize.width, nativeSize.height);
  }

  /// Sets the maximum size of the window.
  void setMaximumSize(Size size) {}

  /// Gets the maximum size of the window.
  Size getMaximumSize() {
    final nativeSize = _bindings.window_get_maximum_size(id);
    return Size(nativeSize.width, nativeSize.height);
  }

  /// Sets whether the window is resizable.
  void setResizable(bool isResizable) {
    _bindings.window_set_resizable(id, isResizable);
  }

  /// Checks if the window is resizable.
  bool isResizable() {
    return _bindings.window_is_resizable(id);
  }

  /// Sets whether the window is movable.
  void setMovable(bool isMovable) {
    _bindings.window_set_movable(id, isMovable);
  }

  /// Checks if the window is movable.
  bool isMovable() {
    return _bindings.window_is_movable(id);
  }

  /// Sets whether the window is minimizable.
  void setMinimizable(bool isMinimizable) {
    _bindings.window_set_minimizable(id, isMinimizable);
  }

  /// Checks if the window is minimizable.
  bool isMinimizable() {
    return _bindings.window_is_minimizable(id);
  }

  /// Sets whether the window is maximizable.
  void setMaximizable(bool isMaximizable) {
    _bindings.window_set_maximizable(id, isMaximizable);
  }

  /// Checks if the window is maximizable.
  bool isMaximizable() {
    return _bindings.window_is_maximizable(id);
  }

  /// Sets whether the window is full screenable.
  void setFullScreenable(bool isFullScreenable) {
    _bindings.window_set_full_screenable(id, isFullScreenable);
  }

  /// Checks if the window is full screenable.
  bool isFullScreenable() {
    return _bindings.window_is_full_screenable(id);
  }

  /// Sets whether the window is closable.
  void setClosable(bool isClosable) {
    _bindings.window_set_closable(id, isClosable);
  }

  /// Checks if the window is closable.
  bool isClosable() {
    return _bindings.window_is_closable(id);
  }

  /// Sets whether the window is always on top.
  void setAlwaysOnTop(bool isAlwaysOnTop) {
    _bindings.window_set_always_on_top(id, isAlwaysOnTop);
  }

  /// Checks if the window is always on top.
  bool isAlwaysOnTop() {
    return _bindings.window_is_always_on_top(id);
  }

  /// Sets the position of the window.
  void setPosition(Offset offset) {
    final pointPtr = malloc<NativePoint>();
    pointPtr.ref.x = offset.dx;
    pointPtr.ref.y = offset.dy;
    _bindings.window_set_position(id, pointPtr.ref);
  }

  /// Gets the position of the window.
  Offset getPosition() {
    final nativePoint = _bindings.window_get_position(id);
    return Offset(nativePoint.x, nativePoint.y);
  }

  /// Sets the title of the window.
  void setTitle(String title) {}

  /// Gets the title of the window.
  String getTitle() {
    return _bindings.window_get_title(id).cast<Utf8>().toDartString();
  }

  /// Sets whether the window has a shadow.
  void setHasShadow(bool hasShadow) {
    _bindings.window_set_has_shadow(id, hasShadow);
  }

  /// Checks if the window has a shadow.
  bool hasShadow() {
    return _bindings.window_has_shadow(id);
  }

  /// Sets the opacity of the window.
  void setOpacity(double opacity) {
    _bindings.window_set_opacity(id, opacity);
  }

  /// Gets the opacity of the window.
  double getOpacity() {
    return _bindings.window_get_opacity(id);
  }

  /// Sets whether the window is focusable.
  void setFocusable(bool isFocusable) {
    _bindings.window_set_focusable(id, isFocusable);
  }

  /// Checks if the window is focusable.
  bool isFocusable() {
    return _bindings.window_is_focusable(id);
  }

  /// Starts dragging the window.
  void startDragging() {
    _bindings.window_start_dragging(id);
  }

  /// Starts resizing the window.
  void startResizing() {
    _bindings.window_start_resizing(id);
  }

  void addListener(VoidCallback listener) {}

  @override
  int get hashCode => id.hashCode;

  @override
  operator ==(Object other) {
    return other is Window && other.id == id;
  }
}
