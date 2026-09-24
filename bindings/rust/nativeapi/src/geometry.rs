// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

#[derive(Debug, Clone, PartialEq)]
pub struct Point {
    pub x: f64,
    pub y: f64,
}

impl Point {
    pub(crate) unsafe fn from_raw(raw: &cnativeapi::native_point_t) -> Self {
        Self {
            x: raw.x,
            y: raw.y,
        }
    }

    pub(crate) fn to_raw(&self) -> RawOfPoint {
        let mut raw = cnativeapi::native_point_t::default();
        raw.x = self.x;
        raw.y = self.y;
        RawOfPoint { raw, _owned: () }
    }
}

/// `Point` in its C form, keeping any borrowed buffers alive.
pub(crate) struct RawOfPoint {
    pub(crate) raw: cnativeapi::native_point_t,
    _owned: (),
}

#[derive(Debug, Clone, PartialEq)]
pub struct Size {
    pub width: f64,
    pub height: f64,
}

impl Size {
    pub(crate) unsafe fn from_raw(raw: &cnativeapi::native_size_t) -> Self {
        Self {
            width: raw.width,
            height: raw.height,
        }
    }

    pub(crate) fn to_raw(&self) -> RawOfSize {
        let mut raw = cnativeapi::native_size_t::default();
        raw.width = self.width;
        raw.height = self.height;
        RawOfSize { raw, _owned: () }
    }
}

/// `Size` in its C form, keeping any borrowed buffers alive.
pub(crate) struct RawOfSize {
    pub(crate) raw: cnativeapi::native_size_t,
    _owned: (),
}

#[derive(Debug, Clone, PartialEq)]
pub struct Rectangle {
    pub x: f64,
    pub y: f64,
    pub width: f64,
    pub height: f64,
}

impl Rectangle {
    pub(crate) unsafe fn from_raw(raw: &cnativeapi::native_rectangle_t) -> Self {
        Self {
            x: raw.x,
            y: raw.y,
            width: raw.width,
            height: raw.height,
        }
    }

    pub(crate) fn to_raw(&self) -> RawOfRectangle {
        let mut raw = cnativeapi::native_rectangle_t::default();
        raw.x = self.x;
        raw.y = self.y;
        raw.width = self.width;
        raw.height = self.height;
        RawOfRectangle { raw, _owned: () }
    }
}

/// `Rectangle` in its C form, keeping any borrowed buffers alive.
pub(crate) struct RawOfRectangle {
    pub(crate) raw: cnativeapi::native_rectangle_t,
    _owned: (),
}

