// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// ignore_for_file: unused_import, unnecessary_import

import 'dart:ffi' as ffi;

import 'package:cnativeapi/cnativeapi.dart' as c;
import 'package:ffi/ffi.dart' as pkg_ffi;

import 'foundation/color.dart';
import 'foundation/geometry.dart';
import 'image.dart';
import 'window.dart';

import 'support.dart';

import 'callbacks.dart';

typedef ViewId = int;

enum ViewLayout {
  absolute(0),
  row(1),
  column(2);

  const ViewLayout(this.value);
  final int value;

  static ViewLayout fromValue(int value) => switch (value) {
    0 => ViewLayout.absolute,
    1 => ViewLayout.row,
    2 => ViewLayout.column,
    _ => ViewLayout.absolute,
  };

  c.native_view_layout_t get raw => c.native_view_layout_t.fromValue(value);
}

enum ViewAlignment {
  stretch(0),
  start(1),
  center(2),
  end(3);

  const ViewAlignment(this.value);
  final int value;

  static ViewAlignment fromValue(int value) => switch (value) {
    0 => ViewAlignment.stretch,
    1 => ViewAlignment.start,
    2 => ViewAlignment.center,
    3 => ViewAlignment.end,
    _ => ViewAlignment.stretch,
  };

  c.native_view_alignment_t get raw =>
      c.native_view_alignment_t.fromValue(value);
}

enum TextAlignment {
  start(0),
  center(1),
  end(2);

  const TextAlignment(this.value);
  final int value;

  static TextAlignment fromValue(int value) => switch (value) {
    0 => TextAlignment.start,
    1 => TextAlignment.center,
    2 => TextAlignment.end,
    _ => TextAlignment.start,
  };

  c.native_text_alignment_t get raw =>
      c.native_text_alignment_t.fromValue(value);
}

enum ViewBackend {
  native(0),
  winUi3(1);

  const ViewBackend(this.value);
  final int value;

  static ViewBackend fromValue(int value) => switch (value) {
    0 => ViewBackend.native,
    1 => ViewBackend.winUi3,
    _ => ViewBackend.native,
  };

  c.native_view_backend_t get raw => c.native_view_backend_t.fromValue(value);
}

/// One `ViewEvent`, in its concrete form.
sealed class ViewEvent {
  const ViewEvent();

  ViewId get viewId;

  /// Reads the event out of its C form. Returns null for a variant this
  /// binding does not know about.
  static ViewEvent? fromNative(c.native_view_event_t raw) {
    if (raw.typeAsInt ==
        c.native_view_event_type_t.NATIVE_VIEW_EVENT_TYPE_FOCUSED.value) {
      return ViewFocusedEvent(viewId: raw.view_id);
    }
    if (raw.typeAsInt ==
        c.native_view_event_type_t.NATIVE_VIEW_EVENT_TYPE_BLURRED.value) {
      return ViewBlurredEvent(viewId: raw.view_id);
    }
    if (raw.typeAsInt ==
        c
            .native_view_event_type_t
            .NATIVE_VIEW_EVENT_TYPE_BUTTON_CLICKED
            .value) {
      return ButtonClickedEvent(viewId: raw.view_id);
    }
    if (raw.typeAsInt ==
        c
            .native_view_event_type_t
            .NATIVE_VIEW_EVENT_TYPE_TEXT_FIELD_CHANGED
            .value) {
      return TextFieldChangedEvent(
        viewId: raw.view_id,
        text: raw.data.text_field_changed.text == ffi.nullptr
            ? null
            : raw.data.text_field_changed.text
                  .cast<pkg_ffi.Utf8>()
                  .toDartString(),
      );
    }
    if (raw.typeAsInt ==
        c
            .native_view_event_type_t
            .NATIVE_VIEW_EVENT_TYPE_TEXT_FIELD_SUBMITTED
            .value) {
      return TextFieldSubmittedEvent(viewId: raw.view_id);
    }
    return null;
  }
}

