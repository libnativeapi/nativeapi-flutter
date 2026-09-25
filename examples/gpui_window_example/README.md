# gpui_window_example

A control panel for the nativeapi `Window` API: every window of the app and
every display drawn to scale, and the selected window driven through geometry,
state, style flags, title bar, opacity, always-on-top, visual effects and more,
with a live log of window events. It is the [GPUI](https://www.gpui.rs)
counterpart of `flutter_window_example`, built on the Rust binding.

## Running

```bash
cd examples/gpui_window_example
cargo run
```

This crate is its own cargo workspace, not a member of the root one: GPUI is a
large dependency with its own platform requirements, and the root workspace's CI
builds every member. It enables GPUI's `runtime_shaders` feature, so building on
macOS does not need Xcode's Metal toolchain.

## Using it

The page has the same app bar, three tabs and sections as the Flutter example:

- **App bar** — the window count, a **⋯** menu with *Minimize All*,
  *Restore All*, *Show All* and *Hide All*, and **Refresh** to re-read the
  window list (it is also polled every 500 ms).
- **Canvas** — the displays (bezel, work area, name) and every window (frame,
  title bar, content area, sizes and position) to scale. Click a window to
  select it; that opens the Actions tab. With a window selected, the Canvas tab
  also shows its identity, geometry, state badges and quick actions (Maximize,
  Minimize, Restore, Hide, More Actions). **+** / **−** / **⤢** zoom in, out
  and back to fit; scroll to pan a zoomed canvas.
- **Actions** — for the selected window: Visibility, Window State, Focus,
  Position & Size, Size Constraints, Appearance (title bar colors and style,
  content under the title bar, shadow, always on top / bottom, opacity),
  Visual Effects, Background Color, Advanced (resizable, movable, minimizable,
  maximizable, fullscreenable, closable), Platform Specific (control buttons,
  all workspaces, taskbar, ignore mouse events, focusable), Interactions
  (Start Dragging, Start Resizing) and Title. A green banner confirms each
  action for three seconds.
- **Events** — every `WindowEvent` (focused, blurred, minimized, maximized,
  restored, created, closed, moved, resized) and the logged actions, newest
  first; a move or resize in progress stays on one line.

The window you are looking at is one of the listed windows, so its own
actions apply to this panel: *Hide* or *Ignore Mouse Events* leave you without
a way back, as in the Flutter example.

### Differences from the Flutter example

GPUI has no widget library, so the Material widgets are small hand-made
equivalents; where it lacks something, the example does the closest thing:

| Flutter | Here |
| --- | --- |
| Material icons on buttons, tabs and cards | Text only (GPUI ships no icon font); the app bar uses `⋯` and `↻`. |
| `InteractiveViewer` (pinch, drag to pan) | Zoom with the buttons, pan by scrolling. |
| `Slider` for opacity | A hand-made slider: click or drag on the track, same range (0.1–1.0) and 18 steps. |
| `Switch`, `PopupMenuButton`, `MaterialBanner`, tooltips | Hand-made switch, menu and banner; no tooltips. |
| Loading spinner and error card on start | None: listing windows cannot fail in the Rust binding. |
| Start Dragging / Start Resizing act on the tap (release) | They act on the press, so holding the button and moving drags or resizes the window. |
| Fullscreen feedback reads the state right after the call | It reports the requested state: on macOS the change is animated and lands later. |

## How it works

GPUI draws the page; everything it shows comes from nativeapi:

| API | Role |
| --- | --- |
| `WindowManager::get_all` / `get` | The windows to list and draw, and a fresh handle for each action. |
| `WindowManager::add_listener` | The Events tab. |
| `DisplayManager::get_all` | The displays on the canvas. |
| `Window` getters (`bounds`, `content_bounds`, `title`, `is_*`, `opacity`, `visual_effect`, `background_color`, …) | Read on every render: the canvas, the badges, the switches and the toggling labels. |
| `Window` setters and actions (`show`, `maximize`, `set_size`, `set_title_bar_style`, `set_opacity`, `start_dragging`, …) | The buttons, switches and slider. |
| `nativeapi_gpui::WindowExt::native_window` | The nativeapi `Window` behind the GPUI window (the `NSWindow*` / `HWND`), to tell whether nativeapi can reach GPUI's windows at all. |

nativeapi calls the event listener from the platform event loop, so
`nativeapi_gpui::observe_window_events` hands the events to the entity from a
GPUI task, with a context to act in.
Window calls also run on a GPUI task rather than inside the click handler: a
call like `set_size` resizes the window synchronously, and GPUI only takes note
of its window's new size when it is not in the middle of an update.

## Platform notes

- macOS and Windows.
- Not Linux: nativeapi wraps a `GtkWindow*` there, and GPUI does not use GTK,
  so the example has no native windows to work with.
- On macOS the list includes a hidden 500×500 window besides this example's
  own: `WindowManager::get_all` returns every `NSWindow` of the app, including
  hidden helper windows (whose origin the example does not track).
