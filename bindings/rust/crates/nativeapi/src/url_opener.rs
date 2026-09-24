// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

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

impl UrlOpenErrorCode {
    pub(crate) fn from_raw(raw: cnativeapi::native_url_open_error_code_t) -> Self {
        match raw {
            cnativeapi::NATIVE_URL_OPEN_ERROR_CODE_NONE => Self::None,
            cnativeapi::NATIVE_URL_OPEN_ERROR_CODE_INVALID_URL_EMPTY => Self::InvalidUrlEmpty,
            cnativeapi::NATIVE_URL_OPEN_ERROR_CODE_INVALID_URL_MISSING_SCHEME => Self::InvalidUrlMissingScheme,
            cnativeapi::NATIVE_URL_OPEN_ERROR_CODE_INVALID_URL_UNSUPPORTED_SCHEME => Self::InvalidUrlUnsupportedScheme,
            cnativeapi::NATIVE_URL_OPEN_ERROR_CODE_UNSUPPORTED_PLATFORM => Self::UnsupportedPlatform,
            cnativeapi::NATIVE_URL_OPEN_ERROR_CODE_INVOCATION_FAILED => Self::InvocationFailed,
            _ => Self::None,
        }
    }

    pub(crate) fn to_raw(self) -> cnativeapi::native_url_open_error_code_t {
        self as cnativeapi::native_url_open_error_code_t
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct UrlOpenResult {
    pub success: bool,
    pub error_code: UrlOpenErrorCode,
    pub error_message: Option<String>,
}

impl UrlOpenResult {
    pub(crate) unsafe fn from_raw(raw: &cnativeapi::native_url_open_result_t) -> Self {
        Self {
            success: raw.success,
            error_code: UrlOpenErrorCode::from_raw(raw.error_code),
            error_message: if raw.error_message.is_null() { None } else { Some(CStr::from_ptr(raw.error_message).to_string_lossy().into_owned()) },
        }
    }

    pub(crate) fn to_raw(&self) -> RawOfUrlOpenResult {
        let mut raw = cnativeapi::native_url_open_result_t::default();
        raw.success = self.success;
        raw.error_code = self.error_code.to_raw();
        let error_message_owned = self.error_message.as_deref().map(|value| CString::new(value).unwrap_or_default());
        raw.error_message = error_message_owned.as_ref().map_or(std::ptr::null_mut(), |value| value.as_ptr() as *mut _);
        RawOfUrlOpenResult { raw, _owned: (error_message_owned, ()) }
    }
}

/// `UrlOpenResult` in its C form, keeping any borrowed buffers alive.
pub(crate) struct RawOfUrlOpenResult {
    pub(crate) raw: cnativeapi::native_url_open_result_t,
    _owned: (Option<CString>, ()),
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