final class ViewFocusedEvent extends ViewEvent {
  const ViewFocusedEvent({required this.viewId});

  @override
  final ViewId viewId;
}

final class ViewBlurredEvent extends ViewEvent {
  const ViewBlurredEvent({required this.viewId});

  @override
  final ViewId viewId;
}

final class ButtonClickedEvent extends ViewEvent {
  const ButtonClickedEvent({required this.viewId});

  @override
  final ViewId viewId;
}

final class TextFieldChangedEvent extends ViewEvent {
  const TextFieldChangedEvent({required this.viewId, required this.text});

  @override
  final ViewId viewId;
  final String? text;
}

final class TextFieldSubmittedEvent extends ViewEvent {
  const TextFieldSubmittedEvent({required this.viewId});

  @override
  final ViewId viewId;
}

class View {
  /// Adopts a handle returned by the C API and releases it when this
  /// object becomes unreachable.
  View.fromHandle(this.nativeHandle) {
    _finalizer.attach(this, nativeHandle, detach: this);
  }

  /// Wraps a handle owned elsewhere; releasing it stays the owner's job.
  View.borrowed(this.nativeHandle);

  /// The underlying handle-table entry.
  final int nativeHandle;

  static final Finalizer<int> _finalizer = Finalizer<int>(
    (handle) => c.native_view_free(handle),
  );

  /// Releases the handle now instead of at collection.
  void dispose() {
    _finalizer.detach(this);
    c.native_view_free(nativeHandle);
  }

  /// Creates a new `View`; returns null if the native side failed.
  static View? create() {
    final handle = c.native_view_create();
    if (handle == 0) return null;
    return View.fromHandle(handle);
  }

  /// Creates a new `View`; returns null if the native side failed.
  static View? createWithNativeView(ffi.Pointer<ffi.Void> nativeView) {
    final handle = c.native_view_create_with_native_view(nativeView);
    if (handle == 0) return null;
    return View.fromHandle(handle);
  }

  static bool isSupported() {
    return c.native_view_is_supported();
  }

  static bool isBackendSupported(ViewBackend backend) {
    return c.native_view_is_backend_supported(backend.raw);
  }

  static bool setDefaultBackend(ViewBackend backend) {
    return c.native_view_set_default_backend(backend.raw);
  }

  static ViewBackend getDefaultBackend() {
    final raw = c.native_view_get_default_backend();
    return ViewBackend.fromValue(raw.value);
  }

  ViewId get id {
    return c.native_view_get_id(nativeHandle);
  }

  ViewBackend get backend {
    final raw = c.native_view_get_backend(nativeHandle);
    return ViewBackend.fromValue(raw.value);
  }

  void addSubview(View? subview) {
    c.native_view_add_subview(nativeHandle, subview?.nativeHandle ?? 0);
  }

  void insertSubview(int index, View? subview) {
    c.native_view_insert_subview(
      nativeHandle,
      index,
      subview?.nativeHandle ?? 0,
    );
  }

  bool removeSubview(View? subview) {
    return c.native_view_remove_subview(
      nativeHandle,
      subview?.nativeHandle ?? 0,
    );
  }

  bool removeSubviewAt(int index) {
    return c.native_view_remove_subview_at(nativeHandle, index);
  }

  void clearSubviews() {
    c.native_view_clear_subviews(nativeHandle);
  }

  int get subviewCount {
    return c.native_view_get_subview_count(nativeHandle);
  }

  View? getSubviewAt(int index) {
    final handle = c.native_view_get_subview_at(nativeHandle, index);
    if (handle == 0) return null;
    return View.fromHandle(handle);
  }

  List<View> get subviews {
    final list = c.native_view_get_subviews(nativeHandle);
    final items = <View>[];
    for (var i = 0; i < list.count; i++) {
      items.add(View.fromHandle(list.views[i]));
    }
    final listPointer = pkg_ffi.calloc<c.native_view_list_t>();
    listPointer.ref = list;
    // The handles now belong to `items`; free just the array.
    c.native_view_list_release(listPointer);
    pkg_ffi.calloc.free(listPointer);
    return items;
  }

