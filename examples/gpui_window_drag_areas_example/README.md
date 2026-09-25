# gpui_window_drag_areas_example

Custom window chrome in [GPUI](https://www.gpui.rs): a coloured bar that moves
the window and eight inset resize handles — the GPUI counterpart of
`flutter_window_drag_areas_example`, built on the Rust binding.

## Running

```bash
cd examples/gpui_window_drag_areas_example
cargo run
```

This crate is its own cargo workspace, not a member of the root one: GPUI is a
large dependency with its own platform requirements, and the root workspace's CI
builds every member. It enables GPUI's `runtime_shaders` feature, so building on
macOS does not need Xcode's Metal toolchain.

## Using it

- Drag the **Drag here to move** bar: the window moves. Double-click it to
  maximize, and again to restore.
- The tinted frame is eight resize handles (four edges, four corners). They are
  inset 16 px from the window edge on purpose, so it is clear the app does the
  resizing, not the native frame. **Edges: all** switches to right and bottom
  only (**Edges: right and bottom**) and back.
- The middle of the window lets the pointer through: **+1** counts clicks, and
  the size readout follows every resize.

The native title bar and window buttons are hidden, the window opens at
720 × 480 in the middle of the screen and cannot get smaller than 480 × 320.

## How it works

| API | Role |
| --- | --- |
| `Window::set_title_bar_style(TitleBarStyle::Hidden)` | No native title bar or buttons; on macOS the window also stops moving from its (now invisible) title bar. GPUI opens it with `appears_transparent`, so the content already covers the frame and hiding the bar does not resize it. |
| `Window::start_dragging` | Hands the press to the platform's window move (`-performWindowDragWithEvent:` on macOS, `WM_NCLBUTTONDOWN`/`HTCAPTION` on Windows). |
| `Window::start_resizing(ResizeEdge)` | Resizes from one edge or corner until the button is released. |
| `Window::is_maximized` / `maximize` / `unmaximize` | The double click on the bar. |
| `Window::with_native_window` | Wraps the `NSWindow*` / `HWND` behind the GPUI window (`src/native.rs`, through `raw-window-handle`). |

Like nativeapi_flutter's `DragToMoveArea` and `DragToResizeArea`, a press only
arms the bar or a handle; the first move with the button down (2 px) starts the
native drag, as a pan gesture would. The double click is read from GPUI's
`MouseDownEvent::click_count`.

The native calls run from a GPUI task, not from the mouse handler itself: both
track the mouse until release (a nested event loop on macOS, the modal
size/move loop on Windows) and resize or move the window meanwhile. Inside an
event handler GPUI's app state is borrowed, so GPUI would drop the resize
notifications and the content would not follow the new size.

### Geometry for a GUI test

In content coordinates (logical px, origin at the top-left of the window,
which has no title bar): handle bands are 12 px thick, starting 16 px from each
edge — the middle of the left band is x = 22, of the top band y = 22, of the
right band x = W − 22, of the bottom band y = H − 22. Corner handles are the
12 × 12 squares at those intersections. The move bar spans x 28 … W − 28,
y 28 … 72. GPUI makes the 720 × 480 window 720 × 481 on macOS (its own
content-rect rounding, before nativeapi touches it), so read the real frame
rather than assuming 480.

## Differences from the Flutter example

- Colours approximate Flutter's indigo-seeded Material 3 theme; the buttons are
  plain GPUI elements.
- Minimum and initial size come from GPUI's `WindowOptions` rather than from
  nativeapi's `minimum_size` / `content_size` / `center`.

## Platform notes

- macOS and Windows. Built and checked on macOS (initial layout); the drag and
  resize gestures still need a real-mouse test. Not run on Windows.
- Not Linux: nativeapi wraps a `GtkWindow*` there, and GPUI does not use GTK,
  so the example has no native window to work with.
