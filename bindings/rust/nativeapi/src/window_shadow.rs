// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

use crate::color::Color;
use crate::geometry::Point;

/// Owned handle to a native `WindowShadow`.
#[derive(Debug)]
#[repr(transparent)]
pub struct WindowShadow {
    handle: cnativeapi::native_window_shadow_t,
}

impl WindowShadow {
    /// Adopts a handle returned by the C API.
    ///
    /// # Safety
    /// `handle` must be a live handle that is not owned elsewhere.
    pub unsafe fn from_raw(handle: cnativeapi::native_window_shadow_t) -> Option<Self> {
        if handle == 0 {
            None
        } else {
            Some(Self { handle })
        }
    }

    /// Borrows the underlying C handle.
    pub fn as_raw(&self) -> cnativeapi::native_window_shadow_t {
        self.handle
    }

    /// Creates a new `WindowShadow`; returns `None` if the native side failed.
    pub fn new() -> Option<Self> {
        unsafe {
            Self::from_raw(cnativeapi::native_window_shadow_create())
        }
    }

    pub fn set_color(&self, color: &Color) {
        let color_raw = color.to_raw();
        unsafe {
            cnativeapi::native_window_shadow_set_color(self.handle, color_raw.raw);
        }
    }

    pub fn color(&self) -> Color {
        unsafe {
            let raw = cnativeapi::native_window_shadow_get_color(self.handle);
            Color::from_raw(&raw)
        }
    }

    pub fn set_blur_radius(&self, radius: f64) -> bool {
        unsafe {
            cnativeapi::native_window_shadow_set_blur_radius(self.handle, radius)
        }
    }

    pub fn blur_radius(&self) -> f64 {
        unsafe {
            cnativeapi::native_window_shadow_get_blur_radius(self.handle)
        }
    }

    pub fn set_offset(&self, offset: &Point) -> bool {
        let offset_raw = offset.to_raw();
        unsafe {
            cnativeapi::native_window_shadow_set_offset(self.handle, offset_raw.raw)
        }
    }

    pub fn offset(&self) -> Point {
        unsafe {
            let raw = cnativeapi::native_window_shadow_get_offset(self.handle);
            Point::from_raw(&raw)
        }
    }

}

impl Drop for WindowShadow {
    fn drop(&mut self) {
        if self.handle != 0 {
            unsafe { cnativeapi::native_window_shadow_free(self.handle) };
        }
    }
}

/// A `WindowShadow` owned elsewhere; using it does not release it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct WindowShadowRef(cnativeapi::native_window_shadow_t);

impl WindowShadowRef {
    pub(crate) fn from_raw(handle: cnativeapi::native_window_shadow_t) -> Self {
        Self(handle)
    }

    pub fn as_raw(&self) -> cnativeapi::native_window_shadow_t {
        self.0
    }

    /// Runs `f` against the borrowed handle. The `WindowShadow` it receives
    /// must not outlive the call.
    pub fn with<R>(&self, f: impl FnOnce(&WindowShadow) -> R) -> R {
        let borrowed = std::mem::ManuallyDrop::new(WindowShadow { handle: self.0 });
        f(&borrowed)
    }
}

