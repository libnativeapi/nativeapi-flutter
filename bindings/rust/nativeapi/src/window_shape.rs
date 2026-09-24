// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

use crate::geometry::Point;

/// Owned handle to a native `WindowShape`.
#[derive(Debug)]
pub struct WindowShape {
    handle: cnativeapi::native_window_shape_t,
}

impl WindowShape {
    /// Adopts a handle returned by the C API.
    ///
    /// # Safety
    /// `handle` must be a live handle that is not owned elsewhere.
    pub unsafe fn from_raw(handle: cnativeapi::native_window_shape_t) -> Option<Self> {
        if handle == 0 {
            None
        } else {
            Some(Self { handle })
        }
    }

    /// Borrows the underlying C handle.
    pub fn as_raw(&self) -> cnativeapi::native_window_shape_t {
        self.handle
    }

    /// Creates a new `WindowShape`; returns `None` if the native side failed.
    pub fn new() -> Option<Self> {
        unsafe {
            Self::from_raw(cnativeapi::native_window_shape_create())
        }
    }

    pub fn add_point(&self, point: &Point) -> bool {
        let point_raw = point.to_raw();
        unsafe {
            cnativeapi::native_window_shape_add_point(self.handle, point_raw.raw)
        }
    }

    pub fn clear(&self) {
        unsafe {
            cnativeapi::native_window_shape_clear(self.handle);
        }
    }

    pub fn point_count(&self) -> std::os::raw::c_ulong {
        unsafe {
            cnativeapi::native_window_shape_get_point_count(self.handle)
        }
    }

    pub fn get_point_at(&self, index: std::os::raw::c_ulong) -> Point {
        unsafe {
            let raw = cnativeapi::native_window_shape_get_point_at(self.handle, index);
            Point::from_raw(&raw)
        }
    }

}

impl Drop for WindowShape {
    fn drop(&mut self) {
        if self.handle != 0 {
            unsafe { cnativeapi::native_window_shape_free(self.handle) };
        }
    }
}

/// A `WindowShape` owned elsewhere; using it does not release it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct WindowShapeRef(cnativeapi::native_window_shape_t);

impl WindowShapeRef {
    pub(crate) fn from_raw(handle: cnativeapi::native_window_shape_t) -> Self {
        Self(handle)
    }

    pub fn as_raw(&self) -> cnativeapi::native_window_shape_t {
        self.0
    }

    /// Runs `f` against the borrowed handle. The `WindowShape` it receives
    /// must not outlive the call.
    pub fn with<R>(&self, f: impl FnOnce(&WindowShape) -> R) -> R {
        let borrowed = std::mem::ManuallyDrop::new(WindowShape { handle: self.0 });
        f(&borrowed)
    }
}

