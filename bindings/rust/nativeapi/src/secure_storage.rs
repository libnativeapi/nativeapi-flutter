// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

/// Owned handle to a native `SecureStorage`.
#[derive(Debug)]
#[repr(transparent)]
pub struct SecureStorage {
    handle: cnativeapi::native_secure_storage_t,
}

impl SecureStorage {
    /// Adopts a handle returned by the C API.
    ///
    /// # Safety
    /// `handle` must be a live handle that is not owned elsewhere.
    pub unsafe fn from_raw(handle: cnativeapi::native_secure_storage_t) -> Option<Self> {
        if handle == 0 {
            None
        } else {
            Some(Self { handle })
        }
    }

    /// Borrows the underlying C handle.
    pub fn as_raw(&self) -> cnativeapi::native_secure_storage_t {
        self.handle
    }

    /// Creates a new `SecureStorage`; returns `None` if the native side failed.
    pub fn new() -> Option<Self> {
        unsafe {
            Self::from_raw(cnativeapi::native_secure_storage_create())
        }
    }

    /// Creates a new `SecureStorage`; returns `None` if the native side failed.
    pub fn with_scope(scope: &str) -> Option<Self> {
        let scope_native = CString::new(scope).expect("string argument contains interior nul byte");
        unsafe {
            Self::from_raw(cnativeapi::native_secure_storage_create_with_scope(scope_native.as_ptr()))
        }
    }

    pub fn set(&self, key: &str, value: &str) -> bool {
        let key_native = CString::new(key).expect("string argument contains interior nul byte");
        let value_native = CString::new(value).expect("string argument contains interior nul byte");
        unsafe {
            cnativeapi::native_secure_storage_set(self.handle, key_native.as_ptr(), value_native.as_ptr())
        }
    }

    pub fn get(&self, key: &str, default_value: &str) -> Option<String> {
        let key_native = CString::new(key).expect("string argument contains interior nul byte");
        let default_value_native = CString::new(default_value).expect("string argument contains interior nul byte");
        unsafe {
            let ptr = cnativeapi::native_secure_storage_get(self.handle, key_native.as_ptr(), default_value_native.as_ptr());
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn remove(&self, key: &str) -> bool {
        let key_native = CString::new(key).expect("string argument contains interior nul byte");
        unsafe {
            cnativeapi::native_secure_storage_remove(self.handle, key_native.as_ptr())
        }
    }

    pub fn clear(&self) -> bool {
        unsafe {
            cnativeapi::native_secure_storage_clear(self.handle)
        }
    }

    pub fn contains(&self, key: &str) -> bool {
        let key_native = CString::new(key).expect("string argument contains interior nul byte");
        unsafe {
            cnativeapi::native_secure_storage_contains(self.handle, key_native.as_ptr())
        }
    }

    pub fn keys(&self) -> Vec<String> {
        unsafe {
            let mut list = cnativeapi::native_secure_storage_get_keys(self.handle);
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

    pub fn size(&self) -> std::os::raw::c_ulong {
        unsafe {
            cnativeapi::native_secure_storage_get_size(self.handle)
        }
    }

    pub fn all(&self) -> std::collections::HashMap<String, String> {
        unsafe {
            let mut raw = cnativeapi::native_secure_storage_get_all(self.handle);
            let mut entries = std::collections::HashMap::new();
            if !raw.keys.is_null() && !raw.values.is_null() {
                for index in 0..raw.count as isize {
                    let key = *raw.keys.offset(index);
                    let value = *raw.values.offset(index);
                    if key.is_null() {
                        continue;
                    }
                    entries.insert(
                        CStr::from_ptr(key).to_string_lossy().into_owned(),
                        if value.is_null() { String::new() } else { CStr::from_ptr(value).to_string_lossy().into_owned() },
                    );
                }
            }
            cnativeapi::native_string_map_free(&mut raw);
            entries
        }
    }

    pub fn scope(&self) -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_secure_storage_get_scope(self.handle);
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn is_available() -> bool {
        unsafe {
            cnativeapi::native_secure_storage_is_available()
        }
    }

}

impl Drop for SecureStorage {
    fn drop(&mut self) {
        if self.handle != 0 {
            unsafe { cnativeapi::native_secure_storage_free(self.handle) };
        }
    }
}

/// A `SecureStorage` owned elsewhere; using it does not release it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct SecureStorageRef(cnativeapi::native_secure_storage_t);

impl SecureStorageRef {
    pub(crate) fn from_raw(handle: cnativeapi::native_secure_storage_t) -> Self {
        Self(handle)
    }

    pub fn as_raw(&self) -> cnativeapi::native_secure_storage_t {
        self.0
    }

    /// Runs `f` against the borrowed handle. The `SecureStorage` it receives
    /// must not outlive the call.
    pub fn with<R>(&self, f: impl FnOnce(&SecureStorage) -> R) -> R {
        let borrowed = std::mem::ManuallyDrop::new(SecureStorage { handle: self.0 });
        f(&borrowed)
    }
}

