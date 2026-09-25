# gpui_browser_tabs_example

Chrome-style tabs across several windows — the [GPUI](https://www.gpui.rs)
counterpart of `flutter_browser_tabs_example`, built on the Rust binding's
`WindowDragSession` and `WindowManager::get_window_at_point`. Every tab's page
is a GPUI entity that keeps its state (address, like count, scroll position,
and a running timer) wherever the tab goes.

## Running

```bash
cd examples/gpui_browser_tabs_example
cargo run
```

This crate is its own cargo workspace, not a member of the root one: GPUI is a
large dependency with its own platform requirements, and the root workspace's CI
builds every member. It enables GPUI's `runtime_shaders` feature, so building on
macOS does not need Xcode's Metal toolchain. `cargo test` runs the strip
geometry tests (`src/layout.rs`).

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
changes for a tab, because its page entity is never recreated.

GPUI has no built-in text input, so unlike the Flutter example the address bar
is not editable. Its state comes from navigation instead: click a paragraph to
go to `…/tab-n/paragraph-i`, and `←` goes back. The history travels with the
tab, like the edited address does in the Flutter example.

## How it works

GPUI owns the windows and draws everything. nativeapi supplies what GPUI does
not:

| API | Role |
| --- | --- |
| `WindowDragSession` | Follows the mouse button globally, even after the dragged tab moved to another window. `start(None, …)` tracks the pointer only (reordering), `start(Some(window), anchor)` retargets it mid-gesture to a window that follows the cursor (tear-off). |
| `WindowManager::get_window_at_point(point, excluded)` | Which window's strip is under the cursor, looking through the dragged window (merge). |
| `Window::content_bounds` / `set_content_bounds` / `focus` | Strip hit testing in screen coordinates, exact placement of a torn-off window, and keeping it in front after the release. |
| `nativeapi_gpui::WindowExt::native_window` | The nativeapi `Window` behind a GPUI window (the `NSWindow*` / `HWND`). |

- `Tabs` (`src/tabs.rs`) owns the windows, their tab lists and the gesture. On
  a press it starts a pointer-only session; from then on **every** step is
  driven by the session's cursor position, including reordering: after a
  merge the target window never saw the press, so GPUI has no mouse events to
  report there. nativeapi calls the drag listener from the platform event
  loop, so `nativeapi_gpui::observe_drag_session` hands the events to the
  model from a GPUI task, with a context to act in.
  - in a strip: the dragged tab's left edge follows the cursor and its index is
    updated as it crosses its neighbours;
  - leaving the strip vertically: a new window gets the tab, placed so the
    grabbed point stays under the cursor, and the session is retargeted to it
    (the only tab: to the source window). The window is opened outside any
    update of `Tabs`, because GPUI draws a new window once before returning;
  - while a window follows the cursor: `get_window_at_point(cursor, dragged)`
    plus the strips' screen rects find a strip to merge into; merging
    retargets the session to pointer-only, closes the dragged window, and
    carries on as a drag along the new strip.
- `TabLayout` (`src/layout.rs`) is the strip geometry shared by the view and
  the controller.
- A tab's page (`src/page.rs`) is an entity rendered by whichever window shows
  the tab. Its scroll offset lives in a `ScrollHandle` it owns rather than in
  the window's element state, so it survives the move too.
- `BrowserWindowView` (`src/views.rs`) draws the strip and eases the other
  tabs into their slots (GPUI has no implicit animation like Flutter's
  `AnimatedPositioned`).

## Platform notes

- macOS and Windows.
- The strip replaces the title bar (GPUI's `appears_transparent` title bar).
  On macOS the traffic lights stay, centred in the strip, and the strip leaves
  room for them. On Windows the title bar goes away with its buttons, so the
  strip carries its own close button.
- The windows are opened with `is_movable: false`: the content owns the title
  bar band, so macOS must not move the window for drags there; the strip moves
  windows itself through the drag session.
- Not Linux: nativeapi wraps a `GtkWindow*` there, and GPUI does not use GTK,
  so the example has no native windows to work with.
