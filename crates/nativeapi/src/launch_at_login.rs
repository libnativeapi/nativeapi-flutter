// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

/// Owned handle to a native `LaunchAtLogin`.
#[derive(Debug)]
pub struct LaunchAtLogin {
    handle: cnativeapi::native_launch_at_login_t,
}

impl LaunchAtLogin {
    /// Adopts a handle returned by the C API.
    ///
    /// # Safety
    /// `handle` must be a live handle that is not owned elsewhere.
    pub unsafe fn from_raw(handle: cnativeapi::native_launch_at_login_t) -> Option<Self> {
        if handle == 0 {
            None
        } else {
            Some(Self { handle })
        }
    }

    /// Borrows the underlying C handle.
    pub fn as_raw(&self) -> cnativeapi::native_launch_at_login_t {
        self.handle
    }

    /// Creates a new `LaunchAtLogin`; returns `None` if the native side failed.
    pub fn new() -> Option<Self> {
        unsafe {
            Self::from_raw(cnativeapi::native_launch_at_login_create())
        }
    }

    /// Creates a new `LaunchAtLogin`; returns `None` if the native side failed.
    pub fn with_id(id: &str) -> Option<Self> {
        let id_native = CString::new(id).expect("string argument contains interior nul byte");
        unsafe {
            Self::from_raw(cnativeapi::native_launch_at_login_create_with_id(id_native.as_ptr()))
        }
    }

    /// Creates a new `LaunchAtLogin`; returns `None` if the native side failed.
    pub fn with_id_and_display_name(id: &str, display_name: &str) -> Option<Self> {
        let id_native = CString::new(id).expect("string argument contains interior nul byte");
        let display_name_native = CString::new(display_name).expect("string argument contains interior nul byte");
        unsafe {
            Self::from_raw(cnativeapi::native_launch_at_login_create_with_id_and_display_name(id_native.as_ptr(), display_name_native.as_ptr()))
        }
    }

    pub fn is_supported() -> bool {
        unsafe {
            cnativeapi::native_launch_at_login_is_supported()
        }
    }

    pub fn id(&self) -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_launch_at_login_get_id(self.handle);
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn display_name(&self) -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_launch_at_login_get_display_name(self.handle);
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn set_display_name(&self, display_name: &str) -> bool {
        let display_name_native = CString::new(display_name).expect("string argument contains interior nul byte");
        unsafe {
            cnativeapi::native_launch_at_login_set_display_name(self.handle, display_name_native.as_ptr())
        }
    }

    pub fn set_program(&self, executable_path: &str, arguments: &[String]) -> bool {
        let executable_path_native = CString::new(executable_path).expect("string argument contains interior nul byte");
        let arguments_owned: Vec<CString> = arguments
            .iter()
            .map(|value| CString::new(value.as_str()).unwrap_or_default())
            .collect();
        let mut arguments_ptrs: Vec<*mut std::os::raw::c_char> =
            arguments_owned.iter().map(|value| value.as_ptr() as *mut _).collect();
        let arguments_native = cnativeapi::native_string_list_t {
            items: arguments_ptrs.as_mut_ptr(),
            count: arguments_ptrs.len() as std::os::raw::c_long,
        };
        unsafe {
            cnativeapi::native_launch_at_login_set_program(self.handle, executable_path_native.as_ptr(), arguments_native)
        }
    }

    pub fn executable_path(&self) -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_launch_at_login_get_executable_path(self.handle);
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn arguments(&self) -> Vec<String> {
        unsafe {
            let mut list = cnativeapi::native_launch_at_login_get_arguments(self.handle);
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

    pub fn enable(&self) -> bool {
        unsafe {
            cnativeapi::native_launch_at_login_enable(self.handle)
        }
    }

    pub fn disable(&self) -> bool {
        unsafe {
            cnativeapi::native_launch_at_login_disable(self.handle)
        }
    }

    pub fn is_enabled(&self) -> bool {
        unsafe {
            cnativeapi::native_launch_at_login_is_enabled(self.handle)
        }
    }

}

impl Drop for LaunchAtLogin {
    fn drop(&mut self) {
        if self.handle != 0 {
            unsafe { cnativeapi::native_launch_at_login_free(self.handle) };
        }
    }
}

/// A `LaunchAtLogin` owned elsewhere; using it does not release it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct LaunchAtLoginRef(cnativeapi::native_launch_at_login_t);

impl LaunchAtLoginRef {
    pub(crate) fn from_raw(handle: cnativeapi::native_launch_at_login_t) -> Self {
        Self(handle)
    }

    pub fn as_raw(&self) -> cnativeapi::native_launch_at_login_t {
        self.0
    }

    /// Runs `f` against the borrowed handle. The `LaunchAtLogin` it receives
    /// must not outlive the call.
    pub fn with<R>(&self, f: impl FnOnce(&LaunchAtLogin) -> R) -> R {
        let borrowed = std::mem::ManuallyDrop::new(LaunchAtLogin { handle: self.0 });
        f(&borrowed)
    }
}

