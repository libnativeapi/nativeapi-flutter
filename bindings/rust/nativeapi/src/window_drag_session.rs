// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

use crate::geometry::Point;
use crate::window::{Window, WindowId};

/// Identifies one registered event listener.
pub type ListenerId = cnativeapi::native_listener_id_t;

/// One `WindowDragEvent`, in its concrete form.
#[derive(Debug, Clone, PartialEq)]
pub enum WindowDragEvent {
    Moved { window_id: WindowId, cursor_position: Point },
    Ended { window_id: WindowId, cursor_position: Point },
    Cancelled { window_id: WindowId, cursor_position: Point },
}

impl WindowDragEvent {
    pub(crate) unsafe fn from_raw(raw: &cnativeapi::native_window_drag_event_t) -> Option<Self> {
        Some(match raw.type_ {
            cnativeapi::NATIVE_WINDOW_DRAG_EVENT_TYPE_MOVED => Self::Moved { window_id: raw.window_id, cursor_position: Point::from_raw(&raw.cursor_position) },
            cnativeapi::NATIVE_WINDOW_DRAG_EVENT_TYPE_ENDED => Self::Ended { window_id: raw.window_id, cursor_position: Point::from_raw(&raw.cursor_position) },
            cnativeapi::NATIVE_WINDOW_DRAG_EVENT_TYPE_CANCELLED => Self::Cancelled { window_id: raw.window_id, cursor_position: Point::from_raw(&raw.cursor_position) },
            _ => return None,
        })
    }
}

/// Owned handle to a native `WindowDragSession`.
#[derive(Debug)]
pub struct WindowDragSession {
    handle: cnativeapi::native_window_drag_session_t,
}

impl WindowDragSession {
    /// Adopts a handle returned by the C API.
    ///
    /// # Safety
    /// `handle` must be a live handle that is not owned elsewhere.
    pub unsafe fn from_raw(handle: cnativeapi::native_window_drag_session_t) -> Option<Self> {
        if handle == 0 {
            None
        } else {
            Some(Self { handle })
        }
    }

    /// Borrows the underlying C handle.
    pub fn as_raw(&self) -> cnativeapi::native_window_drag_session_t {
        self.handle
    }

    /// Creates a new `WindowDragSession`; returns `None` if the native side failed.
    pub fn new() -> Option<Self> {
        unsafe {
            Self::from_raw(cnativeapi::native_window_drag_session_create())
        }
    }

    pub fn start(&self, window: Option<&Window>, anchor: &Point) -> bool {
        let anchor_raw = anchor.to_raw();
        unsafe {
            cnativeapi::native_window_drag_session_start(self.handle, window.map_or(0, |value| value.as_raw()), anchor_raw.raw)
        }
    }

    pub fn cancel(&self) {
        unsafe {
            cnativeapi::native_window_drag_session_cancel(self.handle);
        }
    }

    pub fn is_active(&self) -> bool {
        unsafe {
            cnativeapi::native_window_drag_session_is_active(self.handle)
        }
    }

    pub fn window_id(&self) -> WindowId {
        unsafe {
            cnativeapi::native_window_drag_session_get_window_id(self.handle)
        }
    }

    pub fn anchor(&self) -> Point {
        unsafe {
            let raw = cnativeapi::native_window_drag_session_get_anchor(self.handle);
            Point::from_raw(&raw)
        }
    }

    /// Registers `callback` for every `WindowDragEvent` this `WindowDragSession` emits.
    ///
    /// The closure is dropped on the main thread once the listener is removed
    /// or its emitter destroyed.
    pub fn add_listener(&self, callback: impl Fn(&WindowDragEvent) + 'static) -> ListenerId {
        unsafe extern "C" fn trampoline(event: *const cnativeapi::native_window_drag_event_t, user_data: *mut std::ffi::c_void) {
            if event.is_null() || user_data.is_null() {
                return;
            }
            let callback = &*(user_data as *const Box<dyn Fn(&WindowDragEvent)>);
            if let Some(event) = WindowDragEvent::from_raw(&*event) {
                callback(&event);
            }
        }
        let boxed: Box<Box<dyn Fn(&WindowDragEvent)>> = Box::new(Box::new(callback));
        let user_data = Box::into_raw(boxed) as *mut std::ffi::c_void;
        unsafe extern "C" fn release(user_data: *mut std::ffi::c_void) {
            drop(Box::from_raw(user_data as *mut Box<dyn Fn(&WindowDragEvent)>));
        }
        unsafe { cnativeapi::native_window_drag_session_add_listener(self.handle, Some(trampoline), user_data, Some(release)) }
    }

    /// Unregisters a listener. Returns false if unknown.
    pub fn remove_listener(&self, listener_id: ListenerId) -> bool {
        unsafe { cnativeapi::native_window_drag_session_remove_listener(self.handle, listener_id) }
    }

}

impl Drop for WindowDragSession {
    fn drop(&mut self) {
        if self.handle != 0 {
            unsafe { cnativeapi::native_window_drag_session_free(self.handle) };
        }
    }
}

/// A `WindowDragSession` owned elsewhere; using it does not release it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct WindowDragSessionRef(cnativeapi::native_window_drag_session_t);

impl WindowDragSessionRef {
    pub(crate) fn from_raw(handle: cnativeapi::native_window_drag_session_t) -> Self {
        Self(handle)
    }

    pub fn as_raw(&self) -> cnativeapi::native_window_drag_session_t {
        self.0
    }

    /// Runs `f` against the borrowed handle. The `WindowDragSession` it receives
    /// must not outlive the call.
    pub fn with<R>(&self, f: impl FnOnce(&WindowDragSession) -> R) -> R {
        let borrowed = std::mem::ManuallyDrop::new(WindowDragSession { handle: self.0 });
        f(&borrowed)
    }
}

