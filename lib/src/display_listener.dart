import 'package:nativeapi/src/display.dart';

/// A mixin class for listening to display events.
abstract mixin class DisplayListener {
  /// Called when a display is added.
  void onDisplayAdded(Display display) {}

  /// Called when a display is removed.
  void onDisplayRemoved(Display display) {}
}
