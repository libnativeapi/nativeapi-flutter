//! GPUI integration for [nativeapi](https://github.com/libnativeapi/nativeapi).
//!
//! GPUI owns its windows and draws everything in them; nativeapi reaches the
//! platform window behind each one. This crate covers what every GPUI app
//! using nativeapi needs:
//!
//! - [`WindowExt::native_window`] — the nativeapi [`Window`](nativeapi::window::Window)
//!   behind a [`gpui::Window`].
//! - [`defer_native`] — run a native call once the current GPUI update is over.
//!   Calls that move, resize or re-style a window make the platform call back
//!   into GPUI right away, and GPUI drops those callbacks while an update is
//!   running (inside an event handler, an `update` closure, or the
//!   `open_window` build closure): the content would not follow the new size.
//! - [`observe_window_events`] / [`observe_drag_session`] — deliver nativeapi
//!   events to a GPUI entity, with a context to act in.
//! - [`ToNative`] / [`ToGpui`] — geometry and color conversions.
//! - [`DragToMoveArea`] / [`DragToResizeArea`] — elements that move or resize
//!   the window, like `nativeapi_flutter`'s widgets of the same names.
//!
//! Supported on macOS and Windows. On Linux nativeapi wraps a `GtkWindow*`,
//! which GPUI does not use, so [`WindowExt::native_window`] returns `None`.

mod conversions;
mod drag_to_move_area;
mod drag_to_resize_area;
mod events;
mod window;

pub use conversions::{ToGpui, ToNative};
pub use drag_to_move_area::DragToMoveArea;
pub use drag_to_resize_area::DragToResizeArea;
pub use events::{observe_drag_session, observe_window_events, NativeSubscription};
pub use window::{defer_native, WindowExt};
