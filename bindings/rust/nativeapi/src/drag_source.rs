// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

use crate::geometry::Point;
use crate::image::Image;
use crate::window::{Window, WindowId};

/// Identifies one registered event listener.
pub type ListenerId = cnativeapi::native_listener_id_t;

#[repr(i32)]
#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum DragOperation {
    None = 0,
    Copy = 1,
    Move = 2,
    Link = 3,
}

impl DragOperation {
    pub(crate) fn from_raw(raw: cnativeapi::native_drag_operation_t) -> Self {
        match raw {
            cnativeapi::NATIVE_DRAG_OPERATION_NONE => Self::None,
            cnativeapi::NATIVE_DRAG_OPERATION_COPY => Self::Copy,
            cnativeapi::NATIVE_DRAG_OPERATION_MOVE => Self::Move,
            cnativeapi::NATIVE_DRAG_OPERATION_LINK => Self::Link,
            _ => Self::None,
        }
    }

    pub(crate) fn to_raw(self) -> cnativeapi::native_drag_operation_t {
        self as cnativeapi::native_drag_operation_t
    }
}

/// One `DragSourceEvent`, in its concrete form.
#[derive(Debug, Clone, PartialEq)]
pub enum DragSourceEvent {
    Ended { window_id: WindowId, position: Point, operation: DragOperation },
}

impl DragSourceEvent {
    pub(crate) unsafe fn from_raw(raw: &cnativeapi::native_drag_source_event_t) -> Option<Self> {
        Some(match raw.type_ {
            cnativeapi::NATIVE_DRAG_SOURCE_EVENT_TYPE_ENDED => Self::Ended { window_id: raw.window_id, position: Point::from_raw(&raw.position), operation: DragOperation::from_raw(raw.data.ended.operation) },
            _ => return None,
        })
    }
}

/// Owned handle to a native `DragSource`.
#[derive(Debug)]
pub struct DragSource {
    handle: cnativeapi::native_drag_source_t,
}

impl DragSource {
    /// Adopts a handle returned by the C API.
    ///
    /// # Safety
    /// `handle` must be a live handle that is not owned elsewhere.
    pub unsafe fn from_raw(handle: cnativeapi::native_drag_source_t) -> Option<Self> {
        if handle == 0 {
            None
        } else {
            Some(Self { handle })
        }
    }

    /// Borrows the underlying C handle.
    pub fn as_raw(&self) -> cnativeapi::native_drag_source_t {
        self.handle
    }

    /// Creates a new `DragSource`; returns `None` if the native side failed.
    pub fn new() -> Option<Self> {
        unsafe {
            Self::from_raw(cnativeapi::native_drag_source_create())
        }
    }

    pub fn is_supported() -> bool {
        unsafe {
            cnativeapi::native_drag_source_is_supported()
        }
    }

    pub fn set_file_paths(&self, file_paths: &[String]) {
        let file_paths_owned: Vec<CString> = file_paths
            .iter()
            .map(|value| CString::new(value.as_str()).unwrap_or_default())
            .collect();
        let mut file_paths_ptrs: Vec<*mut std::os::raw::c_char> =
            file_paths_owned.iter().map(|value| value.as_ptr() as *mut _).collect();
        let file_paths_native = cnativeapi::native_string_list_t {
            items: file_paths_ptrs.as_mut_ptr(),
            count: file_paths_ptrs.len() as std::os::raw::c_long,
        };
        unsafe {
            cnativeapi::native_drag_source_set_file_paths(self.handle, file_paths_native);
        }
    }

    pub fn file_paths(&self) -> Vec<String> {
        unsafe {
            let mut list = cnativeapi::native_drag_source_get_file_paths(self.handle);
            let mut items = Vec::new();
            if !list.items.is_null() {
                for index in 0..list.count as isize {
                    let ptr = *list.items.offset(index);
                    if !ptr.is_null() {
                        items.push(CStr::from_ptr(ptr).to_string_lossy().into_owned());
                    }
                }
            }
            cnativeapi::native_string_list_free(&mut list);
            items
        }
    }