  View? get parent {
    final handle = c.native_view_get_parent(nativeHandle);
    if (handle == 0) return null;
    return View.fromHandle(handle);
  }

  Window? get window {
    final handle = c.native_view_get_window(nativeHandle);
    if (handle == 0) return null;
    return Window.fromHandle(handle);
  }

  set frame(Rectangle value) {
    final valuePointer = value.allocNative();
    c.native_view_set_frame(nativeHandle, valuePointer.ref);
    Rectangle.freeNative(valuePointer);
  }

  Rectangle get frame {
    final raw = c.native_view_get_frame(nativeHandle);
    return Rectangle.fromNative(raw);
  }

  set preferredSize(Size value) {
    final valuePointer = value.allocNative();
    c.native_view_set_preferred_size(nativeHandle, valuePointer.ref);
    Size.freeNative(valuePointer);
  }

  Size get preferredSize {
    final raw = c.native_view_get_preferred_size(nativeHandle);
    return Size.fromNative(raw);
  }

  Size get intrinsicSize {
    final raw = c.native_view_get_intrinsic_size(nativeHandle);
    return Size.fromNative(raw);
  }

  set flex(double value) {
    c.native_view_set_flex(nativeHandle, value);
  }

  double get flex {
    return c.native_view_get_flex(nativeHandle);
  }

  set alignment(ViewAlignment value) {
    c.native_view_set_alignment(nativeHandle, value.raw);
  }

  ViewAlignment get alignment {
    final raw = c.native_view_get_alignment(nativeHandle);
    return ViewAlignment.fromValue(raw.value);
  }

  set layout(ViewLayout value) {
    c.native_view_set_layout(nativeHandle, value.raw);
  }

  ViewLayout get layout {
    final raw = c.native_view_get_layout(nativeHandle);
    return ViewLayout.fromValue(raw.value);
  }

  set spacing(double value) {
    c.native_view_set_spacing(nativeHandle, value);
  }

  double get spacing {
    return c.native_view_get_spacing(nativeHandle);
  }

  set padding(EdgeInsets value) {
    final valuePointer = value.allocNative();
    c.native_view_set_padding(nativeHandle, valuePointer.ref);
    EdgeInsets.freeNative(valuePointer);
  }

  EdgeInsets get padding {
    final raw = c.native_view_get_padding(nativeHandle);
    return EdgeInsets.fromNative(raw);
  }

  set isVisible(bool value) {
    c.native_view_set_visible(nativeHandle, value);
  }

  bool get isVisible {
    return c.native_view_is_visible(nativeHandle);
  }

  set isEnabled(bool value) {
    c.native_view_set_enabled(nativeHandle, value);
  }

  bool get isEnabled {
    return c.native_view_is_enabled(nativeHandle);
  }

  set backgroundColor(Color value) {
    final valuePointer = value.allocNative();
    c.native_view_set_background_color(nativeHandle, valuePointer.ref);
    Color.freeNative(valuePointer);
  }

  Color get backgroundColor {
    final raw = c.native_view_get_background_color(nativeHandle);
    return Color.fromNative(raw);
  }

  set tooltip(String? value) {
    final valueNative = value == null
        ? ffi.nullptr
        : value.toNativeUtf8().cast<ffi.Char>();
    c.native_view_set_tooltip(nativeHandle, valueNative);
    if (valueNative != ffi.nullptr) pkg_ffi.calloc.free(valueNative);
  }

  String? get tooltip {
    final resultPointer = c.native_view_get_tooltip(nativeHandle);
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    c.free_c_str(resultPointer);
    return result;
  }

  void focus() {
    c.native_view_focus(nativeHandle);
  }

  void blur() {
    c.native_view_blur(nativeHandle);
  }

  bool get isFocused {
    return c.native_view_is_focused(nativeHandle);
  }

  /// Platform-specific native object behind this handle.
  ffi.Pointer<ffi.Void> get nativeObject =>
      c.native_view_get_native_object(nativeHandle);

