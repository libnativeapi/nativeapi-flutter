// Hand-written: runs the platform event loop for a plain Dart program.

import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io' show stderr;
import 'dart:isolate';

import 'package:cnativeapi/cnativeapi.dart' as c;

import 'application.dart';

/// How long one pump waits for a platform event when none is queued, in ms.
/// It bounds how late a Dart timer or message can be while the app is idle.
const _idleWaitMs = 8;

/// Runs a desktop app from a plain Dart program (`dart run`), without Flutter.
///
/// [main] builds the app: it creates windows and views and registers
/// listeners. It runs in a new isolate that lives on the platform's UI thread,
/// where every call into nativeapi and every event callback then happens,
/// while that isolate's timers, futures and streams keep working as usual.
/// Pass a top-level or static function: it crosses into the new isolate, so
/// it must not capture state.
///
/// The process ends when the app quits: through `Application.instance.quit()`,
/// with its exit code, or when the user quits it from the Dock or with Cmd+Q.
/// Listeners registered in [main] still get `ApplicationExitingEvent` first.
/// The process then ends at once, without the teardown `exit()` from
/// `dart:io` would run (the Dart VM's threads are still busy): windows and
/// tray icons go with it. An uncaught error in the app prints and exits with
/// status 255, as it would in the main isolate.
///
/// Call it at most once, from `main()`, before anything else in nativeapi:
/// the objects nativeapi hands out belong to the thread that created them.
///
/// On macOS AppKit only works on the process's first thread, which the Dart
/// VM keeps parked while `main()` runs elsewhere; the app takes that thread
/// over. On Windows and Linux it gets a thread of its own. Not for Flutter,
/// whose engine already runs the loop, nor for Android or iOS: throws a
/// [StateError] there.
void runNativeApp(void Function() main) {
  // Only final locals can be captured by a callback bound to the group.
  final appMain = main;
  final entry = ffi.NativeCallable<ffi.Void Function()>.isolateGroupBound(() {
    final app = Isolate.create(debugName: 'nativeapi');
    app.runSync(() => _start(appMain));
    // Returns once the app isolate has nothing left to run for.
    app.runEventLoopSync();
  });
  if (!c.cnativeapi_run_ui_thread(entry.nativeFunction)) {
    entry.close();
    throw StateError(
      'runNativeApp: no UI thread to run on. It runs once per process, from a '
      'plain Dart program on macOS, Windows or Linux.',
    );
  }
  // The app isolate ends the process; until then this isolate stays up, and
  // with it `entry`, which the UI thread is still inside.
  RawReceivePort(null, 'runNativeApp');
}

void _start(void Function() main) {
  runZonedGuarded(() {
    c.cnativeapi_start_event_loop();
    main();
    // After main(), so the app's own listeners hear about the exit first.
    // macOS and Linux end a quit here, Windows in _pump().
    Application.instance.addListener((event) {
      if (event is ApplicationExitingEvent) c.cnativeapi_exit(event.exitCode);
    });
    Timer.run(_pump);
  }, _fail);
}

void _pump() {
  final exitCode = c.cnativeapi_pump_event_loop(_idleWaitMs);
  if (exitCode >= 0) {
    c.cnativeapi_exit(exitCode);
  }
  // A timer, not a loop: the isolate's own messages get their turn between
  // two pumps.
  Timer.run(_pump);
}

Never _fail(Object error, StackTrace stackTrace) {
  stderr
    ..writeln('Unhandled exception:')
    ..writeln(error)
    ..writeln(stackTrace);
  c.cnativeapi_exit(255);
  throw StateError('unreachable');
}
