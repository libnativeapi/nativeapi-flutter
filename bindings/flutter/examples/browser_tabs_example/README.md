# browser_tabs_example

Chrome-style tabs across several windows, built on nativeapi's
`WindowDragSession` and `WindowManager.getWindowAtPoint`. Every tab's page is
a live Flutter subtree that keeps its state (edited address, like count,
scroll position, and a running timer) wherever the tab goes.

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

Two browser windows open, with four and two tabs.

- **Reorder**: drag a tab along its strip; the other tabs slide out of the way.
- **Tear off**: drag a tab more than 28 px above or below the strip. It becomes
  a new window of the same size, with the tab still under the cursor. If it
  was the window's only tab, the whole window moves instead.
- **Merge**: drag a torn-off tab over another window's strip. It joins that
  strip at the cursor right away, while you are still dragging, and you can
  keep reordering or pull it out again.
- **Move a window**: drag the empty part of a strip.
- `+` adds a tab; closing a window's last tab closes the window; the app quits
  with the last window.

Each page shows `Page state #n · … · moved between windows k×`; `n` never
changes for a tab, because its `State` is never recreated.

## How it works

- `TabsController` (`lib/src/tabs_controller.dart`) owns the windows and their
  tab lists. On a press it starts a pointer-only `WindowDragSession`; from then
  on **every** step is driven by the session's cursor position, including
  reordering: after a merge the target window never saw the press, so Flutter
  has no pointer to report there.
  - in a strip: the dragged tab's left edge follows the cursor and its index is
    updated as it crosses its neighbours;
  - leaving the strip vertically: a new `WindowController` gets the tab, and
    `start(newWindow, anchor)` keeps the grabbed point of the tab under the
    cursor (the only tab: `start(sourceWindow, anchor)`);
  - while a window follows the cursor: `getWindowAtPoint(cursor, draggedId)`
    plus the strips' screen rects find a strip to merge into; merging
    retargets the session to pointer-only, closes the dragged window, and
    carries on as a drag along the new strip.
- `TabLayout` (`lib/src/tab_layout.dart`) is the strip geometry shared by the
  widgets and the controller; `test/tab_layout_test.dart` covers it.
- All windows live in one `ViewCollection`, and each page is built under its
  tab's `GlobalKey`, so moving a tab between windows reparents the page
  instead of rebuilding it.
- `NativeDragDetector` cancels the Flutter pointer once the native session
  takes over; the press may belong to a window whose content moves away and
  that never sees the release.

## Platform notes

- The strip replaces the title bar. On macOS that is
  `setContentUnderTitleBar(true)`: the traffic lights stay on a transparent
  bar and the strip leaves room for them. Elsewhere that call returns false and
  the strip falls back to `titleBarStyle = hidden`, which takes the window
  buttons with it, so the strip carries its own close button.
- With a hidden title bar the content owns the title bar area: nativeapi keeps
  macOS from moving the window for drags there (it otherwise would, even over
  the Flutter content), so the strip moves windows itself.
- macOS, Windows, and Linux on X11 are supported by the native session. On
  Wayland applications cannot read the global cursor position, so dragging
  does not work there.