  /// Registers [callback] for every `ViewEvent` this `View` emits.
  ///
  /// The callback runs synchronously on whichever thread the native side
  /// dispatches from, because the event struct is freed as soon as it
  /// returns. That thread must therefore be this isolate's own; see the
  /// package README for what that means under Flutter.
  ListenerId addListener(void Function(ViewEvent) callback) {
    final callable =
        ffi.NativeCallable<
          ffi.Void Function(
            ffi.Pointer<c.native_view_event_t>,
            ffi.Pointer<ffi.Void>,
          )
        >.isolateLocal((
          ffi.Pointer<c.native_view_event_t> event,
          ffi.Pointer<ffi.Void> _,
        ) {
          if (event == ffi.nullptr) return;
          final value = ViewEvent.fromNative(event.ref);
          if (value != null) callback(value);
        });
    return c.native_view_add_listener(
      nativeHandle,
      callable.nativeFunction,
      NativeCallbacks.userData(callable),
      NativeCallbacks.release,
    );
  }

  /// Unregisters a listener. Returns false if unknown.
  bool removeListener(ListenerId listenerId) =>
      c.native_view_remove_listener(nativeHandle, listenerId);
}

class Label extends View {
  /// Adopts a handle returned by the C API and releases it when this
  /// object becomes unreachable.
  Label.fromHandle(super.nativeHandle) : super.fromHandle();

  /// Wraps a handle owned elsewhere; releasing it stays the owner's job.
  Label.borrowed(super.nativeHandle) : super.borrowed();

  /// Creates a new `Label`; returns null if the native side failed.
  static Label? create(String text) {
    final textNative = text.toNativeUtf8().cast<ffi.Char>();
    final handle = c.native_label_create(textNative);
    pkg_ffi.calloc.free(textNative);
    if (handle == 0) return null;
    return Label.fromHandle(handle);
  }

  set text(String value) {
    final valueNative = value.toNativeUtf8().cast<ffi.Char>();
    c.native_label_set_text(nativeHandle, valueNative);
    pkg_ffi.calloc.free(valueNative);
  }

  String? get text {
    final resultPointer = c.native_label_get_text(nativeHandle);
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    c.free_c_str(resultPointer);
    return result;
  }

  set textColor(Color value) {
    final valuePointer = value.allocNative();
    c.native_label_set_text_color(nativeHandle, valuePointer.ref);
    Color.freeNative(valuePointer);
  }

  Color get textColor {
    final raw = c.native_label_get_text_color(nativeHandle);
    return Color.fromNative(raw);
  }

  set fontSize(double value) {
    c.native_label_set_font_size(nativeHandle, value);
  }

  double get fontSize {
    return c.native_label_get_font_size(nativeHandle);
  }

  set textAlignment(TextAlignment value) {
    c.native_label_set_text_alignment(nativeHandle, value.raw);
  }

  TextAlignment get textAlignment {
    final raw = c.native_label_get_text_alignment(nativeHandle);
    return TextAlignment.fromValue(raw.value);
  }
}

class Button extends View {
  /// Adopts a handle returned by the C API and releases it when this
  /// object becomes unreachable.
  Button.fromHandle(super.nativeHandle) : super.fromHandle();

  /// Wraps a handle owned elsewhere; releasing it stays the owner's job.
  Button.borrowed(super.nativeHandle) : super.borrowed();

  /// Creates a new `Button`; returns null if the native side failed.
  static Button? create(String text) {
    final textNative = text.toNativeUtf8().cast<ffi.Char>();
    final handle = c.native_button_create(textNative);
    pkg_ffi.calloc.free(textNative);
    if (handle == 0) return null;
    return Button.fromHandle(handle);
  }

  set text(String value) {
    final valueNative = value.toNativeUtf8().cast<ffi.Char>();
    c.native_button_set_text(nativeHandle, valueNative);
    pkg_ffi.calloc.free(valueNative);
  }

