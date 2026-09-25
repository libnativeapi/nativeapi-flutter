# gpui_floating_toolbar_example

A floating toolbar like the one above the iOS Simulator: a second
[GPUI](https://www.gpui.rs) window — transparent, frameless, no shadow — that
belongs to the main window and stays centred above it while the main window is
moved, resized, minimized and restored. The GPUI counterpart of
`flutter_floating_toolbar_example`, built on the Rust binding.

## Running

```bash
cd examples/gpui_floating_toolbar_example
cargo run
```

This crate is its own cargo workspace, not a member of the root one: GPUI is a
large dependency with its own platform requirements, and the root workspace's CI
builds every member. It enables GPUI's `runtime_shaders` feature, so building on
macOS does not need Xcode's Metal toolchain.

## Using it

- Drag, resize or minimize the main window: the pill comes along.
- Press a colour or **Stamp** in the pill: the main window changes. Both windows
  render from one GPUI entity (`src/toolbar.rs`) — that is all the
  "communication between windows" there is.
- **Detach toolbar** makes the pill an independent window again (**Attach
  toolbar** re-attaches it); **Hide toolbar** hides it (**Show toolbar**), and
  moving the main window does not bring it back.
- The log shows `Created` / `Closed` window events and the minimize / restore
  pair as they arrive.

## How it works

1. Both windows are opened with GPUI's `cx.open_window`; the main one centred on
   the primary display's work area, 120 px below its top, the toolbar (380 × 64)
   hidden, with `WindowBackgroundAppearance::Transparent` and a transparent
   title bar.
2. `nativeapi_gpui::WindowExt::native_window` turns each into a nativeapi
   `Window`.
3. The toolbar window is dressed through nativeapi:
   `set_title_bar_style(Hidden)` (which takes the window buttons with it),
   `set_background_color(transparent)`, `set_has_shadow(false)`,
   `set_resizable(false)`, `set_movable(false)`, `set_visible_in_taskbar(false)`,
   `set_content_size(380 × 64)`. The GPUI view paints nothing but the pill.
4. `toolbar.set_parent_window(Some(&main))` makes it a child window: it stays
   above the main window and hides while the main window is minimized. Then
   `show_inactive` shows it without taking focus.
5. A `WindowManager` listener re-centres the toolbar on the main window's
   `Moved` and `Resized` events. nativeapi calls it from the platform event
   loop, without a GPUI context; `nativeapi_gpui::observe_window_events` hands
   them to the model from a GPUI task, and the move itself is deferred past the
   update with `nativeapi_gpui::defer_native`.
6. Closing the main window detaches and closes the toolbar first, then itself.

Every native call that moves, resizes, shows or hides a window runs from a GPUI
task, never inside a GPUI update (a click handler, the window-open closure):
while an update runs GPUI's app state is borrowed, and GPUI drops the resize and
move notifications the call triggers.

## Differences from the Flutter example

- The **Stamp** button has no icon (GPUI ships no icon font).
- Colours approximate Flutter's indigo-seeded Material 3 theme.
- `created: main` is not logged: the main window is on screen before the
  listener is registered.
- No Linux/Wayland branch (dragging the pill with `start_dragging`): the
  example does not run on Linux at all, see below.

## Platform notes

| | follows a move | stays above / hides with the parent |
| --- | --- | --- |
| macOS | natively (a child `NSWindow` moves with its parent); step 5 only re-centres after a resize | yes |
| Windows | through step 5 (an owned window does not move with its owner) | yes |

- Checked on macOS: the pill starts centred 10 px above the main window,
  transparent and without a shadow. Moving, resizing and the buttons still
  need a real-mouse test. Not run on Windows.
- Not Linux: nativeapi wraps a `GtkWindow*` there, and GPUI does not use GTK,
  so the example has no native windows to work with (the pill would be an
  ordinary window that does not follow).
