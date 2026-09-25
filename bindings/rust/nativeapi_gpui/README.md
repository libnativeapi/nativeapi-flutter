# nativeapi_gpui

[GPUI](https://www.gpui.rs) integration for [nativeapi](../nativeapi): GPUI
owns the windows and draws everything in them, nativeapi reaches the platform
window behind each one — for what GPUI does not offer (window shapes, visual
effects, title-bar styles, parent windows, a drag that follows the mouse
across windows, hit testing between windows, …).

| | macOS | Windows | Linux |
|:-:|:-:|:-:|:-:|
| | ✅ | ✅ | — |

On Linux nativeapi wraps a `GtkWindow*`, which GPUI does not use, so
`native_window()` returns `None` there.

## Usage

```toml
[dependencies]
nativeapi = "0.4.0"
nativeapi_gpui = "0.4.0"
gpui = "0.2.2"
```

```rust
use gpui::{prelude::*, App, Application, WindowOptions};
use nativeapi::window::VisualEffect;
use nativeapi_gpui::{defer_native, WindowExt};

Application::new().run(|cx: &mut App| {
    cx.open_window(WindowOptions::default(), |window, cx| {
        // The nativeapi Window behind this GPUI window; keep it.
        let native = window.native_window();
        // Not inside this closure: see "Native calls and GPUI updates".
        if let Some(native) = native {
            defer_native(cx, move || {
                native.set_visual_effect(VisualEffect::Hud);
            });
        }
        cx.new(|_| MyView)
    })
    .unwrap();
});
```

## What it provides

| API | |
| --- | --- |
| `WindowExt::native_window` | The nativeapi `Window` behind a `gpui::Window` (the `NSWindow*` on macOS, the `HWND` on Windows). Wrapping the same window twice gives the same id. |
| `defer_native(cx, f)` | Runs a native call once the current GPUI update is over. |
| `observe_window_events(cx, f)` | Delivers every `WindowEvent` to the entity `cx` belongs to, like GPUI's `cx.observe`. Returns a `NativeSubscription` that removes the listener when dropped (or `.detach()` it). |
| `observe_drag_session(&session, cx, f)` | The same for a `WindowDragSession`. |
| `ToNative` / `ToGpui` | `Point`, `Size`, `Bounds` / `Rectangle` and `Rgba` / `Hsla` / `Color` in both directions. |
| `DragToMoveArea` | An element that moves the window when dragged and maximizes / restores it on a double click (the counterpart of nativeapi_flutter's widget of the same name). |
| `DragToResizeArea` | Resize handles along the edges and corners of its content, with `resize_edge_size`, `resize_edge_color`, `resize_edge_margin` and `enabled_edges`. |

```rust
DragToResizeArea::new("resize")
    .resize_edge_size(px(6.))
    .child(
        div()
            .size_full()
            .child(DragToMoveArea::new("title-bar").h(px(40.)).child("My app"))
            .child(content),
    )
```

## Native calls and GPUI updates

Calls that move, resize, show or re-style a GPUI window (`set_bounds`,
`set_content_bounds`, `set_size`, `maximize`, `set_title_bar_style`, `show`,
…) make the platform report the change to GPUI synchronously. While an update
is running — inside an event handler, an `update` closure, or the
`open_window` build closure — GPUI cannot take that report and drops it, so the
content keeps its old size (a black band where the title bar was, a layout
that does not follow a resize). Make those calls through `defer_native`, or
from a task.

`start_dragging` and `start_resizing` track the mouse until the button is
released and move or resize the window meanwhile, so the same applies; the drag
areas already defer them.

nativeapi calls its event listeners from the platform event loop, with no GPUI
context and possibly in the middle of an update; `observe_window_events` and
`observe_drag_session` queue the events and hand them to the entity from a
GPUI task. They run inside an update of that entity: `cx.defer` the opening of
a window whose view reads the entity, since GPUI draws a new window once before
`open_window` returns.

## Building

This crate is not a member of the repository's root cargo workspace, and GPUI
is left to the app to configure: to build GPUI on macOS without Xcode's Metal
toolchain, enable its `runtime_shaders` feature in the app (the examples do).
The crate's own tests enable it, so `cargo test` and `cargo clippy
--all-targets` work in this directory.

## Examples

Every `gpui_*` example in [`examples/`](../../../examples) uses it; the drag
areas are shown in `gpui_window_drag_areas_example`.
