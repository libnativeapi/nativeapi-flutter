// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

#[repr(i32)]
#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum DialogModality {
    None = 0,
    Application = 1,
    Window = 2,
}

impl DialogModality {
    pub(crate) fn from_raw(raw: cnativeapi::native_dialog_modality_t) -> Self {
        match raw {
            cnativeapi::NATIVE_DIALOG_MODALITY_NONE => Self::None,
            cnativeapi::NATIVE_DIALOG_MODALITY_APPLICATION => Self::Application,
            cnativeapi::NATIVE_DIALOG_MODALITY_WINDOW => Self::Window,
            _ => Self::None,
        }
    }

    pub(crate) fn to_raw(self) -> cnativeapi::native_dialog_modality_t {
        self as cnativeapi::native_dialog_modality_t
    }
}

