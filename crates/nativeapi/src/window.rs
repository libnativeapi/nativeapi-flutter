// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

use crate::color::Color;
use crate::geometry::{Point, Rectangle, Size};

pub type WindowId = u32;

#[repr(i32)]
#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum TitleBarStyle {
    Normal = 0,
    Hidden = 1,
}

impl TitleBarStyle {
    pub(crate) fn from_raw(raw: cnativeapi::native_title_bar_style_t) -> Self {
        match raw {
            cnativeapi::NATIVE_TITLE_BAR_STYLE_NORMAL => Self::Normal,
            cnativeapi::NATIVE_TITLE_BAR_STYLE_HIDDEN => Self::Hidden,
            _ => Self::Normal,
        }
    }

    pub(crate) fn to_raw(self) -> cnativeapi::native_title_bar_style_t {
        self as cnativeapi::native_title_bar_style_t
    }
}

#[repr(i32)]
#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum VisualEffect {
    None = 0,
    Blur = 1,
    Acrylic = 2,
    Mica = 3,
    MicaAlt = 4,
    Hud = 5,
    Popover = 6,
    Menu = 7,
}

impl VisualEffect {
    pub(crate) fn from_raw(raw: cnativeapi::native_visual_effect_t) -> Self {
        match raw {
            cnativeapi::NATIVE_VISUAL_EFFECT_NONE => Self::None,
            cnativeapi::NATIVE_VISUAL_EFFECT_BLUR => Self::Blur,
            cnativeapi::NATIVE_VISUAL_EFFECT_ACRYLIC => Self::Acrylic,
            cnativeapi::NATIVE_VISUAL_EFFECT_MICA => Self::Mica,
            cnativeapi::NATIVE_VISUAL_EFFECT_MICA_ALT => Self::MicaAlt,
            cnativeapi::NATIVE_VISUAL_EFFECT_HUD => Self::Hud,
            cnativeapi::NATIVE_VISUAL_EFFECT_POPOVER => Self::Popover,
            cnativeapi::NATIVE_VISUAL_EFFECT_MENU => Self::Menu,
            _ => Self::None,
        }
    }

    pub(crate) fn to_raw(self) -> cnativeapi::native_visual_effect_t {
        self as cnativeapi::native_visual_effect_t
    }
}

#[repr(i32)]
#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum ResizeEdge {
    Top = 0,
    Left = 1,
    Right = 2,
    Bottom = 3,
    TopLeft = 4,
    TopRight = 5,
    BottomLeft = 6,
    BottomRight = 7,
}

impl ResizeEdge {
    pub(crate) fn from_raw(raw: cnativeapi::native_resize_edge_t) -> Self {
        match raw {
            cnativeapi::NATIVE_RESIZE_EDGE_TOP => Self::Top,
            cnativeapi::NATIVE_RESIZE_EDGE_LEFT => Self::Left,
            cnativeapi::NATIVE_RESIZE_EDGE_RIGHT => Self::Right,
            cnativeapi::NATIVE_RESIZE_EDGE_BOTTOM => Self::Bottom,
            cnativeapi::NATIVE_RESIZE_EDGE_TOP_LEFT => Self::TopLeft,
            cnativeapi::NATIVE_RESIZE_EDGE_TOP_RIGHT => Self::TopRight,
            cnativeapi::NATIVE_RESIZE_EDGE_BOTTOM_LEFT => Self::BottomLeft,
            cnativeapi::NATIVE_RESIZE_EDGE_BOTTOM_RIGHT => Self::BottomRight,
            _ => Self::Top,
        }
    }

    pub(crate) fn to_raw(self) -> cnativeapi::native_resize_edge_t {
        self as cnativeapi::native_resize_edge_t
    }
}

/// One `WindowEvent`, in its concrete form.
#[derive(Debug, Clone, PartialEq)]
pub enum WindowEvent {
    Focused { window_id: WindowId },
    Blurred { window_id: WindowId },
    Minimized { window_id: WindowId },
    Maximized { window_id: WindowId },
    Restored { window_id: WindowId },
    Moved { window_id: WindowId, new_position: Point },
    Resized { window_id: WindowId, new_size: Size },
    Created { window_id: WindowId },
    Closed { window_id: WindowId },
}

