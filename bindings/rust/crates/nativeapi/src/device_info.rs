// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

pub struct DeviceInfo;

impl DeviceInfo {
    pub fn get_name() -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_device_info_get_name();
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn get_model() -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_device_info_get_model();
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn get_manufacturer() -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_device_info_get_manufacturer();
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn get_os_name() -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_device_info_get_os_name();
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn get_os_version() -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_device_info_get_os_version();
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn get_kernel_version() -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_device_info_get_kernel_version();
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn get_architecture() -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_device_info_get_architecture();
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

}

