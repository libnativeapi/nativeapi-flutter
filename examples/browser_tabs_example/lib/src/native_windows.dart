// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'dart:ffi' as ffi;
import 'dart:ui' show Offset;

import 'package:flutter/src/widgets/_window.dart' as fw;
import 'package:flutter/src/widgets/_window_linux.dart' as fw_linux;
import 'package:flutter/src/widgets/_window_macos.dart' as fw_macos;
import 'package:flutter/src/widgets/_window_win32.dart' as fw_win32;
import 'package:nativeapi/nativeapi.dart' as na;

/// The native window behind a Flutter window controller, as a nativeapi
/// [na.Window].
///
/// Flutter hands out an `NSWindow*` on macOS, an `HWND` on Windows, and a
/// `GtkWindow*` on Linux; these are exactly the handles nativeapi wraps, and
/// wrapping reuses the ID already attached to the native window, so the result
/// compares equal (by [na.Window.id]) to what `WindowManager` returns.
na.Window? nativeWindowOf(fw.BaseWindowController controller) {
  if (controller.isDestroyed) return null;
  final ffi.Pointer<ffi.Void> handle = switch (controller) {
    final fw_macos.BaseWindowControllerMacOS c => c.windowHandle,
    final fw_win32.BaseWindowControllerWin32 c => c.windowHandle,
    final fw_linux.BaseWindowControllerLinux c => c.windowHandle,
    _ => ffi.nullptr,
  };
  if (handle == ffi.nullptr) return null;
  return na.Window.createWithNativeWindow(handle);
}

extension NativeWindowGeometry on na.Window {
  /// Offset from the window's outer frame to its content area (title bar and
  /// left border), in logical pixels.
  ///
  /// `WindowDragSession` anchors on the frame while Flutter reports positions
  /// inside the content, so an anchor derived from a pointer position needs
  /// this added.
  Offset get contentInset => contentBounds.topLeft - bounds.topLeft;
}