impl WindowEvent {
    pub(crate) unsafe fn from_raw(raw: &cnativeapi::native_window_event_t) -> Option<Self> {
        Some(match raw.type_ {
            cnativeapi::NATIVE_WINDOW_EVENT_TYPE_FOCUSED => Self::Focused { window_id: raw.window_id },
            cnativeapi::NATIVE_WINDOW_EVENT_TYPE_BLURRED => Self::Blurred { window_id: raw.window_id },
            cnativeapi::NATIVE_WINDOW_EVENT_TYPE_MINIMIZED => Self::Minimized { window_id: raw.window_id },
            cnativeapi::NATIVE_WINDOW_EVENT_TYPE_MAXIMIZED => Self::Maximized { window_id: raw.window_id },
            cnativeapi::NATIVE_WINDOW_EVENT_TYPE_RESTORED => Self::Restored { window_id: raw.window_id },
            cnativeapi::NATIVE_WINDOW_EVENT_TYPE_MOVED => Self::Moved { window_id: raw.window_id, new_position: Point::from_raw(&raw.data.moved.new_position) },
            cnativeapi::NATIVE_WINDOW_EVENT_TYPE_RESIZED => Self::Resized { window_id: raw.window_id, new_size: Size::from_raw(&raw.data.resized.new_size) },
            cnativeapi::NATIVE_WINDOW_EVENT_TYPE_CREATED => Self::Created { window_id: raw.window_id },
            cnativeapi::NATIVE_WINDOW_EVENT_TYPE_CLOSED => Self::Closed { window_id: raw.window_id },
            _ => return None,
        })
    }
}

/// Owned handle to a native `Window`.
#[derive(Debug)]
pub struct Window {
    handle: cnativeapi::native_window_t,
}

impl Window {
    /// Adopts a handle returned by the C API.
    ///
    /// # Safety
    /// `handle` must be a live handle that is not owned elsewhere.
    pub unsafe fn from_raw(handle: cnativeapi::native_window_t) -> Option<Self> {
        if handle == 0 {
            None
        } else {
            Some(Self { handle })
        }
    }

    /// Borrows the underlying C handle.
    pub fn as_raw(&self) -> cnativeapi::native_window_t {
        self.handle
    }

    /// Creates a new `Window`; returns `None` if the native side failed.
    pub fn new() -> Option<Self> {
        unsafe {
            Self::from_raw(cnativeapi::native_window_create())
        }
    }

    /// Creates a new `Window`; returns `None` if the native side failed.
    ///
    /// # Safety
    /// Raw pointers must reference valid platform objects of the expected type.
    /// The caller must uphold the native API's thread and lifetime requirements,
    /// including keeping objects alive while the returned wrapper uses them.
    pub unsafe fn with_native_window(native_window: *mut std::ffi::c_void) -> Option<Self> {
        unsafe {
            Self::from_raw(cnativeapi::native_window_create_with_native_window(native_window))
        }
    }

    pub fn id(&self) -> WindowId {
        unsafe {
            cnativeapi::native_window_get_id(self.handle)
        }
    }

    pub fn focus(&self) {
        unsafe {
            cnativeapi::native_window_focus(self.handle);
        }
    }

    pub fn blur(&self) {
        unsafe {
            cnativeapi::native_window_blur(self.handle);
        }
    }

    pub fn is_focused(&self) -> bool {
        unsafe {
            cnativeapi::native_window_is_focused(self.handle)
        }
    }

    pub fn show(&self) {
        unsafe {
            cnativeapi::native_window_show(self.handle);
        }
    }

    pub fn show_inactive(&self) {
        unsafe {
            cnativeapi::native_window_show_inactive(self.handle);
        }
    }

    pub fn hide(&self) {
        unsafe {
            cnativeapi::native_window_hide(self.handle);
        }
    }

    pub fn is_visible(&self) -> bool {
        unsafe {
            cnativeapi::native_window_is_visible(self.handle)
        }
    }

    pub fn maximize(&self) {
        unsafe {
            cnativeapi::native_window_maximize(self.handle);
        }
    }

    pub fn unmaximize(&self) {
        unsafe {
            cnativeapi::native_window_unmaximize(self.handle);
        }
    }

    pub fn is_maximized(&self) -> bool {
        unsafe {
            cnativeapi::native_window_is_maximized(self.handle)
        }
    }

    pub fn minimize(&self) {
        unsafe {
            cnativeapi::native_window_minimize(self.handle);
        }
    }

    pub fn restore(&self) {
        unsafe {
            cnativeapi::native_window_restore(self.handle);
        }
    }

    pub fn is_minimized(&self) -> bool {
        unsafe {
            cnativeapi::native_window_is_minimized(self.handle)
        }
    }

    pub fn set_full_screen(&self, is_full_screen: bool) {
        unsafe {
            cnativeapi::native_window_set_full_screen(self.handle, is_full_screen);
        }
    }

