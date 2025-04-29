/// A mixin class for listening to keyboard events.
abstract mixin class KeyboardListener {
  /// Called when a key is pressed.
  void onKeyPressed(String key) {}

  /// Called when a key is released.
  void onKeyReleased(String key) {}
}
