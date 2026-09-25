//! Floating toolbar example — a second GPUI window, transparent, frameless and
//! without a shadow, that belongs to the main window and stays centred above
//! it while the main window is moved, resized, minimized and restored.
//!
//! The GPUI counterpart of `flutter_floating_toolbar_example`. GPUI draws both
//! windows; nativeapi dresses the toolbar window (title bar, background,
//! shadow, …), makes it a child of the main window and reports the main
//! window's moves.
//!
//! Usage:
//!   cargo run   # in examples/gpui_floating_toolbar_example

mod toolbar;
mod views;

use gpui::{
    point, px, size, App, AppContext, Application, Bounds, TitlebarOptions,
    WindowBackgroundAppearance, WindowBounds, WindowOptions,
};
use nativeapi::display_manager::DisplayManager;

use crate::toolbar::{Toolbar, GAP, MAIN_SIZE, TOOLBAR_SIZE};
use crate::views::{MainView, ToolbarView};
use nativeapi_gpui::WindowExt;

fn main() {
    Application::new().run(|cx: &mut App| {
        let model = cx.new(Toolbar::new);

        // Leave room above the main window for the toolbar: centred on the
        // primary display's work area, 120 px below its top.
        let (main_x, main_y) = match DisplayManager::get_primary() {
            Some(display) => {
                let area = display.work_area();
                (area.x + (area.width - MAIN_SIZE.0) / 2.0, area.y + 120.0)
            }
            None => (200.0, 200.0),
        };

        let main_options = WindowOptions {
            window_bounds: Some(WindowBounds::Windowed(Bounds::new(
                point(px(main_x as f32), px(main_y as f32)),
                size(px(MAIN_SIZE.0 as f32), px(MAIN_SIZE.1 as f32)),
            ))),
            titlebar: Some(TitlebarOptions {
                title: Some("Floating toolbar".into()),
                ..Default::default()
            }),
            window_min_size: Some(size(px(480.), px(360.))),
            ..Default::default()
        };
        let mut main_native = None;
        cx.open_window(main_options, |window, cx| {
            main_native = window.native_window();
            // Closing the main window closes the toolbar first, then itself.
            let closing = model.clone();
            window.on_window_should_close(cx, move |_, cx| {
                closing.update(cx, |model, cx| model.close_everything(cx));
                cx.quit();
                true
            });
            cx.new(|cx| MainView::new(model.clone(), cx))
        })
        .expect("failed to open the main window");

        // Opened hidden where it will sit; nativeapi dresses it and shows it.
        let toolbar_options = WindowOptions {
            window_bounds: Some(WindowBounds::Windowed(Bounds::new(
                point(
                    px((main_x + (MAIN_SIZE.0 - TOOLBAR_SIZE.0) / 2.0) as f32),
                    px((main_y - TOOLBAR_SIZE.1 - GAP) as f32),
                ),
                size(px(TOOLBAR_SIZE.0 as f32), px(TOOLBAR_SIZE.1 as f32)),
            ))),
            titlebar: Some(TitlebarOptions {
                title: Some("Toolbar".into()),
                appears_transparent: true,
                traffic_light_position: None,
            }),
            window_background: WindowBackgroundAppearance::Transparent,
            focus: false,
            // Shown by nativeapi once dressed; by GPUI where nativeapi cannot
            // reach its windows.
            show: !cfg!(any(target_os = "macos", target_os = "windows")),
            is_movable: false,
            is_resizable: false,
            is_minimizable: false,
            ..Default::default()
        };
        let mut toolbar_native = None;
        let toolbar_handle = cx
            .open_window(toolbar_options, |window, cx| {
                toolbar_native = window.native_window();
                // The toolbar has no close button; closing the main window closes it.
                window.on_window_should_close(cx, |_, _| false);
                cx.new(|cx| ToolbarView::new(model.clone(), cx))
            })
            .expect("failed to open the toolbar window");

        model.update(cx, |model, cx| {
            model.set_windows(main_native, toolbar_native, toolbar_handle.into(), cx)
        });
        cx.activate(true);
    });
}
