// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

use crate::geometry::{Point, Rectangle};
use crate::window::Window;

#[repr(i32)]
#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum PositioningStrategyType {
    Absolute = 0,
    CursorPosition = 1,
    Relative = 2,
}

impl PositioningStrategyType {
    pub(crate) fn from_raw(raw: cnativeapi::native_positioning_strategy_type_t) -> Self {
        match raw {
            cnativeapi::NATIVE_POSITIONING_STRATEGY_TYPE_ABSOLUTE => Self::Absolute,
            cnativeapi::NATIVE_POSITIONING_STRATEGY_TYPE_CURSOR_POSITION => Self::CursorPosition,
            cnativeapi::NATIVE_POSITIONING_STRATEGY_TYPE_RELATIVE => Self::Relative,
            _ => Self::Absolute,
        }
    }

    pub(crate) fn to_raw(self) -> cnativeapi::native_positioning_strategy_type_t {
        self as cnativeapi::native_positioning_strategy_type_t
    }
}

/// Owned handle to a native `PositioningStrategy`.
#[derive(Debug)]
#[repr(transparent)]
pub struct PositioningStrategy {
    handle: cnativeapi::native_positioning_strategy_t,
}

impl PositioningStrategy {
    /// Adopts a handle returned by the C API.
    ///
    /// # Safety
    /// `handle` must be a live handle that is not owned elsewhere.
    pub unsafe fn from_raw(handle: cnativeapi::native_positioning_strategy_t) -> Option<Self> {
        if handle == 0 {
            None
        } else {
            Some(Self { handle })
        }
    }

    /// Borrows the underlying C handle.
    pub fn as_raw(&self) -> cnativeapi::native_positioning_strategy_t {
        self.handle
    }

    pub fn absolute(point: &Point) -> Option<PositioningStrategy> {
        let point_raw = point.to_raw();
        unsafe {
            PositioningStrategy::from_raw(cnativeapi::native_positioning_strategy_absolute(point_raw.raw))
        }
    }

    pub fn cursor_position() -> Option<PositioningStrategy> {
        unsafe {
            PositioningStrategy::from_raw(cnativeapi::native_positioning_strategy_cursor_position())
        }
    }

    pub fn relative_with_rect_and_offset(rect: &Rectangle, offset: &Point) -> Option<PositioningStrategy> {
        let rect_raw = rect.to_raw();
        let offset_raw = offset.to_raw();
        unsafe {
            PositioningStrategy::from_raw(cnativeapi::native_positioning_strategy_relative_with_rect_and_offset(rect_raw.raw, offset_raw.raw))
        }
    }

    pub fn relative_with_window_and_offset(window: &Window, offset: &Point) -> Option<PositioningStrategy> {
        let offset_raw = offset.to_raw();
        unsafe {
            PositioningStrategy::from_raw(cnativeapi::native_positioning_strategy_relative_with_window_and_offset(window.as_raw(), offset_raw.raw))
        }
    }

    pub fn r#type(&self) -> PositioningStrategyType {
        unsafe {
            PositioningStrategyType::from_raw(cnativeapi::native_positioning_strategy_get_type(self.handle))
        }
    }

    pub fn absolute_position(&self) -> Point {
        unsafe {
            let raw = cnativeapi::native_positioning_strategy_get_absolute_position(self.handle);
            Point::from_raw(&raw)
        }
    }

    pub fn relative_rectangle(&self) -> Rectangle {
        unsafe {
            let raw = cnativeapi::native_positioning_strategy_get_relative_rectangle(self.handle);
            Rectangle::from_raw(&raw)
        }
    }

    pub fn relative_offset(&self) -> Point {
        unsafe {
            let raw = cnativeapi::native_positioning_strategy_get_relative_offset(self.handle);
            Point::from_raw(&raw)
        }
    }

}

impl Drop for PositioningStrategy {
    fn drop(&mut self) {
        if self.handle != 0 {
            unsafe { cnativeapi::native_positioning_strategy_free(self.handle) };
        }
    }
}

/// A `PositioningStrategy` owned elsewhere; using it does not release it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PositioningStrategyRef(cnativeapi::native_positioning_strategy_t);

impl PositioningStrategyRef {
    pub(crate) fn from_raw(handle: cnativeapi::native_positioning_strategy_t) -> Self {
        Self(handle)
    }

    pub fn as_raw(&self) -> cnativeapi::native_positioning_strategy_t {
        self.0
    }

    /// Runs `f` against the borrowed handle. The `PositioningStrategy` it receives
    /// must not outlive the call.
    pub fn with<R>(&self, f: impl FnOnce(&PositioningStrategy) -> R) -> R {
        let borrowed = std::mem::ManuallyDrop::new(PositioningStrategy { handle: self.0 });
        f(&borrowed)
    }
}

