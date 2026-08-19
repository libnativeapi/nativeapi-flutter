// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;
import 'dart:ui';

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

import 'foundation/color.dart';
import 'foundation/geometry.dart';

final _bindings = c.cnativeApiBindings;

typedef WindowId = int;

enum TitleBarStyle {
  normal(0),
  hidden(1);

  const TitleBarStyle(this.value);
  final int value;

  static TitleBarStyle fromValue(int value) => switch (value) {
    0 => TitleBarStyle.normal,
    1 => TitleBarStyle.hidden,
    _ => TitleBarStyle.normal,
  };

  c.native_title_bar_style_t get raw => c.native_title_bar_style_t.fromValue(value);
}

enum VisualEffect {
  none(0),
  blur(1),
  acrylic(2),
  mica(3);

  const VisualEffect(this.value);
  final int value;

  static VisualEffect fromValue(int value) => switch (value) {
    0 => VisualEffect.none,
    1 => VisualEffect.blur,
    2 => VisualEffect.acrylic,
    3 => VisualEffect.mica,
    _ => VisualEffect.none,
  };

  c.native_visual_effect_t get raw => c.native_visual_effect_t.fromValue(value);
}

/// One `WindowEvent`, in its concrete form.
sealed class WindowEvent {
  const WindowEvent();

  /// Reads the event out of its C form. Returns null for a variant this
  /// binding does not know about.
  static WindowEvent? fromNative(c.native_window_event_t raw) {
    if (raw.type == c.native_window_event_type_t.NATIVE_WINDOW_EVENT_TYPE_FOCUSED.value) {
      return WindowFocusedEvent(windowId: raw.window_id);
    }
    if (raw.type == c.native_window_event_type_t.NATIVE_WINDOW_EVENT_TYPE_BLURRED.value) {
      return WindowBlurredEvent(windowId: raw.window_id);
    }
    if (raw.type == c.native_window_event_type_t.NATIVE_WINDOW_EVENT_TYPE_MINIMIZED.value) {
      return WindowMinimizedEvent(windowId: raw.window_id);
    }
    if (raw.type == c.native_window_event_type_t.NATIVE_WINDOW_EVENT_TYPE_MAXIMIZED.value) {
      return WindowMaximizedEvent(windowId: raw.window_id);
    }
    if (raw.type == c.native_window_event_type_t.NATIVE_WINDOW_EVENT_TYPE_RESTORED.value) {
      return WindowRestoredEvent(windowId: raw.window_id);
    }
    if (raw.type == c.native_window_event_type_t.NATIVE_WINDOW_EVENT_TYPE_MOVED.value) {
      return WindowMovedEvent(windowId: raw.window_id, newPosition: Offset(raw.data.moved.new_position.x, raw.data.moved.new_position.y));
    }
    if (raw.type == c.native_window_event_type_t.NATIVE_WINDOW_EVENT_TYPE_RESIZED.value) {
      return WindowResizedEvent(windowId: raw.window_id, newSize: Size(raw.data.resized.new_size.width, raw.data.resized.new_size.height));
    }
    return null;
  }
}

final class WindowFocusedEvent extends WindowEvent {
  const WindowFocusedEvent({required this.windowId, });

  final WindowId windowId;
}

final class WindowBlurredEvent extends WindowEvent {
  const WindowBlurredEvent({required this.windowId, });

  final WindowId windowId;
}

final class WindowMinimizedEvent extends WindowEvent {
  const WindowMinimizedEvent({required this.windowId, });

  final WindowId windowId;
}

final class WindowMaximizedEvent extends WindowEvent {
  const WindowMaximizedEvent({required this.windowId, });

  final WindowId windowId;
}

final class WindowRestoredEvent extends WindowEvent {
  const WindowRestoredEvent({required this.windowId, });

  final WindowId windowId;
}

final class WindowMovedEvent extends WindowEvent {
  const WindowMovedEvent({required this.windowId, required this.newPosition, });

