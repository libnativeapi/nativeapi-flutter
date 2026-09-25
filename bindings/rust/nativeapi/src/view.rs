// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

use crate::color::Color;
use crate::geometry::{EdgeInsets, Rectangle, Size};
use crate::image::Image;
use crate::window::Window;

/// Identifies one registered event listener.
pub type ListenerId = cnativeapi::native_listener_id_t;

pub type ViewId = u32;

#[repr(i32)]
#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum ViewLayout {
    Absolute = 0,
    Row = 1,
    Column = 2,
}

impl ViewLayout {
    pub(crate) fn from_raw(raw: cnativeapi::native_view_layout_t) -> Self {
        match raw {
            cnativeapi::NATIVE_VIEW_LAYOUT_ABSOLUTE => Self::Absolute,
            cnativeapi::NATIVE_VIEW_LAYOUT_ROW => Self::Row,
            cnativeapi::NATIVE_VIEW_LAYOUT_COLUMN => Self::Column,
            _ => Self::Absolute,
        }
    }

    pub(crate) fn to_raw(self) -> cnativeapi::native_view_layout_t {
        self as cnativeapi::native_view_layout_t
    }
}

#[repr(i32)]
#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum ViewAlignment {
    Stretch = 0,
    Start = 1,
    Center = 2,
    End = 3,
}

impl ViewAlignment {
    pub(crate) fn from_raw(raw: cnativeapi::native_view_alignment_t) -> Self {
        match raw {
            cnativeapi::NATIVE_VIEW_ALIGNMENT_STRETCH => Self::Stretch,
            cnativeapi::NATIVE_VIEW_ALIGNMENT_START => Self::Start,
            cnativeapi::NATIVE_VIEW_ALIGNMENT_CENTER => Self::Center,
            cnativeapi::NATIVE_VIEW_ALIGNMENT_END => Self::End,
            _ => Self::Stretch,
        }
    }

    pub(crate) fn to_raw(self) -> cnativeapi::native_view_alignment_t {
        self as cnativeapi::native_view_alignment_t
    }
}

#[repr(i32)]
#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum TextAlignment {
    Start = 0,
    Center = 1,
    End = 2,
}

impl TextAlignment {
    pub(crate) fn from_raw(raw: cnativeapi::native_text_alignment_t) -> Self {
        match raw {
            cnativeapi::NATIVE_TEXT_ALIGNMENT_START => Self::Start,
            cnativeapi::NATIVE_TEXT_ALIGNMENT_CENTER => Self::Center,
            cnativeapi::NATIVE_TEXT_ALIGNMENT_END => Self::End,
            _ => Self::Start,
        }
    }

    pub(crate) fn to_raw(self) -> cnativeapi::native_text_alignment_t {
        self as cnativeapi::native_text_alignment_t
    }
}

#[repr(i32)]
#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum ViewBackend {
    Native = 0,
    WinUi3 = 1,
}

impl ViewBackend {
    pub(crate) fn from_raw(raw: cnativeapi::native_view_backend_t) -> Self {
        match raw {
            cnativeapi::NATIVE_VIEW_BACKEND_NATIVE => Self::Native,
            cnativeapi::NATIVE_VIEW_BACKEND_WIN_UI3 => Self::WinUi3,
            _ => Self::Native,
        }
    }

    pub(crate) fn to_raw(self) -> cnativeapi::native_view_backend_t {
        self as cnativeapi::native_view_backend_t
    }
}

/// One `ViewEvent`, in its concrete form.
#[derive(Debug, Clone, PartialEq)]
pub enum ViewEvent {
    Focused { view_id: ViewId },
    Blurred { view_id: ViewId },
    ButtonClicked { view_id: ViewId },
    TextFieldChanged { view_id: ViewId, text: Option<String> },
    TextFieldSubmitted { view_id: ViewId },
}

