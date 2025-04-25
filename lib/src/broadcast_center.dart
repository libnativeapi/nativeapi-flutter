import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

import 'package:nativeapi/src/broadcast_receiver.dart';
import 'package:nativeapi/src/ffi/bindings_generated.dart';
import 'ffi/bindings.dart';

class BroadcastCenter {
  BroadcastCenter._() {
    _broadcastReceivedCallbackCallable =
        ffi.NativeCallable<BroadcastReceivedCallbackFunction>.listener(
            _onBroadcastReceived);
    _bindings.broadcast_center_on_broadcast_received(
        _broadcastReceivedCallbackCallable.nativeFunction);
  }

  static final BroadcastCenter instance = BroadcastCenter._();

  NativeApiBindings get _bindings => nativeApiBindings;

  late final ffi.NativeCallable<BroadcastReceivedCallbackFunction>
      _broadcastReceivedCallbackCallable;

  final Map<String, List<BroadcastReceiver>> _receivers = {};

  void _onBroadcastReceived(
    ffi.Pointer<ffi.Char> topic,
    ffi.Pointer<ffi.Char> message,
  ) {
    String topicStr;
    String messageStr;

    try {
      topicStr = topic.cast<Utf8>().toDartString();
    } catch (e) {
      print('Error converting topic to string: $e');
      topicStr = 'invalid_topic';
    }

    try {
      messageStr = message.cast<Utf8>().toDartString();
    } catch (e) {
      print('Error converting message to string: $e');
      messageStr = 'invalid_message';
    }

    print('onBroadcastReceived: $topicStr, $messageStr');
    notifyReceivers(
      topicStr,
      (l) => l.onBroadcastReceived(
        topicStr,
        messageStr,
      ),
    );
  }

  /// Send a broadcast message to all receivers of a given topic
  void sendBroadcast(String topic, String message) {
    _bindings.broadcast_center_send_broadcast(
      topic.toNativeUtf8().cast<ffi.Char>(),
      message.toNativeUtf8().cast<ffi.Char>(),
    );
  }

  /// Register a receiver for a given topic
  void registerReceiver(String topic, BroadcastReceiver listener) {
    if (_receivers[topic] == null) {
      _receivers[topic] = [];
    }
    _receivers[topic]?.add(listener);
    _bindings.broadcast_center_register_receiver(
      topic.toNativeUtf8().cast<ffi.Char>(),
    );
  }

  /// Unregister a receiver for a given topic
  void unregisterReceiver(String topic, BroadcastReceiver listener) {
    _receivers[topic]?.remove(listener);
    _bindings.broadcast_center_unregister_receiver(
      topic.toNativeUtf8().cast<ffi.Char>(),
    );
  }

  /// Notify all receivers of a given topic and message
  ///
  /// The [topic] is the topic of the broadcast.
  /// The [callback] is called for each receiver.
  void notifyReceivers(String topic, Function(BroadcastReceiver) callback) {
    print('notifyReceivers: $topic');

    final firstTopic = _receivers.keys.first.toString();

    for (var listener in _receivers[firstTopic] ?? []) {
      print('notifyReceivers: $topic, $listener');
      callback(listener);
    }
  }
}
