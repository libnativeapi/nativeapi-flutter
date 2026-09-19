/// Bridges Flutter's experimental multi-window API to nativeapi.
///
/// Kept out of `package:nativeapi/nativeapi.dart` because it imports Flutter's
/// internal windowing libraries, whose names still change between releases; it
/// follows the stable channel (checked with Flutter 3.47.5). Apps that never
/// import this library are unaffected by changes to those internals.
///
/// The stable channel does not offer `flutter config --enable-windowing`: an app
/// sets `isWindowingEnabled = true` (from
/// `package:flutter/src/foundation/_features.dart`) before its binding starts.
library;

export 'src/windowing/flutter_window.dart';
