//! Shaped window example — a GPUI playground whose preview window takes one of
//! twelve silhouettes, clipped by nativeapi (`Window::set_shape`) and given a
//! contour shadow (`Window::set_custom_shadow`).
//!
//! GPUI draws both windows; nativeapi clips the preview to the polygon, casts
//! its shadow, hides its title bar and moves it when its handle is dragged.
//!
//! Usage:
//!   cargo run   # in examples/gpui_shaped_window_example

mod art;
mod geometry;
mod palette;
mod playground;
mod views;
mod widgets;

use gpui::{
    px, size, App, AppContext, Application, Bounds, TitlebarOptions, WindowBackgroundAppearance,
    WindowBounds, WindowOptions,
};

use crate::playground::{Playground, SMALL};
use crate::views::{ControlsView, PreviewView};
use nativeapi_gpui::WindowExt;

fn main() {
    Application::new().run(|cx: &mut App| {
        let playground = cx.new(|_| Playground::new());

        let main_options = WindowOptions {
            window_bounds: Some(WindowBounds::Windowed(Bounds::centered(
                None,
                size(px(480.), px(680.)),
                cx,
            ))),
            titlebar: Some(TitlebarOptions {
                title: Some("Window shapes".into()),
                ..Default::default()
            }),
            ..Default::default()
        };
        let mut main_native = None;
        cx.open_window(main_options, |window, cx| {
            main_native = window.native_window();
            window.on_window_should_close(cx, |_, cx| {
                // Closing the control window closes both.
                cx.quit();
                true
            });
            let playground = playground.clone();
            cx.new(|cx| ControlsView::new(playground, window, cx))
        })
        .expect("failed to open the control window");

        // No title bar and a clear background: the preview is nothing but its
        // painted content, which nativeapi then clips. It stays hidden until
        // its first contour is applied.
        let preview_options = WindowOptions {
            window_bounds: Some(WindowBounds::Windowed(Bounds::centered(
                None,
                size(px(SMALL as f32), px(SMALL as f32)),
                cx,
            ))),
            titlebar: None,
            window_background: WindowBackgroundAppearance::Transparent,
            is_resizable: false,
            is_minimizable: false,
            focus: false,
            show: false,
            ..Default::default()
        };
        let mut preview_native = None;
        cx.open_window(preview_options, |window, cx| {
            preview_native = window.native_window();
            let hide = playground.clone();
            window.on_window_should_close(cx, move |_, cx| {
                hide.update(cx, |p, cx| p.hide_preview(cx));
                false
            });
            let playground = playground.clone();
            cx.new(|cx| PreviewView::new(playground, cx))
        })
        .expect("failed to open the preview window");

        playground.update(cx, |p, _| p.set_windows(main_native, preview_native));
        // Outside this callback: configuring moves and resizes the windows,
        // which calls back into GPUI.
        let weak = playground.downgrade();
        cx.spawn(async move |cx| Playground::configure(weak, cx).await)
            .detach();
        cx.activate(true);
    });
}