impl ViewEvent {
    pub(crate) unsafe fn from_raw(raw: &cnativeapi::native_view_event_t) -> Option<Self> {
        Some(match raw.type_ {
            cnativeapi::NATIVE_VIEW_EVENT_TYPE_FOCUSED => Self::Focused { view_id: raw.view_id },
            cnativeapi::NATIVE_VIEW_EVENT_TYPE_BLURRED => Self::Blurred { view_id: raw.view_id },
            cnativeapi::NATIVE_VIEW_EVENT_TYPE_BUTTON_CLICKED => Self::ButtonClicked { view_id: raw.view_id },
            cnativeapi::NATIVE_VIEW_EVENT_TYPE_TEXT_FIELD_CHANGED => Self::TextFieldChanged { view_id: raw.view_id, text: if raw.data.text_field_changed.text.is_null() { None } else { Some(CStr::from_ptr(raw.data.text_field_changed.text).to_string_lossy().into_owned()) } },
            cnativeapi::NATIVE_VIEW_EVENT_TYPE_TEXT_FIELD_SUBMITTED => Self::TextFieldSubmitted { view_id: raw.view_id },
            _ => return None,
        })
    }
}

/// Owned handle to a native `View`.
#[derive(Debug)]
#[repr(transparent)]
pub struct View {
    handle: cnativeapi::native_view_t,
}

impl View {
    /// Adopts a handle returned by the C API.
    ///
    /// # Safety
    /// `handle` must be a live handle that is not owned elsewhere.
    pub unsafe fn from_raw(handle: cnativeapi::native_view_t) -> Option<Self> {
        if handle == 0 {
            None
        } else {
            Some(Self { handle })
        }
    }

    /// Borrows the underlying C handle.
    pub fn as_raw(&self) -> cnativeapi::native_view_t {
        self.handle
    }

    /// Creates a new `View`; returns `None` if the native side failed.
    pub fn new() -> Option<Self> {
        unsafe {
            Self::from_raw(cnativeapi::native_view_create())
        }
    }

    /// Creates a new `View`; returns `None` if the native side failed.
    ///
    /// # Safety
    /// Raw pointers must reference valid platform objects of the expected type.
    /// The caller must uphold the native API's thread and lifetime requirements,
    /// including keeping objects alive while the returned wrapper uses them.
    pub unsafe fn with_native_view(native_view: *mut std::ffi::c_void) -> Option<Self> {
        unsafe {
            Self::from_raw(cnativeapi::native_view_create_with_native_view(native_view))
        }
    }

    pub fn is_supported() -> bool {
        unsafe {
            cnativeapi::native_view_is_supported()
        }
    }

    pub fn is_backend_supported(backend: ViewBackend) -> bool {
        unsafe {
            cnativeapi::native_view_is_backend_supported(backend.to_raw())
        }
    }

    pub fn set_default_backend(backend: ViewBackend) -> bool {
        unsafe {
            cnativeapi::native_view_set_default_backend(backend.to_raw())
        }
    }

    pub fn get_default_backend() -> ViewBackend {
        unsafe {
            ViewBackend::from_raw(cnativeapi::native_view_get_default_backend())
        }
    }

    pub fn id(&self) -> ViewId {
        unsafe {
            cnativeapi::native_view_get_id(self.handle)
        }
    }

    pub fn backend(&self) -> ViewBackend {
        unsafe {
            ViewBackend::from_raw(cnativeapi::native_view_get_backend(self.handle))
        }
    }

    pub fn add_subview(&self, subview: Option<&View>) {
        unsafe {
            cnativeapi::native_view_add_subview(self.handle, subview.map_or(0, |value| value.as_raw()));
        }
    }

    pub fn insert_subview(&self, index: std::os::raw::c_ulong, subview: Option<&View>) {
        unsafe {
            cnativeapi::native_view_insert_subview(self.handle, index, subview.map_or(0, |value| value.as_raw()));
        }
    }

    pub fn remove_subview(&self, subview: Option<&View>) -> bool {
        unsafe {
            cnativeapi::native_view_remove_subview(self.handle, subview.map_or(0, |value| value.as_raw()))
        }
    }

    pub fn remove_subview_at(&self, index: std::os::raw::c_ulong) -> bool {
        unsafe {
            cnativeapi::native_view_remove_subview_at(self.handle, index)
        }
    }

    pub fn clear_subviews(&self) {
        unsafe {
            cnativeapi::native_view_clear_subviews(self.handle);
        }
    }

    pub fn subview_count(&self) -> std::os::raw::c_ulong {
        unsafe {
            cnativeapi::native_view_get_subview_count(self.handle)
        }
    }

    pub fn get_subview_at(&self, index: std::os::raw::c_ulong) -> Option<View> {
        unsafe {
            View::from_raw(cnativeapi::native_view_get_subview_at(self.handle, index))
        }
    }

