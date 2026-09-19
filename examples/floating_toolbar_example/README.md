# floating_toolbar_example

A floating toolbar like the one above the iOS Simulator: a second **Flutter-rendered**
window — transparent, frameless, no shadow — that belongs to the main window and stays
centred above it while the main window is moved, resized, minimized and restored.
Everything is done from Dart; the runner is untouched.

It answers [nativeapi-flutter#14](https://github.com/libnativeapi/nativeapi-flutter/issues/14).

## Running

Flutter's multi-window API is experimental: it needs the **main** channel and the
windowing feature flag.

```bash
flutter channel main && flutter upgrade
flutter config --enable-windowing
flutter run -d macos   # or windows, linux
```

## Using it

- Drag, resize or minimize the main window: the pill comes along.
- Press a colour or **Stamp** in the pill: the main window changes. Both windows run in
  one isolate and share a `ChangeNotifier` — that is all the "communication between
  windows" there is.
- **Detach toolbar** makes the pill an independent window again; **Hide toolbar** hides
  it, and moving the main window does not bring it back.
- The log shows `WindowCreatedEvent` / `WindowClosedEvent` and the minimize / restore
  pair as they arrive.

## How it works

1. Both windows are created with Flutter's `WindowController` and put into a
   `ViewCollection`.
2. `controller.nativeWindow` (`package:nativeapi/windowing.dart`) turns each controller
   into a nativeapi `Window`.
3. The toolbar window is dressed from Dart: `titleBarStyle = hidden`,
   `isWindowControlButtonsVisible = false`, `backgroundColor = transparent`,
   `hasShadow = false`, `isResizable = false`, `isMovable = false`,
   `isVisibleInTaskbar = false`. The widget tree above it paints nothing opaque
   (`MaterialApp.color` and `Scaffold.backgroundColor` are transparent).
4. `toolbar.setParentWindow(main)` makes it a child window: it stays above the main
   window and hides while the main window is minimized.
5. A `WindowManager` listener re-centres the toolbar on the main window's
   `WindowMovedEvent` and `WindowResizedEvent`.
6. Closing the main window closes the toolbar first, then itself: what closing a parent
   does to its children differs between platforms, closing them yourself does not.

## Platform notes

| | follows a move | stays above / hides with the parent |
| --- | --- | --- |
| macOS | natively (a child `NSWindow` moves with its parent); step 5 only re-centres after a resize | yes |
| Windows | through step 5 (an owned window does not move with its owner) | yes |
| Linux | through step 5 on X11; on Wayland a client cannot position its windows, so the toolbar is placed by the compositor | stays above; minimizing with the parent is up to the window manager |

A GUI test lives in the workspace repository: `tools/gui/flutter_floating_toolbar_test.py`.
