import 'dart:ffi';

abstract interface class NativeHandleWrapper<T extends NativeType> {
  /// The native handle associated with this wrapper.
  T get nativeHandle;

  /// Disposes of the native handle associated with this wrapper.
  void dispose();
}
