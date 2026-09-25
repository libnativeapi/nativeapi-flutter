//! Browser tabs example — Chrome-style tabs across several GPUI windows:
//! reorder a tab within its strip, tear it off into a window of its own, merge
//! it into another window's strip, and move a window by its strip. Every tab's
//! page keeps its state wherever the tab goes.
//!
//! GPUI draws the windows and their content; nativeapi supplies what GPUI does
//! not: a drag that keeps following the mouse after its content moved to
//! another window (`WindowDragSession`), exact native geometry, and hit testing
//! across windows (`WindowManager::get_window_at_point`).
//!
//! Usage:
//!   cargo run   # in examples/gpui_browser_tabs_example

mod layout;
mod native;
mod page;
mod tabs;
mod views;

use gpui::{App, AppContext, Application};
use nativeapi::display_manager::DisplayManager;
use nativeapi::geometry::Rectangle;

use crate::tabs::{open_browser_window, Tabs, DEFAULT_WINDOW_SIZE};

fn main() {
    Application::new().run(|cx: &mut App| {
        let tabs = cx.new(Tabs::new);
        let (first, second) = tabs.update(cx, |tabs, cx| {
            let first: Vec<_> = (0..4).map(|_| tabs.create_tab(cx)).collect();
            let second: Vec<_> = (0..2).map(|_| tabs.create_tab(cx)).collect();
            (first, second)
        });
        let rects = side_by_side(2);
        open_browser_window(&tabs, first, &rects[0], cx);
        open_browser_window(&tabs, second, &rects[1], cx);
        cx.activate(true);
    });
}

/// Content rectangles for `count` windows spread across the primary display,
/// each a little lower than the one before.
fn side_by_side(count: usize) -> Vec<Rectangle> {
    let area = DisplayManager::get_primary()
        .map(|display| display.work_area())
        .unwrap_or(Rectangle {
            x: 0.0,
            y: 0.0,
            width: 1440.0,
            height: 900.0,
        });
    let (width, height) = DEFAULT_WINDOW_SIZE;
    let gaps = count.saturating_sub(1).max(1) as f64;
    let step = ((area.width - width) / gaps).clamp(0.0, width + 24.0);
    (0..count)
        .map(|i| Rectangle {
            x: area.x + (area.width - width - step * (count - 1) as f64) / 2.0 + step * i as f64,
            y: area.y + 80.0 + 60.0 * i as f64,
            width,
            height,
        })
        .collect()
}
