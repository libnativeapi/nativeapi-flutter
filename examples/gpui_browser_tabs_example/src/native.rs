//! Geometry helpers between GPUI content coordinates and the screen.

use gpui::{Bounds, Pixels};
use nativeapi::geometry::{Point, Rectangle};
use nativeapi::window::Window as NativeWindow;

/// Offset of the content's top-left corner inside the window frame.
pub fn content_offset(window: &NativeWindow) -> Point {
    let frame = window.bounds();
    let content = window.content_bounds();
    Point {
        x: content.x - frame.x,
        y: content.y - frame.y,
    }
}

/// A rectangle in a window's content coordinates (as GPUI lays out elements),
/// moved to screen coordinates.
pub fn to_screen(window: &NativeWindow, rect: Bounds<Pixels>) -> Rectangle {
    let content = window.content_bounds();
    Rectangle {
        x: content.x + f64::from(rect.origin.x),
        y: content.y + f64::from(rect.origin.y),
        width: f64::from(rect.size.width),
        height: f64::from(rect.size.height),
    }
}

pub fn contains(rect: &Rectangle, point: &Point) -> bool {
    point.x >= rect.x
        && point.x < rect.x + rect.width
        && point.y >= rect.y
        && point.y < rect.y + rect.height
}