    pub fn is_full_screen(&self) -> bool {
        unsafe {
            cnativeapi::native_window_is_full_screen(self.handle)
        }
    }

    pub fn set_bounds(&self, bounds: &Rectangle) {
        let bounds_raw = bounds.to_raw();
        unsafe {
            cnativeapi::native_window_set_bounds(self.handle, bounds_raw.raw);
        }
    }

    pub fn bounds(&self) -> Rectangle {
        unsafe {
            let raw = cnativeapi::native_window_get_bounds(self.handle);
            Rectangle::from_raw(&raw)
        }
    }

    pub fn set_content_bounds(&self, bounds: &Rectangle) {
        let bounds_raw = bounds.to_raw();
        unsafe {
            cnativeapi::native_window_set_content_bounds(self.handle, bounds_raw.raw);
        }
    }

    pub fn content_bounds(&self) -> Rectangle {
        unsafe {
            let raw = cnativeapi::native_window_get_content_bounds(self.handle);
            Rectangle::from_raw(&raw)
        }
    }

    pub fn set_size(&self, size: &Size, animate: bool) {
        let size_raw = size.to_raw();
        unsafe {
            cnativeapi::native_window_set_size(self.handle, size_raw.raw, animate);
        }
    }

    pub fn size(&self) -> Size {
        unsafe {
            let raw = cnativeapi::native_window_get_size(self.handle);
            Size::from_raw(&raw)
        }
    }

    pub fn set_content_size(&self, size: &Size) {
        let size_raw = size.to_raw();
        unsafe {
            cnativeapi::native_window_set_content_size(self.handle, size_raw.raw);
        }
    }

    pub fn content_size(&self) -> Size {
        unsafe {
            let raw = cnativeapi::native_window_get_content_size(self.handle);
            Size::from_raw(&raw)
        }
    }

    pub fn set_minimum_size(&self, size: &Size) {
        let size_raw = size.to_raw();
        unsafe {
            cnativeapi::native_window_set_minimum_size(self.handle, size_raw.raw);
        }
    }

    pub fn minimum_size(&self) -> Size {
        unsafe {
            let raw = cnativeapi::native_window_get_minimum_size(self.handle);
            Size::from_raw(&raw)
        }
    }

    pub fn set_maximum_size(&self, size: &Size) {
        let size_raw = size.to_raw();
        unsafe {
            cnativeapi::native_window_set_maximum_size(self.handle, size_raw.raw);
        }
    }

    pub fn maximum_size(&self) -> Size {
        unsafe {
            let raw = cnativeapi::native_window_get_maximum_size(self.handle);
            Size::from_raw(&raw)
        }
    }

    pub fn set_aspect_ratio(&self, aspect_ratio: f64) {
        unsafe {
            cnativeapi::native_window_set_aspect_ratio(self.handle, aspect_ratio);
        }
    }

    pub fn aspect_ratio(&self) -> f64 {
        unsafe {
            cnativeapi::native_window_get_aspect_ratio(self.handle)
        }
    }

    pub fn set_resizable(&self, is_resizable: bool) {
        unsafe {
            cnativeapi::native_window_set_resizable(self.handle, is_resizable);
        }
    }

    pub fn is_resizable(&self) -> bool {
        unsafe {
            cnativeapi::native_window_is_resizable(self.handle)
        }
    }

    pub fn set_movable(&self, is_movable: bool) {
        unsafe {
            cnativeapi::native_window_set_movable(self.handle, is_movable);
        }
    }

    pub fn is_movable(&self) -> bool {
        unsafe {
            cnativeapi::native_window_is_movable(self.handle)
        }
    }

    pub fn set_minimizable(&self, is_minimizable: bool) {
        unsafe {
            cnativeapi::native_window_set_minimizable(self.handle, is_minimizable);
        }
    }

    pub fn is_minimizable(&self) -> bool {
        unsafe {
            cnativeapi::native_window_is_minimizable(self.handle)
        }
    }

    pub fn set_maximizable(&self, is_maximizable: bool) {
        unsafe {
            cnativeapi::native_window_set_maximizable(self.handle, is_maximizable);
        }
    }

    pub fn is_maximizable(&self) -> bool {
        unsafe {
            cnativeapi::native_window_is_maximizable(self.handle)
        }
    }

    pub fn set_full_screenable(&self, is_full_screenable: bool) {
        unsafe {
            cnativeapi::native_window_set_full_screenable(self.handle, is_full_screenable);
        }
    }

