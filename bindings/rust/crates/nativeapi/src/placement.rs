// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

#[repr(i32)]
#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum Placement {
    Top = 0,
    TopStart = 1,
    TopEnd = 2,
    Right = 3,
    RightStart = 4,
    RightEnd = 5,
    Bottom = 6,
    BottomStart = 7,
    BottomEnd = 8,
    Left = 9,
    LeftStart = 10,
    LeftEnd = 11,
}

impl Placement {
    pub(crate) fn from_raw(raw: cnativeapi::native_placement_t) -> Self {
        match raw {
            cnativeapi::NATIVE_PLACEMENT_TOP => Self::Top,
            cnativeapi::NATIVE_PLACEMENT_TOP_START => Self::TopStart,
            cnativeapi::NATIVE_PLACEMENT_TOP_END => Self::TopEnd,
            cnativeapi::NATIVE_PLACEMENT_RIGHT => Self::Right,
            cnativeapi::NATIVE_PLACEMENT_RIGHT_START => Self::RightStart,
            cnativeapi::NATIVE_PLACEMENT_RIGHT_END => Self::RightEnd,
            cnativeapi::NATIVE_PLACEMENT_BOTTOM => Self::Bottom,
            cnativeapi::NATIVE_PLACEMENT_BOTTOM_START => Self::BottomStart,
            cnativeapi::NATIVE_PLACEMENT_BOTTOM_END => Self::BottomEnd,
            cnativeapi::NATIVE_PLACEMENT_LEFT => Self::Left,
            cnativeapi::NATIVE_PLACEMENT_LEFT_START => Self::LeftStart,
            cnativeapi::NATIVE_PLACEMENT_LEFT_END => Self::LeftEnd,
            _ => Self::Top,
        }
    }

    pub(crate) fn to_raw(self) -> cnativeapi::native_placement_t {
        self as cnativeapi::native_placement_t
    }
}