  String? get text {
    final resultPointer = c.native_button_get_text(nativeHandle);
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    c.free_c_str(resultPointer);
    return result;
  }
}

class TextField extends View {
  /// Adopts a handle returned by the C API and releases it when this
  /// object becomes unreachable.
  TextField.fromHandle(super.nativeHandle) : super.fromHandle();

  /// Wraps a handle owned elsewhere; releasing it stays the owner's job.
  TextField.borrowed(super.nativeHandle) : super.borrowed();

  /// Creates a new `TextField`; returns null if the native side failed.
  static TextField? create(String text) {
    final textNative = text.toNativeUtf8().cast<ffi.Char>();
    final handle = c.native_text_field_create(textNative);
    pkg_ffi.calloc.free(textNative);
    if (handle == 0) return null;
    return TextField.fromHandle(handle);
  }

  set text(String value) {
    final valueNative = value.toNativeUtf8().cast<ffi.Char>();
    c.native_text_field_set_text(nativeHandle, valueNative);
    pkg_ffi.calloc.free(valueNative);
  }

  String? get text {
    final resultPointer = c.native_text_field_get_text(nativeHandle);
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    c.free_c_str(resultPointer);
    return result;
  }

  set textColor(Color value) {
    final valuePointer = value.allocNative();
    c.native_text_field_set_text_color(nativeHandle, valuePointer.ref);
    Color.freeNative(valuePointer);
  }

  Color get textColor {
    final raw = c.native_text_field_get_text_color(nativeHandle);
    return Color.fromNative(raw);
  }

  set fontSize(double value) {
    c.native_text_field_set_font_size(nativeHandle, value);
  }

  double get fontSize {
    return c.native_text_field_get_font_size(nativeHandle);
  }

  set textAlignment(TextAlignment value) {
    c.native_text_field_set_text_alignment(nativeHandle, value.raw);
  }

  TextAlignment get textAlignment {
    final raw = c.native_text_field_get_text_alignment(nativeHandle);
    return TextAlignment.fromValue(raw.value);
  }

  set placeholder(String? value) {
    final valueNative = value == null
        ? ffi.nullptr
        : value.toNativeUtf8().cast<ffi.Char>();
    c.native_text_field_set_placeholder(nativeHandle, valueNative);
    if (valueNative != ffi.nullptr) pkg_ffi.calloc.free(valueNative);
  }

  String? get placeholder {
    final resultPointer = c.native_text_field_get_placeholder(nativeHandle);
    if (resultPointer == ffi.nullptr) return null;
    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();
    c.free_c_str(resultPointer);
    return result;
  }

  set isEditable(bool value) {
    c.native_text_field_set_editable(nativeHandle, value);
  }

  bool get isEditable {
    return c.native_text_field_is_editable(nativeHandle);
  }

  set isSecure(bool value) {
    c.native_text_field_set_secure(nativeHandle, value);
  }

  bool get isSecure {
    return c.native_text_field_is_secure(nativeHandle);
  }

  set isMultiline(bool value) {
    c.native_text_field_set_multiline(nativeHandle, value);
  }

  bool get isMultiline {
    return c.native_text_field_is_multiline(nativeHandle);
  }
}

class ImageView extends View {
  /// Adopts a handle returned by the C API and releases it when this
  /// object becomes unreachable.
  ImageView.fromHandle(super.nativeHandle) : super.fromHandle();

  /// Wraps a handle owned elsewhere; releasing it stays the owner's job.
  ImageView.borrowed(super.nativeHandle) : super.borrowed();

  /// Creates a new `ImageView`; returns null if the native side failed.
  static ImageView? create() {
    final handle = c.native_image_view_create();
    if (handle == 0) return null;
    return ImageView.fromHandle(handle);
  }

  set image(Image? value) {
    c.native_image_view_set_image(nativeHandle, value?.nativeHandle ?? 0);
  }

  Image? get image {
    final handle = c.native_image_view_get_image(nativeHandle);
    if (handle == 0) return null;
    return Image.fromHandle(handle);
  }
}
