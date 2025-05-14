/// A mixin class for listening to keyboard events.
abstract mixin class KeyboardListener {
  /// Called when a key is pressed.
  void onKeyPressed(int keyCode) {}

  /// Called when a key is released.
  void onKeyReleased(int keyCode) {}
}