    pub fn subviews(&self) -> Vec<View> {
        unsafe {
            let mut list = cnativeapi::native_view_get_subviews(self.handle);
            let mut items = Vec::new();
            if !list.views.is_null() {
                for index in 0..list.count as isize {
                    if let Some(item) = View::from_raw(*list.views.offset(index)) {
                        items.push(item);
                    }
                }
            }
            // Handles are now owned by `items`; drop just the array.
            cnativeapi::native_view_list_release(&mut list);
            items
        }
    }

    pub fn parent(&self) -> Option<View> {
        unsafe {
            View::from_raw(cnativeapi::native_view_get_parent(self.handle))
        }
    }

    pub fn window(&self) -> Option<Window> {
        unsafe {
            Window::from_raw(cnativeapi::native_view_get_window(self.handle))
        }
    }

    pub fn set_frame(&self, frame: &Rectangle) {
        let frame_raw = frame.to_raw();
        unsafe {
            cnativeapi::native_view_set_frame(self.handle, frame_raw.raw);
        }
    }

    pub fn frame(&self) -> Rectangle {
        unsafe {
            let raw = cnativeapi::native_view_get_frame(self.handle);
            Rectangle::from_raw(&raw)
        }
    }

    pub fn set_preferred_size(&self, size: &Size) {
        let size_raw = size.to_raw();
        unsafe {
            cnativeapi::native_view_set_preferred_size(self.handle, size_raw.raw);
        }
    }

    pub fn preferred_size(&self) -> Size {
        unsafe {
            let raw = cnativeapi::native_view_get_preferred_size(self.handle);
            Size::from_raw(&raw)
        }
    }

    pub fn intrinsic_size(&self) -> Size {
        unsafe {
            let raw = cnativeapi::native_view_get_intrinsic_size(self.handle);
            Size::from_raw(&raw)
        }
    }

    pub fn set_flex(&self, flex: f64) {
        unsafe {
            cnativeapi::native_view_set_flex(self.handle, flex);
        }
    }

    pub fn flex(&self) -> f64 {
        unsafe {
            cnativeapi::native_view_get_flex(self.handle)
        }
    }

    pub fn set_alignment(&self, alignment: ViewAlignment) {
        unsafe {
            cnativeapi::native_view_set_alignment(self.handle, alignment.to_raw());
        }
    }

    pub fn alignment(&self) -> ViewAlignment {
        unsafe {
            ViewAlignment::from_raw(cnativeapi::native_view_get_alignment(self.handle))
        }
    }

    pub fn set_layout(&self, layout: ViewLayout) {
        unsafe {
            cnativeapi::native_view_set_layout(self.handle, layout.to_raw());
        }
    }

    pub fn layout(&self) -> ViewLayout {
        unsafe {
            ViewLayout::from_raw(cnativeapi::native_view_get_layout(self.handle))
        }
    }

    pub fn set_spacing(&self, spacing: f64) {
        unsafe {
            cnativeapi::native_view_set_spacing(self.handle, spacing);
        }
    }

    pub fn spacing(&self) -> f64 {
        unsafe {
            cnativeapi::native_view_get_spacing(self.handle)
        }
    }

    pub fn set_padding(&self, padding: &EdgeInsets) {
        let padding_raw = padding.to_raw();
        unsafe {
            cnativeapi::native_view_set_padding(self.handle, padding_raw.raw);
        }
    }

    pub fn padding(&self) -> EdgeInsets {
        unsafe {
            let raw = cnativeapi::native_view_get_padding(self.handle);
            EdgeInsets::from_raw(&raw)
        }
    }

    pub fn set_visible(&self, is_visible: bool) {
        unsafe {
            cnativeapi::native_view_set_visible(self.handle, is_visible);
        }
    }

    pub fn is_visible(&self) -> bool {
        unsafe {
            cnativeapi::native_view_is_visible(self.handle)
        }
    }

    pub fn set_enabled(&self, is_enabled: bool) {
        unsafe {
            cnativeapi::native_view_set_enabled(self.handle, is_enabled);
        }
    }

    pub fn is_enabled(&self) -> bool {
        unsafe {
            cnativeapi::native_view_is_enabled(self.handle)
        }
    }

    pub fn set_background_color(&self, color: &Color) {
        let color_raw = color.to_raw();
        unsafe {
            cnativeapi::native_view_set_background_color(self.handle, color_raw.raw);
        }
    }

