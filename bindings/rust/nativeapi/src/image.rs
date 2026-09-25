// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

use crate::geometry::Size;

/// Owned handle to a native `Image`.
#[derive(Debug)]
#[repr(transparent)]
pub struct Image {
    handle: cnativeapi::native_image_t,
}

impl Image {
    /// Adopts a handle returned by the C API.
    ///
    /// # Safety
    /// `handle` must be a live handle that is not owned elsewhere.
    pub unsafe fn from_raw(handle: cnativeapi::native_image_t) -> Option<Self> {
        if handle == 0 {
            None
        } else {
            Some(Self { handle })
        }
    }

    /// Borrows the underlying C handle.
    pub fn as_raw(&self) -> cnativeapi::native_image_t {
        self.handle
    }

    pub fn from_file(file_path: &str) -> Option<Image> {
        let file_path_native = CString::new(file_path).expect("string argument contains interior nul byte");
        unsafe {
            Image::from_raw(cnativeapi::native_image_from_file(file_path_native.as_ptr()))
        }
    }

    pub fn from_base64(base64_data: &str) -> Option<Image> {
        let base64_data_native = CString::new(base64_data).expect("string argument contains interior nul byte");
        unsafe {
            Image::from_raw(cnativeapi::native_image_from_base64(base64_data_native.as_ptr()))
        }
    }

    pub fn size(&self) -> Size {
        unsafe {
            let raw = cnativeapi::native_image_get_size(self.handle);
            Size::from_raw(&raw)
        }
    }

    pub fn format(&self) -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_image_get_format(self.handle);
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn to_base64(&self) -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_image_to_base64(self.handle);
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn save_to_file(&self, file_path: &str) -> bool {
        let file_path_native = CString::new(file_path).expect("string argument contains interior nul byte");
        unsafe {
            cnativeapi::native_image_save_to_file(self.handle, file_path_native.as_ptr())
        }
    }

    /// Platform-specific native object behind this handle.
    pub fn native_object(&self) -> *mut std::ffi::c_void {
        unsafe { cnativeapi::native_image_get_native_object(self.handle) }
    }

}

impl Drop for Image {
    fn drop(&mut self) {
        if self.handle != 0 {
            unsafe { cnativeapi::native_image_free(self.handle) };
        }
    }
}

/// A `Image` owned elsewhere; using it does not release it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ImageRef(cnativeapi::native_image_t);

impl ImageRef {
    pub(crate) fn from_raw(handle: cnativeapi::native_image_t) -> Self {
        Self(handle)
    }

    pub fn as_raw(&self) -> cnativeapi::native_image_t {
        self.0
    }

    /// Runs `f` against the borrowed handle. The `Image` it receives
    /// must not outlive the call.
    pub fn with<R>(&self, f: impl FnOnce(&Image) -> R) -> R {
        let borrowed = std::mem::ManuallyDrop::new(Image { handle: self.0 });
        f(&borrowed)
    }
}

