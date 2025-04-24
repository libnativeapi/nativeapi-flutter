/// A mixin class for listening to broadcast events.
abstract mixin class BroadcastReceiver {
  /// Called when a broadcast is received.
  void onBroadcastReceived(String topic, String message) {}
}