    pub fn background_color(&self) -> Color {
        unsafe {
            let raw = cnativeapi::native_view_get_background_color(self.handle);
            Color::from_raw(&raw)
        }
    }

    pub fn set_tooltip(&self, tooltip: Option<&str>) {
        let tooltip_native = tooltip.map(|value| CString::new(value).expect("string argument contains interior nul byte"));
        unsafe {
            cnativeapi::native_view_set_tooltip(self.handle, tooltip_native.as_ref().map_or(std::ptr::null(), |value| value.as_ptr()));
        }
    }

    pub fn tooltip(&self) -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_view_get_tooltip(self.handle);
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn focus(&self) {
        unsafe {
            cnativeapi::native_view_focus(self.handle);
        }
    }

    pub fn blur(&self) {
        unsafe {
            cnativeapi::native_view_blur(self.handle);
        }
    }

    pub fn is_focused(&self) -> bool {
        unsafe {
            cnativeapi::native_view_is_focused(self.handle)
        }
    }

    /// Platform-specific native object behind this handle.
    pub fn native_object(&self) -> *mut std::ffi::c_void {
        unsafe { cnativeapi::native_view_get_native_object(self.handle) }
    }

    /// Registers `callback` for every `ViewEvent` this `View` emits.
    ///
    /// The closure is dropped on the main thread once the listener is removed
    /// or its emitter destroyed.
    pub fn add_listener(&self, callback: impl Fn(&ViewEvent) + 'static) -> ListenerId {
        unsafe extern "C" fn trampoline(event: *const cnativeapi::native_view_event_t, user_data: *mut std::ffi::c_void) {
            if event.is_null() || user_data.is_null() {
                return;
            }
            let callback = &*(user_data as *const Box<dyn Fn(&ViewEvent)>);
            if let Some(event) = ViewEvent::from_raw(&*event) {
                callback(&event);
            }
        }
        let boxed: Box<Box<dyn Fn(&ViewEvent)>> = Box::new(Box::new(callback));
        let user_data = Box::into_raw(boxed) as *mut std::ffi::c_void;
        unsafe extern "C" fn release(user_data: *mut std::ffi::c_void) {
            drop(Box::from_raw(user_data as *mut Box<dyn Fn(&ViewEvent)>));
        }
        unsafe { cnativeapi::native_view_add_listener(self.handle, Some(trampoline), user_data, Some(release)) }
    }

    /// Unregisters a listener. Returns false if unknown.
    pub fn remove_listener(&self, listener_id: ListenerId) -> bool {
        unsafe { cnativeapi::native_view_remove_listener(self.handle, listener_id) }
    }

}

impl Drop for View {
    fn drop(&mut self) {
        if self.handle != 0 {
            unsafe { cnativeapi::native_view_free(self.handle) };
        }
    }
}

/// A `View` owned elsewhere; using it does not release it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ViewRef(cnativeapi::native_view_t);

impl ViewRef {
    pub(crate) fn from_raw(handle: cnativeapi::native_view_t) -> Self {
        Self(handle)
    }

    pub fn as_raw(&self) -> cnativeapi::native_view_t {
        self.0
    }

    /// Runs `f` against the borrowed handle. The `View` it receives
    /// must not outlive the call.
    pub fn with<R>(&self, f: impl FnOnce(&View) -> R) -> R {
        let borrowed = std::mem::ManuallyDrop::new(View { handle: self.0 });
        f(&borrowed)
    }
}

/// Owned handle to a native `Label`.
///
/// Derefs to [`View`]: the C ABI resolves this handle as a `View` too, so
/// every `View` method is available and a `&Label` coerces to `&View`.
#[derive(Debug)]
#[repr(transparent)]
pub struct Label {
    handle: cnativeapi::native_label_t,
}

impl std::ops::Deref for Label {
    type Target = View;
    fn deref(&self) -> &View {
        // Both are #[repr(transparent)] over the same handle type.
        unsafe { &*(self as *const Label as *const View) }
    }
}

impl AsRef<View> for Label {
    fn as_ref(&self) -> &View {
        self
    }
}

impl Label {
    /// Adopts a handle returned by the C API.
    ///
    /// # Safety
    /// `handle` must be a live handle that is not owned elsewhere.
    pub unsafe fn from_raw(handle: cnativeapi::native_label_t) -> Option<Self> {
        if handle == 0 {
            None
        } else {
            Some(Self { handle })
        }
    }

