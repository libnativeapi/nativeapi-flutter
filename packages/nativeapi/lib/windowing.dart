/// Bridges Flutter's experimental multi-window API to nativeapi.
///
/// Kept out of `package:nativeapi/nativeapi.dart` because it imports Flutter's
/// internal windowing libraries, which need the main channel and
/// `flutter config --enable-windowing`. Apps that never import this library
/// are unaffected by changes to those internals.
library;

export 'src/windowing/flutter_window.dart';
