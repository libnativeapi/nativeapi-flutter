/// A mixin class for listening to events.
///
/// This class is used to listen to events from a native API.
/// It is a mixin class, so it can be used in a class that extends [Listenable].
///
/// The [addListener] and [removeListener] methods are used to add and remove listeners.
/// The [notifyListeners] method is used to notify all listeners.
///
mixin class EventListenerMixin<T> {
  final List<T> _listeners = [];

  /// Whether there are any listeners.
  bool get hasListeners => _listeners.isNotEmpty;

  /// Add a listener.
  ///
  /// The [listener] is added to the list of listeners.
  void addListener(T listener) {
    _listeners.add(listener);
  }

  /// Remove a listener.
  ///
  /// The [listener] is removed from the list of listeners.
  void removeListener(T listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners.
  ///
  /// The [callback] is called for each listener.
  void notifyListeners(Function(T) callback) {
    for (var listener in _listeners) {
      callback(listener);
    }
  }
}
