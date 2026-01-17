import 'dart:async';

import 'package:meta/meta.dart';

import 'event.dart';

/// Mixin that provides event emission capabilities with lifecycle management.
/// Classes that use this mixin can easily add listener management
/// and event dispatching functionality.
///
/// The mixin automatically manages event listening lifecycle:
/// - `startEventListening()` is called when the first listener is added
/// - `stopEventListening()` is called when the last listener is removed
///
/// Subclasses can override these methods to manage platform-specific resources:
///
/// ```dart
/// class MyClass with EventEmitter {
///   @override
///   void startEventListening() {
///     // Start platform event monitoring
///   }
///
///   @override
///   void stopEventListening() {
///     // Stop platform event monitoring
///   }
///
///   void doSomething() {
///     // Emit an event synchronously
///     emitSync(MyEvent("some data"));
///   }
///
///   void doSomethingAsync() async {
///     // Emit an event asynchronously
///     await emitAsync(MyEvent("async data"));
///   }
/// }
///
/// final obj = MyClass();
///
/// // Add a callback listener
/// obj.addListener<MyEvent>((event) {
///   print('Received: ${event.data}');
/// });
/// ```
mixin EventEmitter {
  /// Map of event types to their listeners
  final Map<Type, Map<int, EventListener>> _listeners = {};

  /// Counter for generating unique listener IDs
  int _nextListenerId = 0;

  /// Called when the first listener is added.
  /// Subclasses can override this to start platform-specific event monitoring.
  @protected
  void startEventListening() {}

  /// Called when the last listener is removed.
  /// Subclasses can override this to stop platform-specific event monitoring.
  @protected
  void stopEventListening() {}

  /// Add a typed event listener for a specific event type.
  ///
  /// Returns a unique listener ID that can be used to remove the listener.
  int addListener<T extends Event>(EventListener<T> listener) {
    final eventType = T;
    final listenerId = _nextListenerId++;

    // Check if this is the first listener
    final wasEmpty = totalListenerCount == 0;

    _listeners.putIfAbsent(eventType, () => <int, EventListener>{});
    _listeners[eventType]![listenerId] = listener;

    // Call hook when transitioning from 0 to 1+ listeners
    if (wasEmpty) {
      startEventListening();
    }

    return listenerId;
  }

  /// Add a callback function as a listener for a specific event type.
  ///
  /// Returns a unique listener ID that can be used to remove the listener.
  int addCallbackListener<T extends Event>(void Function(T event) callback) {
    return addListener(CallbackEventListener<T>(callback));
  }

  /// Remove a listener by its ID.
  ///
  /// Returns true if the listener was found and removed, false otherwise.
  bool removeListener(int listenerId) {
    for (final eventListeners in _listeners.values) {
      if (eventListeners.remove(listenerId) != null) {
        // Check if this was the last listener
        if (totalListenerCount == 0) {
          stopEventListening();
        }
        return true;
      }
    }
    return false;
  }

  /// Remove all listeners for a specific event type, or all listeners if no type is specified.
  ///
  /// Examples:
  /// ```dart
  /// // Remove all listeners for a specific event type
  /// emitter.removeAllListeners<MyCustomEvent>();
  ///
  /// // Remove all listeners for all event types
  /// emitter.removeAllListeners();
  ///
  /// // Remove all listeners for a specific event type using explicit type
  /// emitter.removeAllListeners(MyCustomEvent);
  /// ```
  void removeAllListeners<T extends Event>([Type? eventType]) {
    final hadListeners = totalListenerCount > 0;

    if (eventType != null) {
      final listeners = _listeners[eventType];
      if (listeners != null) {
        listeners.clear();
      }
    } else {
      for (final eventListeners in _listeners.values) {
        eventListeners.clear();
      }
      _listeners.clear();
    }

    // Call hook if we had listeners and now have none
    if (hadListeners && totalListenerCount == 0) {
      stopEventListening();
    }
  }

  /// Get the number of listeners registered for a specific event type.
  int getListenerCount<T extends Event>() {
    final eventType = T;
    return _listeners[eventType]?.length ?? 0;
  }

  /// Get the total number of registered listeners across all event types.
  int get totalListenerCount {
    return _listeners.values
        .map((listeners) => listeners.length)
        .fold(0, (sum, count) => sum + count);
  }

  /// Check if there are any listeners for a specific event type.
  bool hasListeners<T extends Event>() {
    return getListenerCount<T>() > 0;
  }

  /// Emit an event synchronously to all registered listeners.
  /// This will call all listeners immediately on the current thread.
  void emitSync(Event event) {
    final eventType = event.runtimeType;
    final listeners = _listeners[eventType];

    if (listeners != null) {
      // Create a copy of the listeners list to avoid concurrent modification
      final listenersCopy = List<EventListener>.from(listeners.values);

      for (final listener in listenersCopy) {
        try {
          listener.onEvent(event);
        } catch (e) {
          // Log error but continue with other listeners
          print('Error in event listener: $e');
        }
      }
    }
  }

  /// Emit an event synchronously using a factory function.
  /// This creates the event object and emits it immediately.
  void emitSyncWithFactory<T extends Event>(T Function() eventFactory) {
    final event = eventFactory();
    emitSync(event);
  }

  /// Emit an event asynchronously.
  /// The event will be dispatched on the next microtask.
  Future<void> emitAsync(Event event) async {
    return Future.microtask(() => emitSync(event));
  }

  /// Emit an event asynchronously using a factory function.
  Future<void> emitAsyncWithFactory<T extends Event>(
    T Function() eventFactory,
  ) async {
    return Future.microtask(() {
      final event = eventFactory();
      emitSync(event);
    });
  }

  /// Dispose of the event emitter and clean up resources.
  /// Classes using this mixin should call this method when disposing.
  void disposeEventEmitter() {
    final hadListeners = totalListenerCount > 0;

    // Clear all listeners
    _listeners.clear();

    // Call hook if we had listeners
    if (hadListeners) {
      stopEventListening();
    }
  }
}

/// Extension methods for easier event listener registration
extension EventEmitterExtensions on EventEmitter {
  /// Convenience method to add a callback listener using a function
  int on<T extends Event>(void Function(T event) callback) {
    return addCallbackListener<T>(callback);
  }

  /// Convenience method to add a one-time listener that removes itself after firing
  int once<T extends Event>(void Function(T event) callback) {
    late int listenerId;
    listenerId = addCallbackListener<T>((event) {
      removeListener(listenerId);
      callback(event);
    });
    return listenerId;
  }

  /// Remove a listener (alias for removeListener)
  bool off(int listenerId) {
    return removeListener(listenerId);
  }
}

/// Base class that implements EventEmitter as a class instead of mixin.
/// Use this when you can't use the mixin (e.g., when extending another class).
class BaseEventEmitter with EventEmitter {
  void dispose() {
    disposeEventEmitter();
  }
}