    pub fn is_full_screenable(&self) -> bool {
        unsafe {
            cnativeapi::native_window_is_full_screenable(self.handle)
        }
    }

    pub fn set_closable(&self, is_closable: bool) {
        unsafe {
            cnativeapi::native_window_set_closable(self.handle, is_closable);
        }
    }

    pub fn is_closable(&self) -> bool {
        unsafe {
            cnativeapi::native_window_is_closable(self.handle)
        }
    }

    pub fn set_window_control_buttons_visible(&self, is_visible: bool) {
        unsafe {
            cnativeapi::native_window_set_window_control_buttons_visible(self.handle, is_visible);
        }
    }

    pub fn is_window_control_buttons_visible(&self) -> bool {
        unsafe {
            cnativeapi::native_window_is_window_control_buttons_visible(self.handle)
        }
    }

    pub fn set_always_on_top(&self, is_always_on_top: bool) {
        unsafe {
            cnativeapi::native_window_set_always_on_top(self.handle, is_always_on_top);
        }
    }

    pub fn is_always_on_top(&self) -> bool {
        unsafe {
            cnativeapi::native_window_is_always_on_top(self.handle)
        }
    }

    pub fn set_always_on_bottom(&self, is_always_on_bottom: bool) {
        unsafe {
            cnativeapi::native_window_set_always_on_bottom(self.handle, is_always_on_bottom);
        }
    }

    pub fn is_always_on_bottom(&self) -> bool {
        unsafe {
            cnativeapi::native_window_is_always_on_bottom(self.handle)
        }
    }

    pub fn set_parent_window(&self, parent: Option<&Window>) -> bool {
        unsafe {
            cnativeapi::native_window_set_parent_window(self.handle, parent.map_or(0, |value| value.as_raw()))
        }
    }

    pub fn parent_window(&self) -> Option<Window> {
        unsafe {
            Window::from_raw(cnativeapi::native_window_get_parent_window(self.handle))
        }
    }

    pub fn set_non_activating(&self, is_non_activating: bool) {
        unsafe {
            cnativeapi::native_window_set_non_activating(self.handle, is_non_activating);
        }
    }

    pub fn is_non_activating(&self) -> bool {
        unsafe {
            cnativeapi::native_window_is_non_activating(self.handle)
        }
    }

    pub fn set_position(&self, point: &Point) {
        let point_raw = point.to_raw();
        unsafe {
            cnativeapi::native_window_set_position(self.handle, point_raw.raw);
        }
    }

    pub fn position(&self) -> Point {
        unsafe {
            let raw = cnativeapi::native_window_get_position(self.handle);
            Point::from_raw(&raw)
        }
    }

    pub fn center(&self) {
        unsafe {
            cnativeapi::native_window_center(self.handle);
        }
    }

    pub fn set_title(&self, title: &str) {
        let title_native = CString::new(title).expect("string argument contains interior nul byte");
        unsafe {
            cnativeapi::native_window_set_title(self.handle, title_native.as_ptr());
        }
    }

    pub fn title(&self) -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_window_get_title(self.handle);
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn set_title_bar_colors(&self, background: &Color, foreground: &Color) -> bool {
        let background_raw = background.to_raw();
        let foreground_raw = foreground.to_raw();
        unsafe {
            cnativeapi::native_window_set_title_bar_colors(self.handle, background_raw.raw, foreground_raw.raw)
        }
    }

    pub fn reset_title_bar_colors(&self) -> bool {
        unsafe {
            cnativeapi::native_window_reset_title_bar_colors(self.handle)
        }
    }

    pub fn set_title_bar_style(&self, style: TitleBarStyle) {
        unsafe {
            cnativeapi::native_window_set_title_bar_style(self.handle, style.to_raw());
        }
    }

    pub fn title_bar_style(&self) -> TitleBarStyle {
        unsafe {
            TitleBarStyle::from_raw(cnativeapi::native_window_get_title_bar_style(self.handle))
        }
    }

    pub fn set_content_under_title_bar(&self, is_content_under_title_bar: bool) -> bool {
        unsafe {
            cnativeapi::native_window_set_content_under_title_bar(self.handle, is_content_under_title_bar)
        }
    }

    pub fn is_content_under_title_bar(&self) -> bool {
        unsafe {
            cnativeapi::native_window_is_content_under_title_bar(self.handle)
        }
    }

    pub fn is_content_under_title_bar_supported() -> bool {
        unsafe {
            cnativeapi::native_window_is_content_under_title_bar_supported()
        }
    }

