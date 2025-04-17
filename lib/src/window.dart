import 'dart:ui';

import 'package:ffi/ffi.dart';
import 'package:nativeapi/src/nativeapi_bindings.dart';
import 'package:nativeapi/src/nativeapi_bindings_generated.dart';

class Window {
  NativeApiBindings get _bindings => nativeApiBindings;

  final int id;

  Window({required this.id});

  void focus() {
    _bindings.window_focus(id);
  }

  void blur() {
    _bindings.window_blur(id);
  }

  bool isFocused() {
    return _bindings.window_is_focused(id);
  }

  void show() {
    _bindings.window_show(id);
  }

  void hide() {
    _bindings.window_hide(id);
  }

  bool isVisible() {
    return _bindings.window_is_visible(id);
  }

  void maximize() {
    _bindings.window_maximize(id);
  }

  void unmaximize() {
    _bindings.window_unmaximize(id);
  }

  bool isMaximized() {
    return _bindings.window_is_maximized(id);
  }

  void minimize() {
    _bindings.window_minimize(id);
  }

  void restore() {
    _bindings.window_restore(id);
  }

  bool isMinimized() {
    return _bindings.window_is_minimized(id);
  }

  void setFullScreen(bool isFullScreen) {
    _bindings.window_set_full_screen(id, isFullScreen);
  }

  bool isFullScreen() {
    return _bindings.window_is_full_screen(id);
  }

  // void SetBackgroundColor(Color color);
  // Color GetBackgroundColor() const;
  void setBounds(Rect bounds) {}

  Rect get bounds {
    final nativeRectangle = _bindings.window_get_bounds(id);
    return Rect.fromLTRB(
      nativeRectangle.x,
      nativeRectangle.y,
      nativeRectangle.x + nativeRectangle.width,
      nativeRectangle.y + nativeRectangle.height,
    );
  }

  void setSize(Size size) {}

  Size getSize() {
    final nativeSize = _bindings.window_get_size(id);
    return Size(nativeSize.width, nativeSize.height);
  }

  void setContentSize(Size size) {}

  Size getContentSize() {
    final nativeSize = _bindings.window_get_content_size(id);
    return Size(nativeSize.width, nativeSize.height);
  }

  void setMinimumSize(Size size) {}

  Size getMinimumSize() {
    final nativeSize = _bindings.window_get_minimum_size(id);
    return Size(nativeSize.width, nativeSize.height);
  }

  void setMaximumSize(Size size) {}

  Size getMaximumSize() {
    final nativeSize = _bindings.window_get_maximum_size(id);
    return Size(nativeSize.width, nativeSize.height);
  }

  void setResizable(bool isResizable) {
    _bindings.window_set_resizable(id, isResizable);
  }

  bool isResizable() {
    return _bindings.window_is_resizable(id);
  }

  void setMovable(bool isMovable) {
    _bindings.window_set_movable(id, isMovable);
  }

  bool isMovable() {
    return _bindings.window_is_movable(id);
  }

  void setMinimizable(bool isMinimizable) {
    _bindings.window_set_minimizable(id, isMinimizable);
  }

  bool isMinimizable() {
    return _bindings.window_is_minimizable(id);
  }

  void setMaximizable(bool isMaximizable) {
    _bindings.window_set_maximizable(id, isMaximizable);
  }

  bool isMaximizable() {
    return _bindings.window_is_maximizable(id);
  }

  void setFullScreenable(bool isFullScreenable) {
    _bindings.window_set_full_screenable(id, isFullScreenable);
  }

  bool isFullScreenable() {
    return _bindings.window_is_full_screenable(id);
  }

  void setClosable(bool isClosable) {
    _bindings.window_set_closable(id, isClosable);
  }

  bool isClosable() {
    return _bindings.window_is_closable(id);
  }

  void setAlwaysOnTop(bool isAlwaysOnTop) {
    _bindings.window_set_always_on_top(id, isAlwaysOnTop);
  }

  bool isAlwaysOnTop() {
    return _bindings.window_is_always_on_top(id);
  }

  void setPosition(Offset offset) {}

  Offset getPosition() {
    final nativePoint = _bindings.window_get_position(id);
    return Offset(nativePoint.x, nativePoint.y);
  }

  void setTitle(String title) {}

  String getTitle() {
    return _bindings.window_get_title(id).cast<Utf8>().toDartString();
  }

  void setHasShadow(bool hasShadow) {
    _bindings.window_set_has_shadow(id, hasShadow);
  }

  bool hasShadow() {
    return _bindings.window_has_shadow(id);
  }

  void setOpacity(double opacity) {
    _bindings.window_set_opacity(id, opacity);
  }

  double getOpacity() {
    return _bindings.window_get_opacity(id);
  }

  void setFocusable(bool isFocusable) {
    _bindings.window_set_focusable(id, isFocusable);
  }

  bool isFocusable() {
    return _bindings.window_is_focusable(id);
  }

  void startDragging() {
    _bindings.window_start_dragging(id);
  }

  void startResizing() {
    _bindings.window_start_resizing(id);
  }

  void addListener(VoidCallback listener) {}
}
