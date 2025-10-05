import 'package:cnativeapi/cnativeapi.dart';

export 'package:cnativeapi/cnativeapi.dart' hide cnativeApiBindings;

/// A mixin that exposes the shared [CNativeApiBindings] instance used to
/// communicate with the underlying native API.
///
/// Usage example:
/// ```dart
/// class MyClass with CNativeApiBindingsMixin {
///   void myMethod() {
///     // Use the bindings to invoke native functionality.
///     bindings.someMethod();
///   }
/// }
/// ```
mixin class CNativeApiBindingsMixin {
  /// Returns the shared [CNativeApiBindings] instance used for native calls.
  CNativeApiBindings get bindings => cnativeApiBindings;
}
