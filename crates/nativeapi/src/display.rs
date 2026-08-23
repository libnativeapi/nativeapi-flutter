// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

use crate::geometry::{Point, Rectangle, Size};

pub type DisplayId = u32;

#[repr(i32)]
#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum DisplayOrientation {
    Portrait = 0,
    Landscape = 90,
    PortraitFlipped = 180,
    LandscapeFlipped = 270,
}

impl DisplayOrientation {
    pub(crate) fn from_raw(raw: cnativeapi::native_display_orientation_t) -> Self {
        match raw {
            cnativeapi::NATIVE_DISPLAY_ORIENTATION_PORTRAIT => Self::Portrait,
            cnativeapi::NATIVE_DISPLAY_ORIENTATION_LANDSCAPE => Self::Landscape,
            cnativeapi::NATIVE_DISPLAY_ORIENTATION_PORTRAIT_FLIPPED => Self::PortraitFlipped,
            cnativeapi::NATIVE_DISPLAY_ORIENTATION_LANDSCAPE_FLIPPED => Self::LandscapeFlipped,
            _ => Self::Portrait,
        }
    }

    pub(crate) fn to_raw(self) -> cnativeapi::native_display_orientation_t {
        self as cnativeapi::native_display_orientation_t
    }
}

/// One `DisplayEvent`, in its concrete form.
#[derive(Debug, Clone, PartialEq)]
pub enum DisplayEvent {
    Added { display: DisplayRef },
    Removed { display: DisplayRef },
    Changed { display: DisplayRef },
}

impl DisplayEvent {
    pub(crate) unsafe fn from_raw(raw: &cnativeapi::native_display_event_t) -> Option<Self> {
        Some(match raw.type_ {
            cnativeapi::NATIVE_DISPLAY_EVENT_TYPE_ADDED => Self::Added { display: DisplayRef::from_raw(raw.display) },
            cnativeapi::NATIVE_DISPLAY_EVENT_TYPE_REMOVED => Self::Removed { display: DisplayRef::from_raw(raw.display) },
            cnativeapi::NATIVE_DISPLAY_EVENT_TYPE_CHANGED => Self::Changed { display: DisplayRef::from_raw(raw.display) },
            _ => return None,
        })
    }
}

/// Owned handle to a native `Display`.
#[derive(Debug)]
pub struct Display {
    handle: cnativeapi::native_display_t,
}

impl Display {
    /// Adopts a handle returned by the C API.
    ///
    /// # Safety
    /// `handle` must be a live handle that is not owned elsewhere.
    pub unsafe fn from_raw(handle: cnativeapi::native_display_t) -> Option<Self> {
        if handle == 0 {
            None
        } else {
            Some(Self { handle })
        }
    }

    /// Borrows the underlying C handle.
    pub fn as_raw(&self) -> cnativeapi::native_display_t {
        self.handle
    }

    /// Creates a new `Display`; returns `None` if the native side failed.
    pub fn new(display: *mut std::ffi::c_void) -> Option<Self> {
        unsafe {
            Self::from_raw(cnativeapi::native_display_create(display))
        }
    }

    pub fn id(&self) -> DisplayId {
        unsafe {
            cnativeapi::native_display_get_id(self.handle)
        }
    }

    pub fn name(&self) -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_display_get_name(self.handle);
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn position(&self) -> Point {
        unsafe {
            let raw = cnativeapi::native_display_get_position(self.handle);
            Point::from_raw(&raw)
        }
    }

    pub fn size(&self) -> Size {
        unsafe {
            let raw = cnativeapi::native_display_get_size(self.handle);
            Size::from_raw(&raw)
        }
    }

    pub fn work_area(&self) -> Rectangle {
        unsafe {
            let raw = cnativeapi::native_display_get_work_area(self.handle);
            Rectangle::from_raw(&raw)
        }
    }

    pub fn scale_factor(&self) -> f64 {
        unsafe {
            cnativeapi::native_display_get_scale_factor(self.handle)
        }
    }

    pub fn is_primary(&self) -> bool {
        unsafe {
            cnativeapi::native_display_is_primary(self.handle)
        }
    }

    pub fn orientation(&self) -> DisplayOrientation {
        unsafe {
            DisplayOrientation::from_raw(cnativeapi::native_display_get_orientation(self.handle))
        }
    }

    pub fn refresh_rate(&self) -> i32 {
        unsafe {
            cnativeapi::native_display_get_refresh_rate(self.handle)
        }
    }

    pub fn bit_depth(&self) -> i32 {
        unsafe {
            cnativeapi::native_display_get_bit_depth(self.handle)
        }
    }

    /// Platform-specific native object behind this handle.
    pub fn native_object(&self) -> *mut std::ffi::c_void {
        unsafe { cnativeapi::native_display_get_native_object(self.handle) }
    }

}

impl Drop for Display {
    fn drop(&mut self) {
        if self.handle != 0 {
            unsafe { cnativeapi::native_display_free(self.handle) };
        }
    }
}

/// A `Display` owned elsewhere; using it does not release it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct DisplayRef(cnativeapi::native_display_t);

impl DisplayRef {
    pub(crate) fn from_raw(handle: cnativeapi::native_display_t) -> Self {
        Self(handle)
    }

    pub fn as_raw(&self) -> cnativeapi::native_display_t {
        self.0
    }

    /// Runs `f` against the borrowed handle. The `Display` it receives
    /// must not outlive the call.
    pub fn with<R>(&self, f: impl FnOnce(&Display) -> R) -> R {
        let borrowed = std::mem::ManuallyDrop::new(Display { handle: self.0 });
        f(&borrowed)
    }
}

