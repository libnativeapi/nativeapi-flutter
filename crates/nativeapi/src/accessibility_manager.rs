// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]

use cnativeapi;
use std::ffi::CStr;
use std::ffi::CString;

pub struct AccessibilityManager;

impl AccessibilityManager {
    pub fn enable() -> () {
        unsafe {
            cnativeapi::native_accessibility_manager_enable();
        }
    }
    pub fn is_enabled() -> bool {
        unsafe {
            cnativeapi::native_accessibility_manager_is_enabled()
        }
    }
}

