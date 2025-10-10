/// Base class for all events in the generic event system.
/// Events should inherit from this class and provide their own data.
abstract class Event {
  /// The time when this event was created
  final DateTime timestamp;

  Event() : timestamp = DateTime.now();

  /// Get a string representation of the event type (for debugging)
  String get typeName => runtimeType.toString();
}

/// Generic event listener interface providing type-safe event handling.
///
/// This interface supports both generic and specific event handling:
/// - Use [EventListener<Event>] to handle all event types (requires manual type checking)
/// - Use [EventListener<SpecificEventType>] for compile-time type safety with specific events
///
/// Example:
/// ```dart
/// class MyListener implements EventListener<MyCustomEvent> {
///   @override
///   void onEvent(MyCustomEvent event) {
///     // Handle the event with full type safety
///   }
/// }
/// ```
abstract class EventListener<T extends Event> {
  /// Handles an incoming event of type [T].
  ///
  /// The event parameter is guaranteed to be of type [T] or a subtype.
  /// Implementation should process the event according to the listener's logic.
  void onEvent(T event);
}

/// A callback-based event listener that wraps function callbacks into the EventListener interface.
///
/// This implementation allows using function references, lambda functions, or any callable
/// as event handlers without requiring a full class implementation. It's particularly useful
/// for simple event handling scenarios or when you want to use inline functions.
///
/// Example usage:
/// ```dart
/// // Using a lambda function
/// var listener = CallbackEventListener<MyEvent>((event) => print('Received: $event'));
///
/// // Using a function reference
/// void handleMyEvent(MyEvent event) { /* handle event */ }
/// var listener = CallbackEventListener<MyEvent>(handleMyEvent);
/// ```
class CallbackEventListener<T extends Event> extends EventListener<T> {
  /// The callback function that will be invoked when an event is received.
  final void Function(T event) callback;

  /// Creates a new callback-based event listener with the specified [callback] function.
  ///
  /// The [callback] must accept a single parameter of type [T] and return void.
  CallbackEventListener(this.callback);

  @override
  void onEvent(T event) {
    callback(event);
  }
}
