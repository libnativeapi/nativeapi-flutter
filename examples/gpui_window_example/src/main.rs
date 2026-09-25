//! Window example — a GPUI control panel for the nativeapi `Window` API,
//! the counterpart of `flutter_window_example`.
//!
//! GPUI draws the panel; nativeapi does everything it shows: it lists the
//! app's windows and the displays (`WindowManager`, `DisplayManager`), draws
//! them to scale on a canvas, and drives the selected window — visibility,
//! state, focus, geometry and size constraints, title bar, shadow, opacity,
//! always-on-top, visual effects, background color, the style flags, dragging
//! and resizing, and the title — while the Events tab logs every
//! `WindowEvent`.
//!
//! Usage:
//!   cargo run   # in examples/gpui_window_example

mod actions;
mod canvas;
mod example;
mod native;
mod ui;

use gpui::{
    px, size, App, AppContext, Application, Bounds, TitlebarOptions, WindowBounds, WindowOptions,
};

use crate::example::WindowExample;
use crate::native::native_window_of;

fn main() {
    Application::new().run(|cx: &mut App| {
        let options = WindowOptions {
            window_bounds: Some(WindowBounds::Windowed(Bounds::centered(
                None,
                size(px(960.), px(720.)),
                cx,
            ))),
            titlebar: Some(TitlebarOptions {
                title: Some("Window Example".into()),
                ..Default::default()
            }),
            ..Default::default()
        };
        cx.open_window(options, |window, cx| {
            let native = native_window_of(window);
            window.on_window_should_close(cx, |_, cx| {
                cx.quit();
                true
            });
            cx.new(|cx| WindowExample::new(native, cx))
        })
        .expect("failed to open the main window");
        cx.activate(true);
    });
}