    pub fn set_text(&self, text: Option<&str>) {
        let text_native = text.map(|value| CString::new(value).expect("string argument contains interior nul byte"));
        unsafe {
            cnativeapi::native_drag_source_set_text(self.handle, text_native.as_ref().map_or(std::ptr::null(), |value| value.as_ptr()));
        }
    }

    pub fn text(&self) -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_drag_source_get_text(self.handle);
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn set_image(&self, image: Option<&Image>) {
        unsafe {
            cnativeapi::native_drag_source_set_image(self.handle, image.map_or(0, |value| value.as_raw()));
        }
    }

    pub fn image(&self) -> Option<Image> {
        unsafe {
            Image::from_raw(cnativeapi::native_drag_source_get_image(self.handle))
        }
    }

    pub fn set_drag_operation(&self, operation: DragOperation) {
        unsafe {
            cnativeapi::native_drag_source_set_drag_operation(self.handle, operation.to_raw());
        }
    }

    pub fn drag_operation(&self) -> DragOperation {
        unsafe {
            DragOperation::from_raw(cnativeapi::native_drag_source_get_drag_operation(self.handle))
        }
    }

    pub fn start_dragging(&self, window: Option<&Window>) -> bool {
        unsafe {
            cnativeapi::native_drag_source_start_dragging(self.handle, window.map_or(0, |value| value.as_raw()))
        }
    }

    pub fn is_dragging(&self) -> bool {
        unsafe {
            cnativeapi::native_drag_source_is_dragging(self.handle)
        }
    }

    /// Registers `callback` for every `DragSourceEvent` this `DragSource` emits.
    ///
    /// The closure is dropped on the main thread once the listener is removed
    /// or its emitter destroyed.
    pub fn add_listener(&self, callback: impl Fn(&DragSourceEvent) + 'static) -> ListenerId {
        unsafe extern "C" fn trampoline(event: *const cnativeapi::native_drag_source_event_t, user_data: *mut std::ffi::c_void) {
            if event.is_null() || user_data.is_null() {
                return;
            }
            let callback = &*(user_data as *const Box<dyn Fn(&DragSourceEvent)>);
            if let Some(event) = DragSourceEvent::from_raw(&*event) {
                callback(&event);
            }
        }
        let boxed: Box<Box<dyn Fn(&DragSourceEvent)>> = Box::new(Box::new(callback));
        let user_data = Box::into_raw(boxed) as *mut std::ffi::c_void;
        unsafe extern "C" fn release(user_data: *mut std::ffi::c_void) {
            drop(Box::from_raw(user_data as *mut Box<dyn Fn(&DragSourceEvent)>));
        }
        unsafe { cnativeapi::native_drag_source_add_listener(self.handle, Some(trampoline), user_data, Some(release)) }
    }

    /// Unregisters a listener. Returns false if unknown.
    pub fn remove_listener(&self, listener_id: ListenerId) -> bool {
        unsafe { cnativeapi::native_drag_source_remove_listener(self.handle, listener_id) }
    }

}

impl Drop for DragSource {
    fn drop(&mut self) {
        if self.handle != 0 {
            unsafe { cnativeapi::native_drag_source_free(self.handle) };
        }
    }
}

/// A `DragSource` owned elsewhere; using it does not release it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct DragSourceRef(cnativeapi::native_drag_source_t);

impl DragSourceRef {
    pub(crate) fn from_raw(handle: cnativeapi::native_drag_source_t) -> Self {
        Self(handle)
    }

    pub fn as_raw(&self) -> cnativeapi::native_drag_source_t {
        self.0
    }

    /// Runs `f` against the borrowed handle. The `DragSource` it receives
    /// must not outlive the call.
    pub fn with<R>(&self, f: impl FnOnce(&DragSource) -> R) -> R {
        let borrowed = std::mem::ManuallyDrop::new(DragSource { handle: self.0 });
        f(&borrowed)
    }
}