    /// Borrows the underlying C handle.
    pub fn as_raw(&self) -> cnativeapi::native_label_t {
        self.handle
    }

    /// Creates a new `Label`; returns `None` if the native side failed.
    pub fn new(text: &str) -> Option<Self> {
        let text_native = CString::new(text).expect("string argument contains interior nul byte");
        unsafe {
            Self::from_raw(cnativeapi::native_label_create(text_native.as_ptr()))
        }
    }

    pub fn set_text(&self, text: &str) {
        let text_native = CString::new(text).expect("string argument contains interior nul byte");
        unsafe {
            cnativeapi::native_label_set_text(self.handle, text_native.as_ptr());
        }
    }

    pub fn text(&self) -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_label_get_text(self.handle);
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn set_text_color(&self, color: &Color) {
        let color_raw = color.to_raw();
        unsafe {
            cnativeapi::native_label_set_text_color(self.handle, color_raw.raw);
        }
    }

    pub fn text_color(&self) -> Color {
        unsafe {
            let raw = cnativeapi::native_label_get_text_color(self.handle);
            Color::from_raw(&raw)
        }
    }

    pub fn set_font_size(&self, size: f64) {
        unsafe {
            cnativeapi::native_label_set_font_size(self.handle, size);
        }
    }

    pub fn font_size(&self) -> f64 {
        unsafe {
            cnativeapi::native_label_get_font_size(self.handle)
        }
    }

    pub fn set_text_alignment(&self, alignment: TextAlignment) {
        unsafe {
            cnativeapi::native_label_set_text_alignment(self.handle, alignment.to_raw());
        }
    }

    pub fn text_alignment(&self) -> TextAlignment {
        unsafe {
            TextAlignment::from_raw(cnativeapi::native_label_get_text_alignment(self.handle))
        }
    }

}

impl Drop for Label {
    fn drop(&mut self) {
        if self.handle != 0 {
            unsafe { cnativeapi::native_label_free(self.handle) };
        }
    }
}

/// A `Label` owned elsewhere; using it does not release it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct LabelRef(cnativeapi::native_label_t);

impl LabelRef {
    pub(crate) fn from_raw(handle: cnativeapi::native_label_t) -> Self {
        Self(handle)
    }

    pub fn as_raw(&self) -> cnativeapi::native_label_t {
        self.0
    }

    /// Runs `f` against the borrowed handle. The `Label` it receives
    /// must not outlive the call.
    pub fn with<R>(&self, f: impl FnOnce(&Label) -> R) -> R {
        let borrowed = std::mem::ManuallyDrop::new(Label { handle: self.0 });
        f(&borrowed)
    }
}

/// Owned handle to a native `Button`.
///
/// Derefs to [`View`]: the C ABI resolves this handle as a `View` too, so
/// every `View` method is available and a `&Button` coerces to `&View`.
#[derive(Debug)]
#[repr(transparent)]
pub struct Button {
    handle: cnativeapi::native_button_t,
}

impl std::ops::Deref for Button {
    type Target = View;
    fn deref(&self) -> &View {
        // Both are #[repr(transparent)] over the same handle type.
        unsafe { &*(self as *const Button as *const View) }
    }
}

impl AsRef<View> for Button {
    fn as_ref(&self) -> &View {
        self
    }
}

impl Button {
    /// Adopts a handle returned by the C API.
    ///
    /// # Safety
    /// `handle` must be a live handle that is not owned elsewhere.
    pub unsafe fn from_raw(handle: cnativeapi::native_button_t) -> Option<Self> {
        if handle == 0 {
            None
        } else {
            Some(Self { handle })
        }
    }

    /// Borrows the underlying C handle.
    pub fn as_raw(&self) -> cnativeapi::native_button_t {
        self.handle
    }

    /// Creates a new `Button`; returns `None` if the native side failed.
    pub fn new(text: &str) -> Option<Self> {
        let text_native = CString::new(text).expect("string argument contains interior nul byte");
        unsafe {
            Self::from_raw(cnativeapi::native_button_create(text_native.as_ptr()))
        }
    }

    pub fn set_text(&self, text: &str) {
        let text_native = CString::new(text).expect("string argument contains interior nul byte");
        unsafe {
            cnativeapi::native_button_set_text(self.handle, text_native.as_ptr());
        }
    }

