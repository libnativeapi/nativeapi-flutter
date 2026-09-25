// Bindings for the event loop shim in src/event_loop.h, which the build hook
// compiles into the same library as the core. Hand-written: ffigen only reads
// the core's C API headers. The names follow the C ones, as in
// bindings_generated.dart.

// ignore_for_file: non_constant_identifier_names

@ffi.DefaultAsset('package:cnativeapi/cnativeapi.dart')
library;

import 'dart:ffi' as ffi;

/// Calls [entry] on the thread that becomes the UI thread, outside any
/// isolate; the process ends when it returns. See src/event_loop.h.
@ffi.Native<
  ffi.Bool Function(ffi.Pointer<ffi.NativeFunction<ffi.Void Function()>>)
>()
external bool cnativeapi_run_ui_thread(
  ffi.Pointer<ffi.NativeFunction<ffi.Void Function()>> entry,
);

/// Prepares the platform loop. Once, on the UI thread, before the first pump.
@ffi.Native<ffi.Void Function()>()
external void cnativeapi_start_event_loop();

/// Dispatches pending platform events, waiting up to [timeout_ms] for one when
/// there is none. Returns -1 to keep going, or the exit code to quit with.
@ffi.Native<ffi.Int Function(ffi.Int)>()
external int cnativeapi_pump_event_loop(int timeout_ms);

/// Flushes stdio and ends the process with [exit_code], skipping atexit
/// handlers and static destructors. See src/event_loop.h.
@ffi.Native<ffi.Void Function(ffi.Int)>()
external void cnativeapi_exit(int exit_code);
