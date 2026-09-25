//! The bridge between GPUI windows and nativeapi windows.

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
