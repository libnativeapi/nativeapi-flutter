# detachable_window_example

Tear a panel out of the main window into a window of its own, move it around,
and dock it back — like dragging a tab out of Chrome or undocking a tool window
in an IDE. The panel is the same Flutter widget subtree throughout, so its
state (text field contents, counters, scroll position, a running stopwatch)
survives every move.

## Running

Flutter's multi-window API is experimental. This example is written against the
**stable** channel (checked with Flutter 3.47.5). Stable does not offer
`flutter config --enable-windowing`, so `main()` turns the API on itself by setting
Flutter's internal `isWindowingEnabled` before the binding starts. The main channel
has since renamed parts of this API (`RegularWindowController` became
`WindowController`, `RegularWindow` became `Window`), so the example does not compile
there.

```bash
flutter channel stable && flutter upgrade
flutter run -d macos   # or windows, linux
```

This example is excluded from the repository's melos scripts because CI pins an
older stable release.

## Using it

The app opens two main windows with differently shaped slots:

| Window | Slots |
| --- | --- |
| A | a narrow sidebar on the left (240 wide), a bottom panel (210 high) |
| B | a top strip (170 high, full width), a wide sidebar on the right (330 wide) |

Both panels start in Window A. A panel takes the size of the slot it is docked
in and lays itself out for it (stacked in tall slots, side by side in wide
ones); when it pops out, its window's content area has exactly that size.

- Drag the **Inspector** or **Stopwatch** header more than 8 pixels: the
  panel pops into a window of its own, sitting exactly where it was, and
  follows the cursor. Shorter drags do nothing.
  - Release over an empty slot (including the one it came from, or one in
    the other main window) and it docks there.
  - Release anywhere else and it stays a separate window, even over the main
    window. This matches how browser tabs and IDE tool windows behave: the
    drop zones decide, not the window bounds.
- Drag a floating panel by the same header over an empty slot in the main
  window; the slot highlights and the window turns translucent. Release to
  dock.
- The header buttons, and closing a floating window, do the same without a
  drag.
- Closing a main window pops the panels docked in it out into their own
  windows; the app quits with the last main window.
- Each panel shows `State #n · moved between windows k×`: `n` never changes,
  because the `State` object is never recreated.

## How it works

The native part lives in nativeapi and knows nothing about panels or docking:

| API | Role |
| --- | --- |
| `WindowDragSession` | Follows the primary mouse button across the whole screen until it is released, optionally moving a window so a given anchor point stays under the cursor. `start()` on an active session retargets it to another window (or to tracking only) within the same gesture. Emits `WindowDragMovedEvent`, `WindowDragEndedEvent`, `WindowDragCancelledEvent`. |
| `WindowManager.getWindowAtPoint(point, excludedWindowId)` | The application window that is frontmost at a screen point, looking through the window being dragged. `null` if another application's window covers the point. |
| `Window.createWithNativeWindow(handle)` | Wraps the `NSWindow*` / `HWND` / `GtkWindow*` behind a Flutter window. |

On top of that, `lib/src/detachable/` is a small, UI-agnostic layer:

- `DetachController` owns which item is docked in which slot and which items
  float, and runs the gesture:
  1. drag starts on a docked item's handle → `start(null, …)` (track only);
  2. cursor 8 px (`popOutDistance`) from the press → create a
     `WindowController` for the item, move the item's content there, and
     `start(newWindow, anchor)` with the anchor on the pressed point, so the
     window appears exactly over the slot;
  3. while moving → `getWindowAtPoint` + the slots' screen rects decide the
     drop target: the empty slot under the cursor, if any;
  4. on release → dock into the highlighted target (destroying the window
     after the frame that moves the content out), or keep floating.
- `DetachHandle` cancels its Flutter pointer once the native session takes
  over: the press happened in a window whose content is moving away, and that
  window may never see the release, which would otherwise leave the drag
  recognizer stuck.
- `DetachableWindows` renders every window in one `ViewCollection`, which is
  what makes the move a `GlobalKey` reparent instead of a rebuild.
- `DockSlot` and `DetachHandle` are the only widgets the UI has to place.
  Slots can live in any number of host windows; slot ids just have to be
  unique across them.

`lib/main.dart` and `lib/src/demo/` are the demo built from those pieces.

`test/reparent_across_views_test.dart` checks the underlying premise without
native windows: a `GlobalKey` subtree moved between two views, each with its
own `MaterialApp`, keeps its `State`, controllers, scroll offset, and running
animation.

## Platform notes

- macOS, Windows, and Linux on X11 are supported.
- On Wayland applications cannot read the global cursor position, so
  `WindowDragSession.start` ends immediately; use the header buttons.
- On Windows, coordinates follow nativeapi's convention of physical pixels
  divided by the scale factor of the monitor they fall on.