    pub fn set_has_shadow(&self, has_shadow: bool) {
        unsafe {
            cnativeapi::native_window_set_has_shadow(self.handle, has_shadow);
        }
    }

    pub fn has_shadow(&self) -> bool {
        unsafe {
            cnativeapi::native_window_has_shadow(self.handle)
        }
    }

    pub fn set_opacity(&self, opacity: f32) {
        unsafe {
            cnativeapi::native_window_set_opacity(self.handle, opacity);
        }
    }

    pub fn opacity(&self) -> f32 {
        unsafe {
            cnativeapi::native_window_get_opacity(self.handle)
        }
    }

    pub fn set_visual_effect(&self, effect: VisualEffect) -> bool {
        unsafe {
            cnativeapi::native_window_set_visual_effect(self.handle, effect.to_raw())
        }
    }

    pub fn visual_effect(&self) -> VisualEffect {
        unsafe {
            VisualEffect::from_raw(cnativeapi::native_window_get_visual_effect(self.handle))
        }
    }

    pub fn is_visual_effect_supported(effect: VisualEffect) -> bool {
        unsafe {
            cnativeapi::native_window_is_visual_effect_supported(effect.to_raw())
        }
    }

    pub fn set_background_color(&self, color: &Color) {
        let color_raw = color.to_raw();
        unsafe {
            cnativeapi::native_window_set_background_color(self.handle, color_raw.raw);
        }
    }

    pub fn background_color(&self) -> Color {
        unsafe {
            let raw = cnativeapi::native_window_get_background_color(self.handle);
            Color::from_raw(&raw)
        }
    }

    pub fn set_visible_on_all_workspaces(&self, is_visible_on_all_workspaces: bool) {
        unsafe {
            cnativeapi::native_window_set_visible_on_all_workspaces(self.handle, is_visible_on_all_workspaces);
        }
    }

    pub fn is_visible_on_all_workspaces(&self) -> bool {
        unsafe {
            cnativeapi::native_window_is_visible_on_all_workspaces(self.handle)
        }
    }

    pub fn set_visible_in_taskbar(&self, is_visible_in_taskbar: bool) {
        unsafe {
            cnativeapi::native_window_set_visible_in_taskbar(self.handle, is_visible_in_taskbar);
        }
    }

    pub fn is_visible_in_taskbar(&self) -> bool {
        unsafe {
            cnativeapi::native_window_is_visible_in_taskbar(self.handle)
        }
    }

    pub fn set_ignore_mouse_events(&self, is_ignore_mouse_events: bool) {
        unsafe {
            cnativeapi::native_window_set_ignore_mouse_events(self.handle, is_ignore_mouse_events);
        }
    }

    pub fn is_ignore_mouse_events(&self) -> bool {
        unsafe {
            cnativeapi::native_window_is_ignore_mouse_events(self.handle)
        }
    }

    pub fn set_focusable(&self, is_focusable: bool) {
        unsafe {
            cnativeapi::native_window_set_focusable(self.handle, is_focusable);
        }
    }

    pub fn is_focusable(&self) -> bool {
        unsafe {
            cnativeapi::native_window_is_focusable(self.handle)
        }
    }

    pub fn start_dragging(&self) {
        unsafe {
            cnativeapi::native_window_start_dragging(self.handle);
        }
    }

    pub fn start_resizing(&self, edge: ResizeEdge) {
        unsafe {
            cnativeapi::native_window_start_resizing(self.handle, edge.to_raw());
        }
    }

    /// Platform-specific native object behind this handle.
    pub fn native_object(&self) -> *mut std::ffi::c_void {
        unsafe { cnativeapi::native_window_get_native_object(self.handle) }
    }

}

impl Drop for Window {
    fn drop(&mut self) {
        if self.handle != 0 {
            unsafe { cnativeapi::native_window_free(self.handle) };
        }
    }
}

/// A `Window` owned elsewhere; using it does not release it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct WindowRef(cnativeapi::native_window_t);

impl WindowRef {
    pub(crate) fn from_raw(handle: cnativeapi::native_window_t) -> Self {
        Self(handle)
    }

    pub fn as_raw(&self) -> cnativeapi::native_window_t {
        self.0
    }

    /// Runs `f` against the borrowed handle. The `Window` it receives
    /// must not outlive the call.
    pub fn with<R>(&self, f: impl FnOnce(&Window) -> R) -> R {
        let borrowed = std::mem::ManuallyDrop::new(Window { handle: self.0 });
        f(&borrowed)
    }
}

