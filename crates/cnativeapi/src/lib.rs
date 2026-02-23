//! Native API C bindings for Rust
//!
//! This crate provides low-level FFI bindings to the nativeapi C library,
//! which offers cross-platform native system API access.
//!
//! The bindings are automatically generated using bindgen from the C headers.

// Include the generated bindings
#![allow(non_upper_case_globals)]
#![allow(non_camel_case_types)]
#![allow(non_snake_case)]

mod bindings;

// Re-export everything from bindings
pub use bindings::*;

// Re-export common types for convenience
pub use std::ffi::{CStr, CString};
pub use std::os::raw::{c_char, c_int, c_long, c_void};

/// Safe wrapper for creating a CString from a Rust string
pub fn to_cstring(s: &str) -> Result<CString, std::ffi::NulError> {
    CString::new(s)
}

/// Safe wrapper for converting a C string pointer to a Rust string
///
/// # Safety
/// The caller must ensure that the pointer is valid and points to a null-terminated string.
pub unsafe fn from_cstring(ptr: *const c_char) -> Option<&'static str> {
    if ptr.is_null() {
        None
    } else {
        CStr::from_ptr(ptr).to_str().ok()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_string_conversion() {
        let rust_string = "Hello, World!";
        let c_string = to_cstring(rust_string).unwrap();

        unsafe {
            let back_to_rust = from_cstring(c_string.as_ptr()).unwrap();
            assert_eq!(rust_string, back_to_rust);
        }
    }
}
