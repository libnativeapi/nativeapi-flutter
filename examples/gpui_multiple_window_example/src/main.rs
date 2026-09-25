//! Multiple window example — three GPUI windows laid out on the primary
//! display by nativeapi: a will-show hook catches each window just before it
//! is shown, sizes and positions it against the display's work area, and then
//! lets the show through with `call_original_show`.
//!
//! The windows are opened hidden and shown with nativeapi's `Window::show`:
//! GPUI's own show (inside `open_window`) is caught by the hook too, but GPUI
//! moves the window back to its requested origin right after it, so only the
//! size would stick. See the README.
//!
//! Usage:
//!   cargo run   # in examples/gpui_multiple_window_example

mod native;

use gpui::prelude::*;
use gpui::{
    div, px, rgb, size, App, Application, Bounds, SharedString, TitlebarOptions, Window,
    WindowBounds, WindowOptions,
};
use nativeapi::display::Display;
use nativeapi::display_manager::DisplayManager;
use nativeapi::geometry::{Point, Size};
use nativeapi::window::Window as NativeWindow;
use nativeapi::window_manager::WindowManager;

use crate::native::native_window_of;

const PRIMARY: &str = "Primary Window";
const SECONDARY: &str = "Secondary Window";
const TERTIARY: &str = "Tertiary Window";

// Material 3 baseline colours, as the Flutter example's default theme uses.
const SURFACE: u32 = 0xfef7ff;
const ON_SURFACE: u32 = 0x1d1b20;
const PRIMARY_COLOR: u32 = 0x6750a4;
const ON_PRIMARY: u32 = 0xffffff;

fn main() {
    Application::new().run(|cx: &mut App| {
        let primary_display = DisplayManager::get_primary();
        WindowManager::set_will_show_hook(Some(Box::new(move |window_id| {
            let window = WindowManager::get(window_id);
            if let (Some(window), Some(display)) = (&window, &primary_display) {
                match window.title().as_deref() {
                    // Top row, centred, full width (60% of the work area).
                    Some(PRIMARY) => place(window, display, Slot::Top),
                    // Bottom left (half of 60% of the work area).
                    Some(SECONDARY) => place(window, display, Slot::BottomLeft),
                    // Bottom right (half of 60% of the work area).
                    Some(TERTIARY) => place(window, display, Slot::BottomRight),
                    _ => {}
                }
            }
            // A will-show hook replaces the show: nothing appears until it says so.
            WindowManager::call_original_show(window_id);
        })));
        WindowManager::set_will_hide_hook(Some(Box::new(|window_id| {
            println!("[Rust] will hide hook {window_id}");
            // Unlike the Flutter example, let the hide through: a will-hide
            // hook replaces the hide just like the show.
            WindowManager::call_original_hide(window_id);
        })));

        // Closing the last window quits.
        cx.on_window_closed(|cx| {
            if cx.windows().is_empty() {
                cx.quit();
            }
        })
        .detach();

        // The same order as the Flutter example's ViewCollection.
        let mut windows = Vec::new();
        for title in [TERTIARY, SECONDARY, PRIMARY] {
            let options = WindowOptions {
                window_bounds: Some(WindowBounds::Windowed(Bounds::centered(
                    None,
                    size(px(800.), px(600.)),
                    cx,
                ))),
                titlebar: Some(TitlebarOptions {
                    title: Some(title.into()),
                    ..Default::default()
                }),
                // Shown below through nativeapi, where the hook's layout sticks.
                show: false,
                ..Default::default()
            };
            let mut native = None;
            let opened = cx.open_window(options, |window, cx| {
                native = native_window_of(window);
                cx.new(|_| PageView { title })
            });
            if opened.is_ok() {
                windows.extend(native);
            }
        }

        // Outside the current update: showing resizes the window, and GPUI
        // only hears about that when no update is running.
        cx.spawn(async move |_| {
            for window in &windows {
                window.show();
            }
        })
        .detach();
        cx.activate(true);
    });
}

enum Slot {
    Top,
    BottomLeft,
    BottomRight,
}

/// Lays the three windows out as one block covering 60% of the work area,
/// centred: one window across the top half, two side by side below.
fn place(window: &NativeWindow, display: &Display, slot: Slot) {
    let work_area = display.work_area();
    let total_width = work_area.width * 0.6;
    let total_height = work_area.height * 0.6;
    let start_x = work_area.x + (work_area.width - total_width) / 2.0;
    let start_y = work_area.y + (work_area.height - total_height) / 2.0;
    let row_height = total_height * 0.5;
    let half_width = total_width * 0.5;

    let (x, y, width) = match slot {
        Slot::Top => (start_x, start_y, total_width),
        Slot::BottomLeft => (start_x, start_y + row_height, half_width),
        Slot::BottomRight => (start_x + half_width, start_y + row_height, half_width),
    };
    window.set_size(
        &Size {
            width,
            height: row_height,
        },
        false,
    );
    window.set_position(&Point { x, y });
}

/// One window's content: an app bar with its title, and a body.
struct PageView {
    title: &'static str,
}

impl Render for PageView {
    fn render(&mut self, _: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        // Like the Flutter bodies: the primary window's button sits at the
        // top of a centred column, the other windows centre their title.
        let body = div().flex_1().flex().flex_col().items_center();
        let body = if self.title == PRIMARY {
            body.child(
                div()
                    .id("a-window")
                    .px_6()
                    .py_2p5()
                    .rounded_full()
                    .bg(rgb(PRIMARY_COLOR))
                    .text_color(rgb(ON_PRIMARY))
                    .text_sm()
                    .cursor_pointer()
                    .hover(|this| this.opacity(0.9))
                    .child("A Window")
                    .on_click(cx.listener(|_, _, _, cx| {
                        // Outside the click's update: see the show in main().
                        cx.spawn(async move |_, _| resize_and_show_primary())
                            .detach();
                    })),
            )
        } else {
            body.justify_center().child(SharedString::from(self.title))
        };
        div()
            .size_full()
            .flex()
            .flex_col()
            .bg(rgb(SURFACE))
            .text_color(rgb(ON_SURFACE))
            .child(
                div()
                    .h(px(64.))
                    .flex_none()
                    .flex()
                    .items_center()
                    .px_4()
                    .text_xl()
                    .child(self.title),
            )
            .child(body)
    }
}

/// What the Flutter example's button does: finds the primary window by its
/// title, makes it 1000 × 1000 and shows it — and the will-show hook puts it
/// straight back into its slot.
fn resize_and_show_primary() {
    let primary = WindowManager::get_all()
        .into_iter()
        .find(|window| window.title().as_deref() == Some(PRIMARY));
    if let Some(primary) = primary {
        primary.set_size(
            &Size {
                width: 1000.0,
                height: 1000.0,
            },
            false,
        );
        primary.show();
    }
}
