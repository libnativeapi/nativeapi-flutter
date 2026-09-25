use gpui::App;
use nativeapi::window::Window as NativeWindow;
use raw_window_handle::{HasWindowHandle, RawWindowHandle};

/// Access to the platform window behind a GPUI window.
pub trait WindowExt {
    /// Wraps the platform window behind this GPUI window: the `NSWindow*`
    /// owning the GPUI view on macOS, the `HWND` on Windows. `None` on other
    /// platforms (nativeapi expects a `GtkWindow*` on Linux, which GPUI does
    /// not use) or when the window has no platform handle.
    ///
    /// Wrapping the same window again yields the same
    /// [`id`](NativeWindow::id); keep the result rather than calling this
    /// on every frame.
    fn native_window(&self) -> Option<NativeWindow>;
}

impl WindowExt for gpui::Window {
    fn native_window(&self) -> Option<NativeWindow> {
        let handle = HasWindowHandle::window_handle(self).ok()?;
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
}

/// Runs `f` once the current GPUI update is over.
///
/// Use it for every native call that moves, resizes, shows or re-styles a GPUI
/// window (`set_bounds`, `set_content_bounds`, `set_size`, `maximize`,
/// `set_title_bar_style`, `show`, …) and for the calls that track the mouse
/// (`start_dragging`, `start_resizing`). The platform reports the change to
/// GPUI synchronously, and while an update is running — inside an event
/// handler, an `update` closure or the `open_window` build closure — GPUI
/// cannot take the report and drops it, so the content keeps its old size.
pub fn defer_native(cx: &App, f: impl FnOnce() + 'static) {
    cx.spawn(async move |_| f()).detach();
}