  final WindowId windowId;
  final Offset newPosition;
}

final class WindowResizedEvent extends WindowEvent {
  const WindowResizedEvent({required this.windowId, required this.newSize, });

  final WindowId windowId;
  final Size newSize;
}

class Window {
  /// Adopts a handle returned by the C API and releases it when this
  /// object becomes unreachable.
  Window.fromHandle(this.nativeHandle) {
    _finalizer.attach(this, nativeHandle, detach: this);
  }

  /// Wraps a handle owned elsewhere; releasing it stays the owner's job.
  Window.borrowed(this.nativeHandle);

  /// The underlying handle-table entry.
  final int nativeHandle;

  static final Finalizer<int> _finalizer = Finalizer<int>(
    (handle) => _bindings.native_window_free(handle),
  );

  /// Releases the handle now instead of at collection.
  void dispose() {
    _finalizer.detach(this);
    _bindings.native_window_free(nativeHandle);
  }

  /// Creates a new `Window`; returns null if the native side failed.
  static Window? create() {
    final handle = _bindings.native_window_create();
    if (handle == 0) return null;
    return Window.fromHandle(handle);
  }

  /// Creates a new `Window`; returns null if the native side failed.
  static Window? createWithNativeWindow(ffi.Pointer<ffi.Void> nativeWindow) {
    final handle = _bindings.native_window_create_with_native_window(nativeWindow);
    if (handle == 0) return null;
    return Window.fromHandle(handle);
  }

  WindowId get id {
    return _bindings.native_window_get_id(nativeHandle);
  }

  void focus() {
    _bindings.native_window_focus(nativeHandle);
  }

  void blur() {
    _bindings.native_window_blur(nativeHandle);
  }

  bool get isFocused {
    return _bindings.native_window_is_focused(nativeHandle);
  }

  void show() {
    _bindings.native_window_show(nativeHandle);
  }

  void showInactive() {
    _bindings.native_window_show_inactive(nativeHandle);
  }

  void hide() {
    _bindings.native_window_hide(nativeHandle);
  }

  bool get isVisible {
    return _bindings.native_window_is_visible(nativeHandle);
  }

  void maximize() {
    _bindings.native_window_maximize(nativeHandle);
  }

  void unmaximize() {
    _bindings.native_window_unmaximize(nativeHandle);
  }

  bool get isMaximized {
    return _bindings.native_window_is_maximized(nativeHandle);
  }

  void minimize() {
    _bindings.native_window_minimize(nativeHandle);
  }

  void restore() {
    _bindings.native_window_restore(nativeHandle);
  }

  bool get isMinimized {
    return _bindings.native_window_is_minimized(nativeHandle);
  }

  set isFullScreen(bool value) {
    _bindings.native_window_set_full_screen(nativeHandle, value);
  }

  bool get isFullScreen {
    return _bindings.native_window_is_full_screen(nativeHandle);
  }

  set bounds(Rect value) {
    final valuePointer = pkg_ffi.calloc<c.native_rectangle_t>();
    valuePointer.ref.x = value.left;
    valuePointer.ref.y = value.top;
    valuePointer.ref.width = value.width;
    valuePointer.ref.height = value.height;
    _bindings.native_window_set_bounds(nativeHandle, valuePointer.ref);
    pkg_ffi.calloc.free(valuePointer);
  }

  Rect get bounds {
    final raw = _bindings.native_window_get_bounds(nativeHandle);
    return Rect.fromLTWH(raw.x, raw.y, raw.width, raw.height);
  }

  set contentBounds(Rect value) {
    final valuePointer = pkg_ffi.calloc<c.native_rectangle_t>();
    valuePointer.ref.x = value.left;
    valuePointer.ref.y = value.top;
    valuePointer.ref.width = value.width;
    valuePointer.ref.height = value.height;
    _bindings.native_window_set_content_bounds(nativeHandle, valuePointer.ref);
    pkg_ffi.calloc.free(valuePointer);
  }

