// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]

use cnativeapi;
use std::ffi::CStr;
use std::ffi::CString;

#[repr(i32)]
#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum UrlOpenErrorCode {
    None = 0,
    InvalidUrlEmpty = 1,
    InvalidUrlMissingScheme = 2,
    InvalidUrlUnsupportedScheme = 3,
    UnsupportedPlatform = 4,
    InvocationFailed = 5,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct UrlOpenResult {
    pub success: bool,
    pub error_code: UrlOpenErrorCode,
    pub error_message: Option<String>,
}

impl UrlOpenResult {
    unsafe fn from_raw(raw: &cnativeapi::native_url_open_result_t) -> Self {
        Self {
            success: raw.success,
            error_code: std::mem::transmute::<i32, UrlOpenErrorCode>(raw.error_code as i32),
            error_message: if raw.error_message.is_null() { None } else { Some(CStr::from_ptr(raw.error_message).to_string_lossy().into_owned()) },
        }
    }
}

pub struct UrlOpener;

impl UrlOpener {
    pub fn is_supported() -> bool {
        unsafe {
            cnativeapi::native_url_opener_is_supported()
        }
    }
    pub fn can_open(url: &str) -> bool {
        let url_native = CString::new(url).expect("string argument contains interior nul byte");
        unsafe {
            cnativeapi::native_url_opener_can_open(url_native.as_ptr())
        }
    }
    pub fn open(url: &str) -> UrlOpenResult {
        let url_native = CString::new(url).expect("string argument contains interior nul byte");
        unsafe {
            let mut raw = cnativeapi::native_url_opener_open(url_native.as_ptr());
            let result = UrlOpenResult::from_raw(&raw);
            cnativeapi::native_url_open_result_free(&mut raw);
            result
        }
    }
}

