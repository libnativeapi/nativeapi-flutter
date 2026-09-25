//! The bridge between GPUI windows and nativeapi windows.

use gpui::{Bounds, Pixels};
use nativeapi::geometry::{Point, Rectangle};
use nativeapi::window::Window as NativeWindow;
use raw_window_handle::{HasWindowHandle, RawWindowHandle};

/// Wraps the platform window behind a GPUI window: the `NSWindow*` owning the
/// GPUI view on macOS, the `HWND` on Windows. `None` elsewhere — on Linux
/// nativeapi expects a `GtkWindow*`, which GPUI does not use.
pub fn native_window_of(window: &gpui::Window) -> Option<NativeWindow> {
    let handle = HasWindowHandle::window_handle(window).ok()?;
    match handle.as_raw() {
        #[cfg(target_os = "macos")]
        RawWindowHandle::AppKit(appkit) => {
            use objc2::runtime::AnyObject;
            let view = appkit.ns_view.as_ptr() as *mut AnyObject;
            let ns_window: *mut AnyObject = unsafe { objc2::msg_send![view, window] };
            if ns_window.is_null() {
                return None;
            }
            unsafe { NativeWindow::with_native_window(ns_window.cast()) }
        }
        #[cfg(target_os = "windows")]
        RawWindowHandle::Win32(win32) => unsafe {
            NativeWindow::with_native_window(win32.hwnd.get() as *mut std::ffi::c_void)
        },
        _ => None,
    }
}

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