  Rect get contentBounds {
    final raw = _bindings.native_window_get_content_bounds(nativeHandle);
    return Rect.fromLTWH(raw.x, raw.y, raw.width, raw.height);
  }

  void setSize(Size size, bool animate) {
    final sizePointer = pkg_ffi.calloc<c.native_size_t>();
    sizePointer.ref.width = size.width;
    sizePointer.ref.height = size.height;
    _bindings.native_window_set_size(nativeHandle, sizePointer.ref, animate);
    pkg_ffi.calloc.free(sizePointer);
  }

  Size get size {
    final raw = _bindings.native_window_get_size(nativeHandle);
    return Size(raw.width, raw.height);
  }

  set contentSize(Size value) {
    final valuePointer = pkg_ffi.calloc<c.native_size_t>();
    valuePointer.ref.width = value.width;
    valuePointer.ref.height = value.height;
    _bindings.native_window_set_content_size(nativeHandle, valuePointer.ref);
    pkg_ffi.calloc.free(valuePointer);
  }

  Size get contentSize {
    final raw = _bindings.native_window_get_content_size(nativeHandle);
    return Size(raw.width, raw.height);
  }

  set minimumSize(Size value) {
    final valuePointer = pkg_ffi.calloc<c.native_size_t>();
    valuePointer.ref.width = value.width;
    valuePointer.ref.height = value.height;
    _bindings.native_window_set_minimum_size(nativeHandle, valuePointer.ref);
    pkg_ffi.calloc.free(valuePointer);
  }

  Size get minimumSize {
    final raw = _bindings.native_window_get_minimum_size(nativeHandle);
    return Size(raw.width, raw.height);
  }

  set maximumSize(Size value) {
    final valuePointer = pkg_ffi.calloc<c.native_size_t>();
    valuePointer.ref.width = value.width;
    valuePointer.ref.height = value.height;
    _bindings.native_window_set_maximum_size(nativeHandle, valuePointer.ref);
    pkg_ffi.calloc.free(valuePointer);
  }

  Size get maximumSize {
    final raw = _bindings.native_window_get_maximum_size(nativeHandle);
    return Size(raw.width, raw.height);
  }

  set isResizable(bool value) {
    _bindings.native_window_set_resizable(nativeHandle, value);
  }

  bool get isResizable {
    return _bindings.native_window_is_resizable(nativeHandle);
  }

  set isMovable(bool value) {
    _bindings.native_window_set_movable(nativeHandle, value);
  }

  bool get isMovable {
    return _bindings.native_window_is_movable(nativeHandle);
  }

  set isMinimizable(bool value) {
    _bindings.native_window_set_minimizable(nativeHandle, value);
  }

  bool get isMinimizable {
    return _bindings.native_window_is_minimizable(nativeHandle);
  }

  set isMaximizable(bool value) {
    _bindings.native_window_set_maximizable(nativeHandle, value);
  }

  bool get isMaximizable {
    return _bindings.native_window_is_maximizable(nativeHandle);
  }

  set isFullScreenable(bool value) {
    _bindings.native_window_set_full_screenable(nativeHandle, value);
  }

  bool get isFullScreenable {
    return _bindings.native_window_is_full_screenable(nativeHandle);
  }

  set isClosable(bool value) {
    _bindings.native_window_set_closable(nativeHandle, value);
  }

  bool get isClosable {
    return _bindings.native_window_is_closable(nativeHandle);
  }

  set isWindowControlButtonsVisible(bool value) {
    _bindings.native_window_set_window_control_buttons_visible(nativeHandle, value);
  }

  bool get isWindowControlButtonsVisible {
    return _bindings.native_window_is_window_control_buttons_visible(nativeHandle);
  }

  set isAlwaysOnTop(bool value) {
    _bindings.native_window_set_always_on_top(nativeHandle, value);
  }