    pub fn text(&self) -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_button_get_text(self.handle);
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

}

impl Drop for Button {
    fn drop(&mut self) {
        if self.handle != 0 {
            unsafe { cnativeapi::native_button_free(self.handle) };
        }
    }
}

/// A `Button` owned elsewhere; using it does not release it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ButtonRef(cnativeapi::native_button_t);

impl ButtonRef {
    pub(crate) fn from_raw(handle: cnativeapi::native_button_t) -> Self {
        Self(handle)
    }

    pub fn as_raw(&self) -> cnativeapi::native_button_t {
        self.0
    }

    /// Runs `f` against the borrowed handle. The `Button` it receives
    /// must not outlive the call.
    pub fn with<R>(&self, f: impl FnOnce(&Button) -> R) -> R {
        let borrowed = std::mem::ManuallyDrop::new(Button { handle: self.0 });
        f(&borrowed)
    }
}

/// Owned handle to a native `TextField`.
///
/// Derefs to [`View`]: the C ABI resolves this handle as a `View` too, so
/// every `View` method is available and a `&TextField` coerces to `&View`.
#[derive(Debug)]
#[repr(transparent)]
pub struct TextField {
    handle: cnativeapi::native_text_field_t,
}

impl std::ops::Deref for TextField {
    type Target = View;
    fn deref(&self) -> &View {
        // Both are #[repr(transparent)] over the same handle type.
        unsafe { &*(self as *const TextField as *const View) }
    }
}

impl AsRef<View> for TextField {
    fn as_ref(&self) -> &View {
        self
    }
}

impl TextField {
    /// Adopts a handle returned by the C API.
    ///
    /// # Safety
    /// `handle` must be a live handle that is not owned elsewhere.
    pub unsafe fn from_raw(handle: cnativeapi::native_text_field_t) -> Option<Self> {
        if handle == 0 {
            None
        } else {
            Some(Self { handle })
        }
    }

    /// Borrows the underlying C handle.
    pub fn as_raw(&self) -> cnativeapi::native_text_field_t {
        self.handle
    }

    /// Creates a new `TextField`; returns `None` if the native side failed.
    pub fn new(text: &str) -> Option<Self> {
        let text_native = CString::new(text).expect("string argument contains interior nul byte");
        unsafe {
            Self::from_raw(cnativeapi::native_text_field_create(text_native.as_ptr()))
        }
    }

    pub fn set_text(&self, text: &str) {
        let text_native = CString::new(text).expect("string argument contains interior nul byte");
        unsafe {
            cnativeapi::native_text_field_set_text(self.handle, text_native.as_ptr());
        }
    }

    pub fn text(&self) -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_text_field_get_text(self.handle);
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn set_text_color(&self, color: &Color) {
        let color_raw = color.to_raw();
        unsafe {
            cnativeapi::native_text_field_set_text_color(self.handle, color_raw.raw);
        }
    }

    pub fn text_color(&self) -> Color {
        unsafe {
            let raw = cnativeapi::native_text_field_get_text_color(self.handle);
            Color::from_raw(&raw)
        }
    }

    pub fn set_font_size(&self, size: f64) {
        unsafe {
            cnativeapi::native_text_field_set_font_size(self.handle, size);
        }
    }

    pub fn font_size(&self) -> f64 {
        unsafe {
            cnativeapi::native_text_field_get_font_size(self.handle)
        }
    }

    pub fn set_text_alignment(&self, alignment: TextAlignment) {
        unsafe {
            cnativeapi::native_text_field_set_text_alignment(self.handle, alignment.to_raw());
        }
    }

    pub fn text_alignment(&self) -> TextAlignment {
        unsafe {
            TextAlignment::from_raw(cnativeapi::native_text_field_get_text_alignment(self.handle))
        }
    }

    pub fn set_placeholder(&self, placeholder: Option<&str>) {
        let placeholder_native = placeholder.map(|value| CString::new(value).expect("string argument contains interior nul byte"));
        unsafe {
            cnativeapi::native_text_field_set_placeholder(self.handle, placeholder_native.as_ref().map_or(std::ptr::null(), |value| value.as_ptr()));
        }
    }

    pub fn placeholder(&self) -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_text_field_get_placeholder(self.handle);
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn set_editable(&self, is_editable: bool) {
        unsafe {
            cnativeapi::native_text_field_set_editable(self.handle, is_editable);
        }
    }

