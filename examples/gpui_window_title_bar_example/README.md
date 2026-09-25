# gpui_window_title_bar_example

Every state a window's title bar can be in, on one screen, for testing by hand —
the [GPUI](https://www.gpui.rs) counterpart of `flutter_window_title_bar_example`,
built on the Rust binding.

## Running

```bash
cd examples/gpui_window_title_bar_example
cargo run
TITLE_BAR_AUTOPLAY=1 cargo run   # walk through the states by itself
```

This crate is its own cargo workspace, not a member of the root one: GPUI is a
large dependency with its own platform requirements, and the root workspace's CI
builds every member. It enables GPUI's `runtime_shaders` feature, so building on
macOS does not need Xcode's Metal toolchain.

## Using it

The window opens with GPUI's default, standard title bar
(`TitlebarOptions { appears_transparent: false, .. }`); every change after that
goes through nativeapi, as in the Flutter example.

- **Normal** — the platform's standard title bar.
- **Content under title bar** — `set_content_under_title_bar(true)`: the bar keeps
  its window buttons and its height but stops drawing, and the content reaches
  the top edge behind them. macOS only; elsewhere the chip is greyed out because
  `Window::is_content_under_title_bar_supported()` says so.
- **Hidden** — `set_title_bar_style(TitleBarStyle::Hidden)`: no title bar and no
  window buttons.

Because Hidden takes the close button with it, the example draws a strip of its
own that is always there: drag it to move the window (`Window::start_dragging`
on mouse down, the Flutter example's `DragToMoveArea`), and **Quit** to end the
application. The strip starts clear of the macOS window buttons when they are
over the content.

The **Now** card reports `titleBarStyle`, `isContentUnderTitleBar`,
`isWindowControlButtonsVisible`, `isContentUnderTitleBarSupported()` and
`contentSize` (the names the Flutter example shows) after every change;
`contentSize` is what shows that switching states keeps the window's frame and
moves the title bar height into or out of the content. The **Window control
buttons** chips show the ordering rule: setting a style resets the buttons to
what it implies, so an override goes after it. The texts are the Flutter
example's.

`TITLE_BAR_AUTOPLAY=1` is an addition of this example (the Flutter one has no
autoplay): 3 s after start it goes content under title bar → hidden → hidden with
buttons → content under title bar → buttons hidden → normal, 2.5 s apart, printing
`STEP <name>` on stdout once each is applied, so the states can be looked at
without touching the mouse.

## How it works

| API | Role |
| --- | --- |
| `Window::set_title_bar_style` / `title_bar_style` | Normal / Hidden. |
| `Window::set_content_under_title_bar` / `is_content_under_title_bar` / `is_content_under_title_bar_supported` | Content under the title bar. |
| `Window::set_window_control_buttons_visible` / `is_window_control_buttons_visible` | The button override. |
| `Window::content_size` | The readout. |
| `Window::start_dragging` | Moving the window by the strip. |
| `nativeapi_gpui::WindowExt::native_window` | The nativeapi `Window` behind the GPUI window (the `NSWindow*` / `HWND`). |

### How GPUI follows the change (macOS)

GPUI's view is an autoresizing subview of the window's content view, and GPUI
takes its window size from that content view. nativeapi switches
`NSWindowStyleMaskFullSizeContentView` and keeps the window frame, so the content
view grows or shrinks by the title bar height and GPUI's view with it. GPUI turns
mouse positions into view coordinates from the content height, so hit testing
stays right. In short, GPUI's origin is always the content's top-left corner:
under a Normal title bar that is below the bar, with content under the title bar
or Hidden it is the window's top edge, behind the traffic lights. Nothing needs
to tell GPUI what happened — **provided the change reaches it**:

GPUI hears about the resize through a callback that updates the window through an
`AsyncApp`, and that fails while the app is already borrowed — in a click
handler, inside `Context::update`, in the `open_window` build closure. The resize
is then dropped: GPUI keeps its old viewport, lays the window out at the old
height and leaves a band as tall as the title bar at the bottom unpainted (black).
That is what the first version of this example did. So a title bar change runs
in a `cx.spawn` task, outside every `update`, with the native window in an `Rc`
(`change_title_bar` in `src/main.rs`); the view is updated afterwards.

GPUI's own title-bar state does not know about the change: it still believes the
title bar is standard. That has no visible effect here, but it is why the
example does not also use GPUI's `appears_transparent` / `traffic_light_position`,
which would fight nativeapi over the same `NSWindow` properties.

## Differences from the Flutter example

- `TITLE_BAR_AUTOPLAY` exists only here.
- The window is created by GPUI at 620 × 520 with a minimum of 520 × 420 through
  `WindowOptions`; GPUI makes the content one point taller than asked
  (`contentSize` reads 620 × 521 at start).
- Quit calls GPUI's `cx.quit()` instead of `Application::quit`.
- In the content-under-title-bar state the system may still move the window when
  the top band of the content is dragged (GPUI's view does not refuse
  `mouseDownCanMoveWindow`). Not checked, since the example was verified without
  mouse input.

## Platform notes

- macOS and Windows.
- Not Linux: nativeapi wraps a `GtkWindow*` there, and GPUI does not use GTK, so
  the example has no native window to work with.
- Verified on macOS (26) by screenshots during an autoplay run: the frame stays
  620 × 553, `contentSize` goes 521 → 553 → 521, and GPUI fills the whole content
  in every state with the strip at the top edge (inset past the traffic lights
  under the title bar). The strip drag and the chips were not clicked.
- Windows has not been built or run. There nativeapi subclasses GPUI's `HWND`
  and answers `WM_NCCALCSIZE` itself for Hidden, ahead of GPUI's own window
  procedure; GPUI reads its client size from `WM_SIZE`, so it should follow, but
  that is untested.
