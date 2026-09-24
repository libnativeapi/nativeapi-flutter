//! Detachable window example — a GPUI app whose panels can be torn out of the
//! main window into windows of their own and docked back, like dragging a tab
//! out of a browser.
//!
//! GPUI draws the windows and their content; nativeapi supplies what GPUI does
//! not: a drag that keeps following the mouse after its content moved to
//! another window (`WindowDragSession`), exact native geometry, hit testing
//! across windows, and opacity.
//!
//! Usage:
//!   cargo run   # in examples/gpui_detachable_window_example

mod detach;
mod native;
mod views;

use gpui::{
    px, size, App, AppContext, Application, Bounds, TitlebarOptions, WindowBounds, WindowOptions,
};

use crate::detach::Detach;
use crate::native::native_window_of;
use crate::views::{Inspector, MainView, Stopwatch};

fn main() {
    Application::new().run(|cx: &mut App| {
        let inspector = cx.new(|_| Inspector::new());
        let stopwatch = cx.new(|_| Stopwatch::default());
        let detach = cx.new(|cx| Detach::new(inspector.into(), stopwatch.into(), cx));

        let options = WindowOptions {
            window_bounds: Some(WindowBounds::Windowed(Bounds::centered(
                None,
                size(px(960.), px(640.)),
                cx,
            ))),
            titlebar: Some(TitlebarOptions {
                title: Some("Detachable Window".into()),
                ..Default::default()
            }),
            ..Default::default()
        };
        cx.open_window(options, |window, cx| {
            let native = native_window_of(window);
            detach.update(cx, |detach, _| detach.set_main_window(native));
            window.on_window_should_close(cx, |_, cx| {
                cx.quit();
                true
            });
            cx.new(|cx| MainView::new(detach.clone(), cx))
        })
        .expect("failed to open the main window");
        cx.activate(true);
    });
}