  bool get isAlwaysOnTop {
    return _bindings.native_window_is_always_on_top(nativeHandle);
  }

  set position(Offset value) {
    final valuePointer = pkg_ffi.calloc<c.native_point_t>();
    valuePointer.ref.x = value.dx;
    valuePointer.ref.y = value.dy;
    _bindings.native_window_set_position(nativeHandle, valuePointer.ref);
    pkg_ffi.calloc.free(valuePointer);
  }

  Offset get position {
    final raw = _bindings.native_window_get_position(nativeHandle);
    return Offset(raw.x, raw.y);
  }

  void center() {
    _bindings.native_window_center(nativeHandle);
  }

  set title(String value) {
    final valueNative = value.toNativeUtf8().cast<ffi.Char>();
    _bindings.native_window_set_title(nativeHandle, valueNative);
    pkg_ffi.calloc.free(valueNative);
  }

  String? get title {
    final resultPointer = _bindings.native_window_get_title(nativeHandle);
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    _bindings.free_c_str(resultPointer);
    return result;
  }

  set titleBarStyle(TitleBarStyle value) {
    _bindings.native_window_set_title_bar_style(nativeHandle, value.raw);
  }

  TitleBarStyle get titleBarStyle {
    final raw = _bindings.native_window_get_title_bar_style(nativeHandle);
    return TitleBarStyle.fromValue(raw.value);
  }

  set hasShadow(bool value) {
    _bindings.native_window_set_has_shadow(nativeHandle, value);
  }

  bool get hasShadow {
    return _bindings.native_window_has_shadow(nativeHandle);
  }

  set opacity(double value) {
    _bindings.native_window_set_opacity(nativeHandle, value);
  }

  double get opacity {
    return _bindings.native_window_get_opacity(nativeHandle);
  }

  set visualEffect(VisualEffect value) {
    _bindings.native_window_set_visual_effect(nativeHandle, value.raw);
  }

  VisualEffect get visualEffect {
    final raw = _bindings.native_window_get_visual_effect(nativeHandle);
    return VisualEffect.fromValue(raw.value);
  }

  set backgroundColor(Color value) {
    final valuePointer = pkg_ffi.calloc<c.native_color_t>();
    valuePointer.ref.r = (value.r * 255).round();
    valuePointer.ref.g = (value.g * 255).round();
    valuePointer.ref.b = (value.b * 255).round();
    valuePointer.ref.a = (value.a * 255).round();
    _bindings.native_window_set_background_color(nativeHandle, valuePointer.ref);
    pkg_ffi.calloc.free(valuePointer);
  }

  Color get backgroundColor {
    final raw = _bindings.native_window_get_background_color(nativeHandle);
    return Color.fromARGB(raw.a, raw.r, raw.g, raw.b);
  }

  set isVisibleOnAllWorkspaces(bool value) {
    _bindings.native_window_set_visible_on_all_workspaces(nativeHandle, value);
  }

  bool get isVisibleOnAllWorkspaces {
    return _bindings.native_window_is_visible_on_all_workspaces(nativeHandle);
  }

  set isIgnoreMouseEvents(bool value) {
    _bindings.native_window_set_ignore_mouse_events(nativeHandle, value);
  }

  bool get isIgnoreMouseEvents {
    return _bindings.native_window_is_ignore_mouse_events(nativeHandle);
  }

  set isFocusable(bool value) {
    _bindings.native_window_set_focusable(nativeHandle, value);
  }

  bool get isFocusable {
    return _bindings.native_window_is_focusable(nativeHandle);
  }

  void startDragging() {
    _bindings.native_window_start_dragging(nativeHandle);
  }

  void startResizing() {
    _bindings.native_window_start_resizing(nativeHandle);
  }

  /// Platform-specific native object behind this handle.
  ffi.Pointer<ffi.Void> get nativeObject =>
      _bindings.native_window_get_native_object(nativeHandle);

}

