// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'dart:ffi' as ffi;
import 'dart:ui' show Offset;

import 'package:flutter/src/widgets/_window.dart' as fw;
import 'package:flutter/src/widgets/_window_linux.dart' as fw_linux;
import 'package:flutter/src/widgets/_window_macos.dart' as fw_macos;
import 'package:flutter/src/widgets/_window_win32.dart' as fw_win32;

import '../window.dart';

/// The native window behind a Flutter window controller, as a nativeapi
/// [Window].
///
/// Flutter hands out an `NSWindow*` on macOS, an `HWND` on Windows, and a
/// `GtkWindow*` on Linux; these are exactly the handles nativeapi wraps, and
/// wrapping reuses the ID already attached to the native window, so the result
/// compares equal (by [Window.id]) to what `WindowManager` returns.
///
/// Returns null once the controller is destroyed, or on a platform whose
/// controller does not expose a window handle.
Window? nativeWindowOf(fw.BaseWindowController controller) {
  final ffi.Pointer<ffi.Void> handle;
  try {
    handle = switch (controller) {
      final fw_macos.WindowControllerMacOS c => c.windowHandle,
      final fw_win32.WindowControllerWin32 c => c.windowHandle,
      final fw_linux.WindowControllerLinux c => c.windowHandle,
      _ => ffi.nullptr,
    };
  } on StateError {
    // The stable channel has no `isDestroyed`; a destroyed controller throws
    // from `windowHandle` instead.
    return null;
  }
  if (handle == ffi.nullptr) return null;
  return Window.createWithNativeWindow(handle);
}

extension FlutterWindowControllerNativeWindow on fw.BaseWindowController {
  /// Shorthand for [nativeWindowOf].
  Window? get nativeWindow => nativeWindowOf(this);
}

extension NativeWindowGeometry on Window {
  /// Offset from the window's outer frame to its content area (title bar and
  /// left border), in logical pixels.
  ///
  /// `WindowDragSession` anchors on the frame while Flutter reports positions
  /// inside the content, so an anchor derived from a pointer position needs
  /// this added.
  Offset get contentInset => contentBounds.topLeft - bounds.topLeft;
}
