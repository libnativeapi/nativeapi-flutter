// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]

use cnativeapi;
use std::ffi::CStr;
use std::ffi::CString;

#[derive(Debug, Clone, PartialEq)]
pub struct Point {
    pub x: f64,
    pub y: f64,
}

#[derive(Debug, Clone, PartialEq)]
pub struct Size {
    pub width: f64,
    pub height: f64,
}

#[derive(Debug, Clone, PartialEq)]
pub struct Rectangle {
    pub x: f64,
    pub y: f64,
    pub width: f64,
    pub height: f64,
}

impl Point {
    unsafe fn from_raw(raw: &cnativeapi::native_point_t) -> Self {
        Self {
            x: raw.x,
            y: raw.y,
        }
    }
}

impl Size {
    unsafe fn from_raw(raw: &cnativeapi::native_size_t) -> Self {
        Self {
            width: raw.width,
            height: raw.height,
        }
    }
}

impl Rectangle {
    unsafe fn from_raw(raw: &cnativeapi::native_rectangle_t) -> Self {
        Self {
            x: raw.x,
            y: raw.y,
            width: raw.width,
            height: raw.height,
        }
    }
}

