/// Raw FFI bindings to the nativeapi C API.
///
/// Every function is an `@Native` external resolved against the shared library
/// that this package's build hook compiles from the nativeapi core sources.
library;

export 'src/bindings_generated.dart';
