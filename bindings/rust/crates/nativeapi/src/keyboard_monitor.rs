// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

use crate::keyboard::KeyboardEvent;

/// Identifies one registered event listener.
pub type ListenerId = cnativeapi::native_listener_id_t;

/// Owned handle to a native `KeyboardMonitor`.
#[derive(Debug)]
pub struct KeyboardMonitor {
    handle: cnativeapi::native_keyboard_monitor_t,
}

impl KeyboardMonitor {
    /// Adopts a handle returned by the C API.
    ///
    /// # Safety
    /// `handle` must be a live handle that is not owned elsewhere.
    pub unsafe fn from_raw(handle: cnativeapi::native_keyboard_monitor_t) -> Option<Self> {
        if handle == 0 {
            None
        } else {
            Some(Self { handle })
        }
    }

    /// Borrows the underlying C handle.
    pub fn as_raw(&self) -> cnativeapi::native_keyboard_monitor_t {
        self.handle
    }

    /// Creates a new `KeyboardMonitor`; returns `None` if the native side failed.
    pub fn new() -> Option<Self> {
        unsafe {
            Self::from_raw(cnativeapi::native_keyboard_monitor_create())
        }
    }

    pub fn start(&self) {
        unsafe {
            cnativeapi::native_keyboard_monitor_start(self.handle);
        }
    }

    pub fn stop(&self) {
        unsafe {
            cnativeapi::native_keyboard_monitor_stop(self.handle);
        }
    }

    pub fn is_monitoring(&self) -> bool {
        unsafe {
            cnativeapi::native_keyboard_monitor_is_monitoring(self.handle)
        }
    }

    /// Registers `callback` for every `KeyboardEvent` this `KeyboardMonitor` emits.
    ///
    /// The closure is leaked: the C ABI takes a `user_data` pointer but
    /// offers no hook to reclaim it, so removing the listener stops the
    /// calls without freeing the closure.
    pub fn add_listener(&self, callback: impl Fn(&KeyboardEvent) + 'static) -> ListenerId {
        unsafe extern "C" fn trampoline(event: *const cnativeapi::native_keyboard_event_t, user_data: *mut std::ffi::c_void) {
            if event.is_null() || user_data.is_null() {
                return;
            }
            let callback = &*(user_data as *const Box<dyn Fn(&KeyboardEvent)>);
            if let Some(event) = KeyboardEvent::from_raw(&*event) {
                callback(&event);
            }
        }
        let boxed: Box<Box<dyn Fn(&KeyboardEvent)>> = Box::new(Box::new(callback));
        let user_data = Box::into_raw(boxed) as *mut std::ffi::c_void;
        unsafe { cnativeapi::native_keyboard_monitor_add_listener(self.handle, Some(trampoline), user_data) }
    }

    /// Unregisters a listener. Returns false if unknown.
    pub fn remove_listener(&self, listener_id: ListenerId) -> bool {
        unsafe { cnativeapi::native_keyboard_monitor_remove_listener(self.handle, listener_id) }
    }

}

impl Drop for KeyboardMonitor {
    fn drop(&mut self) {
        if self.handle != 0 {
            unsafe { cnativeapi::native_keyboard_monitor_free(self.handle) };
        }
    }
}

/// A `KeyboardMonitor` owned elsewhere; using it does not release it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct KeyboardMonitorRef(cnativeapi::native_keyboard_monitor_t);

impl KeyboardMonitorRef {
    pub(crate) fn from_raw(handle: cnativeapi::native_keyboard_monitor_t) -> Self {
        Self(handle)
    }

    pub fn as_raw(&self) -> cnativeapi::native_keyboard_monitor_t {
        self.0
    }

    /// Runs `f` against the borrowed handle. The `KeyboardMonitor` it receives
    /// must not outlive the call.
    pub fn with<R>(&self, f: impl FnOnce(&KeyboardMonitor) -> R) -> R {
        let borrowed = std::mem::ManuallyDrop::new(KeyboardMonitor { handle: self.0 });
        f(&borrowed)
    }
}

