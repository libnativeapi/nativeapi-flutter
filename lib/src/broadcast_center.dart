import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

import 'package:nativeapi/src/broadcast_receiver.dart';
import 'package:nativeapi/src/event_listener_mixin.dart';
import 'package:nativeapi/src/ffi/bindings_generated.dart';
import 'ffi/bindings.dart';

class BroadcastCenter with EventListenerMixin<BroadcastReceiver> {
  BroadcastCenter._();

  static final BroadcastCenter instance = BroadcastCenter._();

  NativeApiBindings get _bindings => nativeApiBindings;

  late final ffi.NativeCallable<BroadcastReceivedCallbackFunction>
      _broadcastReceivedCallbackCallable;

  BroadcastCenter() {
    _broadcastReceivedCallbackCallable =
        ffi.NativeCallable<BroadcastReceivedCallbackFunction>.listener(
            _onBroadcastReceived);

    _bindings.broadcast_center_on_broadcast_received(
        _broadcastReceivedCallbackCallable.nativeFunction);
  }

  void _onBroadcastReceived(ffi.Pointer<ffi.Char> message) {
    print('onBroadcastReceived: ${message.cast<Utf8>().toDartString()}');
    notifyListeners(
        (l) => l.onBroadcastReceived(message.cast<Utf8>().toDartString()));
  }

  @override
  void addListener(BroadcastReceiver listener) {
    super.addListener(listener);
    if (hasListeners) _bindings.broadcast_center_start_listening();
  }

  @override
  void removeListener(BroadcastReceiver listener) {
    super.removeListener(listener);
    if (!hasListeners) _bindings.broadcast_center_stop_listening();
  }
}
