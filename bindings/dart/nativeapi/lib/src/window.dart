// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

import 'foundation/color.dart';
import 'foundation/geometry.dart';
import 'window_shadow.dart';
import 'window_shape.dart';

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

  c.native_title_bar_style_t get raw =>
      c.native_title_bar_style_t.fromValue(value);
}

enum VisualEffect {
  none(0),
  blur(1),
  acrylic(2),
  mica(3),
  micaAlt(4),
  hud(5),
  popover(6),
  menu(7);

  const VisualEffect(this.value);
  final int value;

  static VisualEffect fromValue(int value) => switch (value) {
    0 => VisualEffect.none,
    1 => VisualEffect.blur,
    2 => VisualEffect.acrylic,
    3 => VisualEffect.mica,
    4 => VisualEffect.micaAlt,
    5 => VisualEffect.hud,
    6 => VisualEffect.popover,
    7 => VisualEffect.menu,
    _ => VisualEffect.none,
  };

  c.native_visual_effect_t get raw => c.native_visual_effect_t.fromValue(value);
}

enum ResizeEdge {
  top(0),
  left(1),
  right(2),
  bottom(3),
  topLeft(4),
  topRight(5),
  bottomLeft(6),
  bottomRight(7);

  const ResizeEdge(this.value);
  final int value;

  static ResizeEdge fromValue(int value) => switch (value) {
    0 => ResizeEdge.top,
    1 => ResizeEdge.left,
    2 => ResizeEdge.right,
    3 => ResizeEdge.bottom,
    4 => ResizeEdge.topLeft,
    5 => ResizeEdge.topRight,
    6 => ResizeEdge.bottomLeft,
    7 => ResizeEdge.bottomRight,
    _ => ResizeEdge.top,
  };

  c.native_resize_edge_t get raw => c.native_resize_edge_t.fromValue(value);
}

/// One `WindowEvent`, in its concrete form.
sealed class WindowEvent {
  const WindowEvent();

  WindowId get windowId;

  /// Reads the event out of its C form. Returns null for a variant this
  /// binding does not know about.
  static WindowEvent? fromNative(c.native_window_event_t raw) {
    if (raw.typeAsInt ==
        c.native_window_event_type_t.NATIVE_WINDOW_EVENT_TYPE_FOCUSED.value) {
      return WindowFocusedEvent(windowId: raw.window_id);
    }
    if (raw.typeAsInt ==
        c.native_window_event_type_t.NATIVE_WINDOW_EVENT_TYPE_BLURRED.value) {
      return WindowBlurredEvent(windowId: raw.window_id);
    }
    if (raw.typeAsInt ==
        c.native_window_event_type_t.NATIVE_WINDOW_EVENT_TYPE_MINIMIZED.value) {
      return WindowMinimizedEvent(windowId: raw.window_id);
    }
    if (raw.typeAsInt ==
        c.native_window_event_type_t.NATIVE_WINDOW_EVENT_TYPE_MAXIMIZED.value) {
      return WindowMaximizedEvent(windowId: raw.window_id);
    }
    if (raw.typeAsInt ==
        c.native_window_event_type_t.NATIVE_WINDOW_EVENT_TYPE_RESTORED.value) {
      return WindowRestoredEvent(windowId: raw.window_id);
    }
    if (raw.typeAsInt ==
        c.native_window_event_type_t.NATIVE_WINDOW_EVENT_TYPE_MOVED.value) {
      return WindowMovedEvent(
        windowId: raw.window_id,
        newPosition: Point.fromNative(raw.data.moved.new_position),
      );
    }
    if (raw.typeAsInt ==
        c.native_window_event_type_t.NATIVE_WINDOW_EVENT_TYPE_RESIZED.value) {
      return WindowResizedEvent(
        windowId: raw.window_id,
        newSize: Size.fromNative(raw.data.resized.new_size),
      );
    }
    if (raw.typeAsInt ==
        c.native_window_event_type_t.NATIVE_WINDOW_EVENT_TYPE_CREATED.value) {
      return WindowCreatedEvent(windowId: raw.window_id);
    }
    if (raw.typeAsInt ==
        c.native_window_event_type_t.NATIVE_WINDOW_EVENT_TYPE_CLOSED.value) {
      return WindowClosedEvent(windowId: raw.window_id);
    }
    return null;
  }
}

final class WindowFocusedEvent extends WindowEvent {
  const WindowFocusedEvent({required this.windowId});

  @override
  final WindowId windowId;
}

