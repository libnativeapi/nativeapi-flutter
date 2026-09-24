// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Color {
    pub r: u8,
    pub g: u8,
    pub b: u8,
    pub a: u8,
}

impl Color {
    pub(crate) unsafe fn from_raw(raw: &cnativeapi::native_color_t) -> Self {
        Self {
            r: raw.r,
            g: raw.g,
            b: raw.b,
            a: raw.a,
        }
    }

    pub(crate) fn to_raw(&self) -> RawOfColor {
        let mut raw = cnativeapi::native_color_t::default();
        raw.r = self.r;
        raw.g = self.g;
        raw.b = self.b;
        raw.a = self.a;
        RawOfColor { raw, _owned: () }
    }
}

/// `Color` in its C form, keeping any borrowed buffers alive.
pub(crate) struct RawOfColor {
    pub(crate) raw: cnativeapi::native_color_t,
    _owned: (),
}

