import 'dart:ffi';
import 'package:ffi/ffi.dart' as ffi;

import 'menu.dart';
import 'foundation/geometry.dart';
import 'foundation/native_handle_wrapper.dart';
import 'foundation/cnativeapi_bindings_mixin.dart';

class TrayIcon
    with CNativeApiBindingsMixin
    implements NativeHandleWrapper<native_tray_icon_t> {
  final native_tray_icon_t _nativeHandle;

  TrayIcon(native_tray_icon_t nativeHandle) : _nativeHandle = nativeHandle;

  int get id => bindings.native_tray_icon_get_id(_nativeHandle);

  set icon(String icon) {
    final iconPtr = icon.toNativeUtf8().cast<Char>();
    bindings.native_tray_icon_set_icon(_nativeHandle, iconPtr);
    ffi.calloc.free(iconPtr);
  }

  String? get title {
    final titlePtr = bindings.native_display_get_name(_nativeHandle);
    final title = titlePtr.cast<ffi.Utf8>().toDartString();
    bindings.free_c_str(titlePtr);
    return title;
  }

  set title(String title) {
    final titlePtr = title.toNativeUtf8().cast<Char>();
    bindings.native_tray_icon_set_title(_nativeHandle, titlePtr);
    bindings.free_c_str(titlePtr);
  }

  String? get tooltip {
    final tooltipPtr = bindings.native_display_get_name(_nativeHandle);
    final tooltip = tooltipPtr.cast<ffi.Utf8>().toDartString();
    bindings.free_c_str(tooltipPtr);
    return tooltip;
  }

  set tooltip(String tooltip) {
    final tooltipPtr = tooltip.toNativeUtf8().cast<Char>();
    bindings.native_tray_icon_set_tooltip(_nativeHandle, tooltipPtr);
    ffi.calloc.free(tooltipPtr);
  }

  Menu? get contextMenu {
    final menuHandle = bindings.native_tray_icon_get_context_menu(
      _nativeHandle,
    );
    if (menuHandle == nullptr) {
      return null;
    }
    return Menu(menuHandle);
  }

  set contextMenu(Menu? menu) {
    bindings.native_tray_icon_set_context_menu(
      _nativeHandle,
      menu?.nativeHandle ?? nullptr,
    );
  }

  Rect? get bounds {
    final boundsPtr = ffi.calloc<native_rectangle_t>();
    final success = bindings.native_tray_icon_get_bounds(
      _nativeHandle,
      boundsPtr,
    );

    if (!success) {
      ffi.calloc.free(boundsPtr);
      return null;
    }

    final bounds = Rect.fromLTWH(
      boundsPtr.ref.x,
      boundsPtr.ref.y,
      boundsPtr.ref.width,
      boundsPtr.ref.height,
    );

    ffi.calloc.free(boundsPtr);
    return bounds;
  }

  bool show() {
    return bindings.native_tray_icon_show(_nativeHandle);
  }

  bool hide() {
    return bindings.native_tray_icon_hide(_nativeHandle);
  }

  bool get isVisible {
    return bindings.native_tray_icon_is_visible(_nativeHandle);
  }

  void showContextMenu({double? x, double? y}) {
    if (x != null && y != null) {
      bindings.native_tray_icon_show_context_menu(_nativeHandle, x, y);
    } else {
      bindings.native_tray_icon_show_context_menu_default(_nativeHandle);
    }
  }

  @override
  native_display_t get nativeHandle => _nativeHandle;

  @override
  void dispose() {
    if (contextMenu != null) {
      contextMenu!.dispose();
    }
    bindings.native_tray_icon_destroy(_nativeHandle);
  }
}