final class WindowBlurredEvent extends WindowEvent {
  const WindowBlurredEvent({required this.windowId});

  @override
  final WindowId windowId;
}

final class WindowMinimizedEvent extends WindowEvent {
  const WindowMinimizedEvent({required this.windowId});

  @override
  final WindowId windowId;
}

final class WindowMaximizedEvent extends WindowEvent {
  const WindowMaximizedEvent({required this.windowId});

  @override
  final WindowId windowId;
}

final class WindowRestoredEvent extends WindowEvent {
  const WindowRestoredEvent({required this.windowId});

  @override
  final WindowId windowId;
}

final class WindowMovedEvent extends WindowEvent {
  const WindowMovedEvent({required this.windowId, required this.newPosition});

  @override
  final WindowId windowId;
  final Point newPosition;
}

final class WindowResizedEvent extends WindowEvent {
  const WindowResizedEvent({required this.windowId, required this.newSize});

  @override
  final WindowId windowId;
  final Size newSize;
}

final class WindowCreatedEvent extends WindowEvent {
  const WindowCreatedEvent({required this.windowId});

  @override
  final WindowId windowId;
}

final class WindowClosedEvent extends WindowEvent {
  const WindowClosedEvent({required this.windowId});

  @override
  final WindowId windowId;
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
    (handle) => c.native_window_free(handle),
  );

  /// Releases the handle now instead of at collection.
  void dispose() {
    _finalizer.detach(this);
    c.native_window_free(nativeHandle);
  }

  /// Creates a new `Window`; returns null if the native side failed.
  static Window? create() {
    final handle = c.native_window_create();
    if (handle == 0) return null;
    return Window.fromHandle(handle);
  }

  /// Creates a new `Window`; returns null if the native side failed.
  static Window? createWithNativeWindow(ffi.Pointer<ffi.Void> nativeWindow) {
    final handle = c.native_window_create_with_native_window(nativeWindow);
    if (handle == 0) return null;
    return Window.fromHandle(handle);
  }

  WindowId get id {
    return c.native_window_get_id(nativeHandle);
  }

  void focus() {
    c.native_window_focus(nativeHandle);
  }

  void blur() {
    c.native_window_blur(nativeHandle);
  }

  bool get isFocused {
    return c.native_window_is_focused(nativeHandle);
  }

  void show() {
    c.native_window_show(nativeHandle);
  }

  void showInactive() {
    c.native_window_show_inactive(nativeHandle);
  }

  void hide() {
    c.native_window_hide(nativeHandle);
  }

  bool get isVisible {
    return c.native_window_is_visible(nativeHandle);
  }

  void maximize() {
    c.native_window_maximize(nativeHandle);
  }

  void unmaximize() {
    c.native_window_unmaximize(nativeHandle);
  }

  bool get isMaximized {
    return c.native_window_is_maximized(nativeHandle);
  }

  void minimize() {
    c.native_window_minimize(nativeHandle);
  }

  void restore() {
    c.native_window_restore(nativeHandle);
  }

  bool get isMinimized {
    return c.native_window_is_minimized(nativeHandle);
  }

  set isFullScreen(bool value) {
    c.native_window_set_full_screen(nativeHandle, value);
  }

  bool get isFullScreen {
    return c.native_window_is_full_screen(nativeHandle);
  }

  set bounds(Rectangle value) {
    final valuePointer = value.allocNative();
    c.native_window_set_bounds(nativeHandle, valuePointer.ref);
    Rectangle.freeNative(valuePointer);
  }

  Rectangle get bounds {
    final raw = c.native_window_get_bounds(nativeHandle);
    return Rectangle.fromNative(raw);
  }

  set contentBounds(Rectangle value) {
    final valuePointer = value.allocNative();
    c.native_window_set_content_bounds(nativeHandle, valuePointer.ref);
    Rectangle.freeNative(valuePointer);
  }

  Rectangle get contentBounds {
    final raw = c.native_window_get_content_bounds(nativeHandle);
    return Rectangle.fromNative(raw);
  }

  void setSize(Size size, bool animate) {
    final sizePointer = size.allocNative();
    c.native_window_set_size(nativeHandle, sizePointer.ref, animate);
    Size.freeNative(sizePointer);
  }

  Size get size {
    final raw = c.native_window_get_size(nativeHandle);
    return Size.fromNative(raw);
  }

  set contentSize(Size value) {
    final valuePointer = value.allocNative();
    c.native_window_set_content_size(nativeHandle, valuePointer.ref);
    Size.freeNative(valuePointer);
  }

  Size get contentSize {
    final raw = c.native_window_get_content_size(nativeHandle);
    return Size.fromNative(raw);
  }

  set minimumSize(Size value) {
    final valuePointer = value.allocNative();
    c.native_window_set_minimum_size(nativeHandle, valuePointer.ref);
    Size.freeNative(valuePointer);
  }

  Size get minimumSize {
    final raw = c.native_window_get_minimum_size(nativeHandle);
    return Size.fromNative(raw);
  }

  set maximumSize(Size value) {
    final valuePointer = value.allocNative();
    c.native_window_set_maximum_size(nativeHandle, valuePointer.ref);
    Size.freeNative(valuePointer);
  }

  Size get maximumSize {
    final raw = c.native_window_get_maximum_size(nativeHandle);
    return Size.fromNative(raw);
  }

  set aspectRatio(double value) {
    c.native_window_set_aspect_ratio(nativeHandle, value);
  }

  double get aspectRatio {
    return c.native_window_get_aspect_ratio(nativeHandle);
  }

  set isResizable(bool value) {
    c.native_window_set_resizable(nativeHandle, value);
  }

  bool get isResizable {
    return c.native_window_is_resizable(nativeHandle);
  }

  set isMovable(bool value) {
    c.native_window_set_movable(nativeHandle, value);
  }

  bool get isMovable {
    return c.native_window_is_movable(nativeHandle);
  }

  set isMinimizable(bool value) {
    c.native_window_set_minimizable(nativeHandle, value);
  }

  bool get isMinimizable {
    return c.native_window_is_minimizable(nativeHandle);
  }

  set isMaximizable(bool value) {
    c.native_window_set_maximizable(nativeHandle, value);
  }

  bool get isMaximizable {
    return c.native_window_is_maximizable(nativeHandle);
  }

  set isFullScreenable(bool value) {
    c.native_window_set_full_screenable(nativeHandle, value);
  }

  bool get isFullScreenable {
    return c.native_window_is_full_screenable(nativeHandle);
  }

  set isClosable(bool value) {
    c.native_window_set_closable(nativeHandle, value);
  }

  bool get isClosable {
    return c.native_window_is_closable(nativeHandle);
  }

  set isWindowControlButtonsVisible(bool value) {
    c.native_window_set_window_control_buttons_visible(nativeHandle, value);
  }

  bool get isWindowControlButtonsVisible {
    return c.native_window_is_window_control_buttons_visible(nativeHandle);
  }

  set isAlwaysOnTop(bool value) {
    c.native_window_set_always_on_top(nativeHandle, value);
  }

  bool get isAlwaysOnTop {
    return c.native_window_is_always_on_top(nativeHandle);
  }

  set isAlwaysOnBottom(bool value) {
    c.native_window_set_always_on_bottom(nativeHandle, value);
  }

  bool get isAlwaysOnBottom {
    return c.native_window_is_always_on_bottom(nativeHandle);
  }

  bool setParentWindow(Window? parent) {
    return c.native_window_set_parent_window(
      nativeHandle,
      parent?.nativeHandle ?? 0,
    );
  }

  Window? get parentWindow {
    final handle = c.native_window_get_parent_window(nativeHandle);
    if (handle == 0) return null;
    return Window.fromHandle(handle);
  }

  set isNonActivating(bool value) {
    c.native_window_set_non_activating(nativeHandle, value);
  }

  bool get isNonActivating {
    return c.native_window_is_non_activating(nativeHandle);
  }

  set position(Point value) {
    final valuePointer = value.allocNative();
    c.native_window_set_position(nativeHandle, valuePointer.ref);
    Point.freeNative(valuePointer);
  }

  Point get position {
    final raw = c.native_window_get_position(nativeHandle);
    return Point.fromNative(raw);
  }

  void center() {
    c.native_window_center(nativeHandle);
  }

  set title(String value) {
    final valueNative = value.toNativeUtf8().cast<ffi.Char>();
    c.native_window_set_title(nativeHandle, valueNative);
    pkg_ffi.calloc.free(valueNative);
  }

  String? get title {
    final resultPointer = c.native_window_get_title(nativeHandle);
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    c.free_c_str(resultPointer);
    return result;
  }

  bool setTitleBarColors(Color background, Color foreground) {
    final backgroundPointer = background.allocNative();
    final foregroundPointer = foreground.allocNative();
    final result = c.native_window_set_title_bar_colors(
      nativeHandle,
      backgroundPointer.ref,
      foregroundPointer.ref,
    );
    Color.freeNative(backgroundPointer);
    Color.freeNative(foregroundPointer);
    return result;
  }

  bool resetTitleBarColors() {
    return c.native_window_reset_title_bar_colors(nativeHandle);
  }

  set titleBarStyle(TitleBarStyle value) {
    c.native_window_set_title_bar_style(nativeHandle, value.raw);
  }

  TitleBarStyle get titleBarStyle {
    final raw = c.native_window_get_title_bar_style(nativeHandle);
    return TitleBarStyle.fromValue(raw.value);
  }

  bool setContentUnderTitleBar(bool isContentUnderTitleBar) {
    return c.native_window_set_content_under_title_bar(
      nativeHandle,
      isContentUnderTitleBar,
    );
  }

  bool get isContentUnderTitleBar {
    return c.native_window_is_content_under_title_bar(nativeHandle);
  }

  static bool isContentUnderTitleBarSupported() {
    return c.native_window_is_content_under_title_bar_supported();
  }

  set hasShadow(bool value) {
    c.native_window_set_has_shadow(nativeHandle, value);
  }

  bool get hasShadow {
    return c.native_window_has_shadow(nativeHandle);
  }

  bool setCustomShadow(WindowShadow? shadow) {
    return c.native_window_set_custom_shadow(
      nativeHandle,
      shadow?.nativeHandle ?? 0,
    );
  }

  WindowShadow? get customShadow {
    final handle = c.native_window_get_custom_shadow(nativeHandle);
    if (handle == 0) return null;
    return WindowShadow.fromHandle(handle);
  }

  set opacity(double value) {
    c.native_window_set_opacity(nativeHandle, value);
  }

  double get opacity {
    return c.native_window_get_opacity(nativeHandle);
  }

  bool setVisualEffect(VisualEffect effect) {
    return c.native_window_set_visual_effect(nativeHandle, effect.raw);
  }

  VisualEffect get visualEffect {
    final raw = c.native_window_get_visual_effect(nativeHandle);
    return VisualEffect.fromValue(raw.value);
  }

  static bool isVisualEffectSupported(VisualEffect effect) {
    return c.native_window_is_visual_effect_supported(effect.raw);
  }

  bool setShape(WindowShape? shape) {
    return c.native_window_set_shape(nativeHandle, shape?.nativeHandle ?? 0);
  }

  bool get isShaped {
    return c.native_window_is_shaped(nativeHandle);
  }

  static bool isShapeSupported() {
    return c.native_window_is_shape_supported();
  }

  bool setInputShape(WindowShape? shape) {
    return c.native_window_set_input_shape(
      nativeHandle,
      shape?.nativeHandle ?? 0,
    );
  }

  bool get isInputShaped {
    return c.native_window_is_input_shaped(nativeHandle);
  }

  static bool isInputShapeSupported() {
    return c.native_window_is_input_shape_supported();
  }

  set backgroundColor(Color value) {
    final valuePointer = value.allocNative();
    c.native_window_set_background_color(nativeHandle, valuePointer.ref);
    Color.freeNative(valuePointer);
  }

  Color get backgroundColor {
    final raw = c.native_window_get_background_color(nativeHandle);
    return Color.fromNative(raw);
  }

  set isVisibleOnAllWorkspaces(bool value) {
    c.native_window_set_visible_on_all_workspaces(nativeHandle, value);
  }

  bool get isVisibleOnAllWorkspaces {
    return c.native_window_is_visible_on_all_workspaces(nativeHandle);
  }

  set isVisibleInTaskbar(bool value) {
    c.native_window_set_visible_in_taskbar(nativeHandle, value);
  }

  bool get isVisibleInTaskbar {
    return c.native_window_is_visible_in_taskbar(nativeHandle);
  }

  set isIgnoreMouseEvents(bool value) {
    c.native_window_set_ignore_mouse_events(nativeHandle, value);
  }

  bool get isIgnoreMouseEvents {
    return c.native_window_is_ignore_mouse_events(nativeHandle);
  }

  set isFocusable(bool value) {
    c.native_window_set_focusable(nativeHandle, value);
  }

  bool get isFocusable {
    return c.native_window_is_focusable(nativeHandle);
  }

  void startDragging() {
    c.native_window_start_dragging(nativeHandle);
  }

  void startResizing(ResizeEdge edge) {
    c.native_window_start_resizing(nativeHandle, edge.raw);
  }

  /// Platform-specific native object behind this handle.
  ffi.Pointer<ffi.Void> get nativeObject =>
      c.native_window_get_native_object(nativeHandle);
}