    pub fn is_editable(&self) -> bool {
        unsafe {
            cnativeapi::native_text_field_is_editable(self.handle)
        }
    }

    pub fn set_secure(&self, is_secure: bool) {
        unsafe {
            cnativeapi::native_text_field_set_secure(self.handle, is_secure);
        }
    }

    pub fn is_secure(&self) -> bool {
        unsafe {
            cnativeapi::native_text_field_is_secure(self.handle)
        }
    }

    pub fn set_multiline(&self, is_multiline: bool) {
        unsafe {
            cnativeapi::native_text_field_set_multiline(self.handle, is_multiline);
        }
    }

    pub fn is_multiline(&self) -> bool {
        unsafe {
            cnativeapi::native_text_field_is_multiline(self.handle)
        }
    }

}

impl Drop for TextField {
    fn drop(&mut self) {
        if self.handle != 0 {
            unsafe { cnativeapi::native_text_field_free(self.handle) };
        }
    }
}

/// A `TextField` owned elsewhere; using it does not release it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct TextFieldRef(cnativeapi::native_text_field_t);

impl TextFieldRef {
    pub(crate) fn from_raw(handle: cnativeapi::native_text_field_t) -> Self {
        Self(handle)
    }

    pub fn as_raw(&self) -> cnativeapi::native_text_field_t {
        self.0
    }

    /// Runs `f` against the borrowed handle. The `TextField` it receives
    /// must not outlive the call.
    pub fn with<R>(&self, f: impl FnOnce(&TextField) -> R) -> R {
        let borrowed = std::mem::ManuallyDrop::new(TextField { handle: self.0 });
        f(&borrowed)
    }
}

/// Owned handle to a native `ImageView`.
///
/// Derefs to [`View`]: the C ABI resolves this handle as a `View` too, so
/// every `View` method is available and a `&ImageView` coerces to `&View`.
#[derive(Debug)]
#[repr(transparent)]
pub struct ImageView {
    handle: cnativeapi::native_image_view_t,
}

impl std::ops::Deref for ImageView {
    type Target = View;
    fn deref(&self) -> &View {
        // Both are #[repr(transparent)] over the same handle type.
        unsafe { &*(self as *const ImageView as *const View) }
    }
}

impl AsRef<View> for ImageView {
    fn as_ref(&self) -> &View {
        self
    }
}

impl ImageView {
    /// Adopts a handle returned by the C API.
    ///
    /// # Safety
    /// `handle` must be a live handle that is not owned elsewhere.
    pub unsafe fn from_raw(handle: cnativeapi::native_image_view_t) -> Option<Self> {
        if handle == 0 {
            None
        } else {
            Some(Self { handle })
        }
    }

    /// Borrows the underlying C handle.
    pub fn as_raw(&self) -> cnativeapi::native_image_view_t {
        self.handle
    }

    /// Creates a new `ImageView`; returns `None` if the native side failed.
    pub fn new() -> Option<Self> {
        unsafe {
            Self::from_raw(cnativeapi::native_image_view_create())
        }
    }

    pub fn set_image(&self, image: Option<&Image>) {
        unsafe {
            cnativeapi::native_image_view_set_image(self.handle, image.map_or(0, |value| value.as_raw()));
        }
    }

    pub fn image(&self) -> Option<Image> {
        unsafe {
            Image::from_raw(cnativeapi::native_image_view_get_image(self.handle))
        }
    }

}

impl Drop for ImageView {
    fn drop(&mut self) {
        if self.handle != 0 {
            unsafe { cnativeapi::native_image_view_free(self.handle) };
        }
    }
}

/// A `ImageView` owned elsewhere; using it does not release it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ImageViewRef(cnativeapi::native_image_view_t);

impl ImageViewRef {
    pub(crate) fn from_raw(handle: cnativeapi::native_image_view_t) -> Self {
        Self(handle)
    }

    pub fn as_raw(&self) -> cnativeapi::native_image_view_t {
        self.0
    }

    /// Runs `f` against the borrowed handle. The `ImageView` it receives
    /// must not outlive the call.
    pub fn with<R>(&self, f: impl FnOnce(&ImageView) -> R) -> R {
        let borrowed = std::mem::ManuallyDrop::new(ImageView { handle: self.0 });
        f(&borrowed)
    }
}

