# gpui_detachable_window_example

Tear a panel out of the main window into a window of its own, move it around,
and dock it back — the [GPUI](https://www.gpui.rs) counterpart of
`flutter_detachable_window_example` and `deno_detachable_window_example`, built
on the Rust binding.

## Running

```bash
cd examples/gpui_detachable_window_example
cargo run
```

This crate is its own cargo workspace, not a member of the root one: GPUI is a
large dependency with its own platform requirements, and the root workspace's CI
builds every member. It enables GPUI's `runtime_shaders` feature, so building on
macOS does not need Xcode's Metal toolchain.

## Using it

- Drag the **Inspector** or **Stopwatch** header more than 8 px: the panel pops
  into its own window exactly where it was and follows the cursor.
- Drag a floating panel by its header over an empty slot: the slot highlights
  and the window turns translucent. Release to dock; release anywhere else and
  it keeps floating.
- **Pop out** / **Dock** do the same without a drag; closing a floating window
  docks its panel back.
- The click counter, the instance number and a running stopwatch survive every
  move, and `moved k×` counts the moves.

## How it works

GPUI owns the windows and draws everything. nativeapi supplies what GPUI does
not:

| API | Role |
| --- | --- |
| `WindowDragSession` | Follows the mouse button globally, even after the drag's content moved to a new window; `start(Some(window), anchor)` retargets it mid-gesture. |
| `WindowManager::get_window_at_point(point, excluded)` | What is under the cursor, looking through the dragged window. |
| `Window::content_bounds` / `set_content_bounds` / `set_opacity` | Exact placement and the drop-target feedback. |
| `Window::with_native_window` | Wraps the `NSWindow*` / `HWND` behind a GPUI window (`src/native.rs`, through `raw-window-handle`). |

A panel's content is a GPUI entity, rendered by whichever window currently
shows it, so moving it between windows never recreates it. `src/detach.rs` owns
which panel sits in which slot, which panels float, and the gesture; nativeapi
calls the drag listener from the platform event loop, so the events are
forwarded over a channel to a GPUI task that has a context to act in.

## Platform notes

- macOS and Windows.
- Not Linux: nativeapi wraps a `GtkWindow*` there, and GPUI does not use GTK,
  so the example has no native windows to work with.
