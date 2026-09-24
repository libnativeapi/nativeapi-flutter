// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

use crate::drag_source::DragOperation;
use crate::geometry::Point;
use crate::window::{Window, WindowId};

/// Identifies one registered event listener.
pub type ListenerId = cnativeapi::native_listener_id_t;

/// One `DropTargetEvent`, in its concrete form.
#[derive(Debug, Clone, PartialEq)]
pub enum DropTargetEvent {
    Entered { window_id: WindowId, position: Point },
    Moved { window_id: WindowId, position: Point },
    Exited { window_id: WindowId, position: Point },
    Dropped { window_id: WindowId, position: Point, file_paths: Vec<String>, text: Option<String> },
}

impl DropTargetEvent {
    pub(crate) unsafe fn from_raw(raw: &cnativeapi::native_drop_target_event_t) -> Option<Self> {
        Some(match raw.type_ {
            cnativeapi::NATIVE_DROP_TARGET_EVENT_TYPE_ENTERED => Self::Entered { window_id: raw.window_id, position: Point::from_raw(&raw.position) },
            cnativeapi::NATIVE_DROP_TARGET_EVENT_TYPE_MOVED => Self::Moved { window_id: raw.window_id, position: Point::from_raw(&raw.position) },
            cnativeapi::NATIVE_DROP_TARGET_EVENT_TYPE_EXITED => Self::Exited { window_id: raw.window_id, position: Point::from_raw(&raw.position) },
            cnativeapi::NATIVE_DROP_TARGET_EVENT_TYPE_DROPPED => Self::Dropped { window_id: raw.window_id, position: Point::from_raw(&raw.position), file_paths: if raw.data.dropped.file_paths.items.is_null() { Vec::new() } else { (0..raw.data.dropped.file_paths.count as usize).filter_map(|index| { let ptr = *raw.data.dropped.file_paths.items.add(index); if ptr.is_null() { None } else { Some(CStr::from_ptr(ptr).to_string_lossy().into_owned()) } }).collect() }, text: if raw.data.dropped.text.is_null() { None } else { Some(CStr::from_ptr(raw.data.dropped.text).to_string_lossy().into_owned()) } },
            _ => return None,
        })
    }
}

/// Owned handle to a native `DropTarget`.
#[derive(Debug)]
pub struct DropTarget {
    handle: cnativeapi::native_drop_target_t,
}

impl DropTarget {
    /// Adopts a handle returned by the C API.
    ///
    /// # Safety
    /// `handle` must be a live handle that is not owned elsewhere.
    pub unsafe fn from_raw(handle: cnativeapi::native_drop_target_t) -> Option<Self> {
        if handle == 0 {
            None
        } else {
            Some(Self { handle })
        }
    }

    /// Borrows the underlying C handle.
    pub fn as_raw(&self) -> cnativeapi::native_drop_target_t {
        self.handle
    }

    /// Creates a new `DropTarget`; returns `None` if the native side failed.
    pub fn new(window: Option<&Window>) -> Option<Self> {
        unsafe {
            Self::from_raw(cnativeapi::native_drop_target_create(window.map_or(0, |value| value.as_raw())))
        }
    }

    pub fn is_supported() -> bool {
        unsafe {
            cnativeapi::native_drop_target_is_supported()
        }
    }

    pub fn window_id(&self) -> WindowId {
        unsafe {
            cnativeapi::native_drop_target_get_window_id(self.handle)
        }
    }

    pub fn set_drop_operation(&self, operation: DragOperation) {
        unsafe {
            cnativeapi::native_drop_target_set_drop_operation(self.handle, operation.to_raw());
        }
    }

    pub fn drop_operation(&self) -> DragOperation {
        unsafe {
            DragOperation::from_raw(cnativeapi::native_drop_target_get_drop_operation(self.handle))
        }
    }

    pub fn is_active(&self) -> bool {
        unsafe {
            cnativeapi::native_drop_target_is_active(self.handle)
        }
    }

    /// Registers `callback` for every `DropTargetEvent` this `DropTarget` emits.
    ///
    /// The closure is leaked: the C ABI takes a `user_data` pointer but
    /// offers no hook to reclaim it, so removing the listener stops the
    /// calls without freeing the closure.
    pub fn add_listener(&self, callback: impl Fn(&DropTargetEvent) + 'static) -> ListenerId {
        unsafe extern "C" fn trampoline(event: *const cnativeapi::native_drop_target_event_t, user_data: *mut std::ffi::c_void) {
            if event.is_null() || user_data.is_null() {
                return;
            }
            let callback = &*(user_data as *const Box<dyn Fn(&DropTargetEvent)>);
            if let Some(event) = DropTargetEvent::from_raw(&*event) {
                callback(&event);
            }
        }
        let boxed: Box<Box<dyn Fn(&DropTargetEvent)>> = Box::new(Box::new(callback));
        let user_data = Box::into_raw(boxed) as *mut std::ffi::c_void;
        unsafe { cnativeapi::native_drop_target_add_listener(self.handle, Some(trampoline), user_data) }
    }

    /// Unregisters a listener. Returns false if unknown.
    pub fn remove_listener(&self, listener_id: ListenerId) -> bool {
        unsafe { cnativeapi::native_drop_target_remove_listener(self.handle, listener_id) }
    }

}

impl Drop for DropTarget {
    fn drop(&mut self) {
        if self.handle != 0 {
            unsafe { cnativeapi::native_drop_target_free(self.handle) };
        }
    }
}

/// A `DropTarget` owned elsewhere; using it does not release it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct DropTargetRef(cnativeapi::native_drop_target_t);

impl DropTargetRef {
    pub(crate) fn from_raw(handle: cnativeapi::native_drop_target_t) -> Self {
        Self(handle)
    }

    pub fn as_raw(&self) -> cnativeapi::native_drop_target_t {
        self.0
    }

    /// Runs `f` against the borrowed handle. The `DropTarget` it receives
    /// must not outlive the call.
    pub fn with<R>(&self, f: impl FnOnce(&DropTarget) -> R) -> R {
        let borrowed = std::mem::ManuallyDrop::new(DropTarget { handle: self.0 });
        f(&borrowed)
    }
}

