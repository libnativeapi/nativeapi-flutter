/// A mixin class for listening to window events.
abstract mixin class WindowListener {
  /// Called when a window is blurred.
  void onWindowBlur() {}

  /// Called when a window is focused.
  void onWindowFocus() {}

  /// Called when a window is resized.
  void onWindowShow() {}

  /// Called when a window is hidden.
  void onWindowHide() {}

  /// Called when a window is maximized.
  void onWindowMaximize() {}

  /// Called when a window is unmaximized.
  void onWindowUnmaximize() {}

  /// Called when a window is minimized.
  void onWindowMinimize() {}

  /// Called when a window is restored.
  void onWindowRestore() {}
}
