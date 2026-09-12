// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

use crate::geometry::Rectangle;
use crate::image::Image;
use crate::menu::Menu;

/// Identifies one registered event listener.
pub type ListenerId = cnativeapi::native_listener_id_t;

pub type TrayIconId = u32;

#[repr(i32)]
#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum ContextMenuTrigger {
    None = 0,
    Clicked = 1,
    RightClicked = 2,
    DoubleClicked = 3,
}

impl ContextMenuTrigger {
    pub(crate) fn from_raw(raw: cnativeapi::native_context_menu_trigger_t) -> Self {
        match raw {
            cnativeapi::NATIVE_CONTEXT_MENU_TRIGGER_NONE => Self::None,
            cnativeapi::NATIVE_CONTEXT_MENU_TRIGGER_CLICKED => Self::Clicked,
            cnativeapi::NATIVE_CONTEXT_MENU_TRIGGER_RIGHT_CLICKED => Self::RightClicked,
            cnativeapi::NATIVE_CONTEXT_MENU_TRIGGER_DOUBLE_CLICKED => Self::DoubleClicked,
            _ => Self::None,
        }
    }

    pub(crate) fn to_raw(self) -> cnativeapi::native_context_menu_trigger_t {
        self as cnativeapi::native_context_menu_trigger_t
    }
}

/// One `TrayIconEvent`, in its concrete form.
#[derive(Debug, Clone, PartialEq)]
pub enum TrayIconEvent {
    Clicked { tray_icon_id: TrayIconId },
    RightClicked { tray_icon_id: TrayIconId },
    DoubleClicked { tray_icon_id: TrayIconId },
}

impl TrayIconEvent {
    pub(crate) unsafe fn from_raw(raw: &cnativeapi::native_tray_icon_event_t) -> Option<Self> {
        Some(match raw.type_ {
            cnativeapi::NATIVE_TRAY_ICON_EVENT_TYPE_CLICKED => Self::Clicked { tray_icon_id: raw.data.clicked.tray_icon_id },
            cnativeapi::NATIVE_TRAY_ICON_EVENT_TYPE_RIGHT_CLICKED => Self::RightClicked { tray_icon_id: raw.data.right_clicked.tray_icon_id },
            cnativeapi::NATIVE_TRAY_ICON_EVENT_TYPE_DOUBLE_CLICKED => Self::DoubleClicked { tray_icon_id: raw.data.double_clicked.tray_icon_id },
            _ => return None,
        })
    }
}

/// Owned handle to a native `TrayIcon`.
#[derive(Debug)]
pub struct TrayIcon {
    handle: cnativeapi::native_tray_icon_t,
}

impl TrayIcon {
    /// Adopts a handle returned by the C API.
    ///
    /// # Safety
    /// `handle` must be a live handle that is not owned elsewhere.
    pub unsafe fn from_raw(handle: cnativeapi::native_tray_icon_t) -> Option<Self> {
        if handle == 0 {
            None
        } else {
            Some(Self { handle })
        }
    }

    /// Borrows the underlying C handle.
    pub fn as_raw(&self) -> cnativeapi::native_tray_icon_t {
        self.handle
    }

    /// Creates a new `TrayIcon`; returns `None` if the native side failed.
    pub fn new() -> Option<Self> {
        unsafe {
            Self::from_raw(cnativeapi::native_tray_icon_create())
        }
    }

    /// Creates a new `TrayIcon`; returns `None` if the native side failed.
    ///
    /// # Safety
    /// Raw pointers must reference valid platform objects of the expected type.
    /// The caller must uphold the native API's thread and lifetime requirements,
    /// including keeping objects alive while the returned wrapper uses them.
    pub unsafe fn with_tray(tray: *mut std::ffi::c_void) -> Option<Self> {
        unsafe {
            Self::from_raw(cnativeapi::native_tray_icon_create_with_tray(tray))
        }
    }

    pub fn get_id(&self) -> TrayIconId {
        unsafe {
            cnativeapi::native_tray_icon_get_id(self.handle)
        }
    }

    pub fn set_icon(&self, image: Option<&Image>) {
        unsafe {
            cnativeapi::native_tray_icon_set_icon(self.handle, image.map_or(0, |value| value.as_raw()));
        }
    }

    pub fn icon(&self) -> Option<Image> {
        unsafe {
            Image::from_raw(cnativeapi::native_tray_icon_get_icon(self.handle))
        }
    }

    pub fn set_title(&self, title: Option<&str>) {
        let title_native = title.map(|value| CString::new(value).expect("string argument contains interior nul byte"));
        unsafe {
            cnativeapi::native_tray_icon_set_title(self.handle, title_native.as_ref().map_or(std::ptr::null(), |value| value.as_ptr()));
        }
    }

    pub fn get_title(&self) -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_tray_icon_get_title(self.handle);
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn set_tooltip(&self, tooltip: Option<&str>) {
        let tooltip_native = tooltip.map(|value| CString::new(value).expect("string argument contains interior nul byte"));
        unsafe {
            cnativeapi::native_tray_icon_set_tooltip(self.handle, tooltip_native.as_ref().map_or(std::ptr::null(), |value| value.as_ptr()));
        }
    }

    pub fn get_tooltip(&self) -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_tray_icon_get_tooltip(self.handle);
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn set_context_menu(&self, menu: Option<&Menu>) {
        unsafe {
            cnativeapi::native_tray_icon_set_context_menu(self.handle, menu.map_or(0, |value| value.as_raw()));
        }
    }

    pub fn get_context_menu(&self) -> Option<Menu> {
        unsafe {
            Menu::from_raw(cnativeapi::native_tray_icon_get_context_menu(self.handle))
        }
    }

    pub fn set_context_menu_trigger(&self, trigger: ContextMenuTrigger) {
        unsafe {
            cnativeapi::native_tray_icon_set_context_menu_trigger(self.handle, trigger.to_raw());
        }
    }

    pub fn get_context_menu_trigger(&self) -> ContextMenuTrigger {
        unsafe {
            ContextMenuTrigger::from_raw(cnativeapi::native_tray_icon_get_context_menu_trigger(self.handle))
        }
    }

    pub fn get_bounds(&self) -> Rectangle {
        unsafe {
            let raw = cnativeapi::native_tray_icon_get_bounds(self.handle);
            Rectangle::from_raw(&raw)
        }
    }

    pub fn set_visible(&self, visible: bool) -> bool {
        unsafe {
            cnativeapi::native_tray_icon_set_visible(self.handle, visible)
        }
    }

    pub fn is_visible(&self) -> bool {
        unsafe {
            cnativeapi::native_tray_icon_is_visible(self.handle)
        }
    }

    pub fn open_context_menu(&self) -> bool {
        unsafe {
            cnativeapi::native_tray_icon_open_context_menu(self.handle)
        }
    }

    pub fn close_context_menu(&self) -> bool {
        unsafe {
            cnativeapi::native_tray_icon_close_context_menu(self.handle)
        }
    }

    /// Platform-specific native object behind this handle.
    pub fn native_object(&self) -> *mut std::ffi::c_void {
        unsafe { cnativeapi::native_tray_icon_get_native_object(self.handle) }
    }

    /// Registers `callback` for every `TrayIconEvent` this `TrayIcon` emits.
    ///
    /// The closure is leaked: the C ABI takes a `user_data` pointer but
    /// offers no hook to reclaim it, so removing the listener stops the
    /// calls without freeing the closure.
    pub fn add_listener(&self, callback: impl Fn(&TrayIconEvent) + 'static) -> ListenerId {
        unsafe extern "C" fn trampoline(event: *const cnativeapi::native_tray_icon_event_t, user_data: *mut std::ffi::c_void) {
            if event.is_null() || user_data.is_null() {
                return;
            }
            let callback = &*(user_data as *const Box<dyn Fn(&TrayIconEvent)>);
            if let Some(event) = TrayIconEvent::from_raw(&*event) {
                callback(&event);
            }
        }
        let boxed: Box<Box<dyn Fn(&TrayIconEvent)>> = Box::new(Box::new(callback));
        let user_data = Box::into_raw(boxed) as *mut std::ffi::c_void;
        unsafe { cnativeapi::native_tray_icon_add_listener(self.handle, Some(trampoline), user_data) }
    }

    /// Unregisters a listener. Returns false if unknown.
    pub fn remove_listener(&self, listener_id: ListenerId) -> bool {
        unsafe { cnativeapi::native_tray_icon_remove_listener(self.handle, listener_id) }
    }

}

impl Drop for TrayIcon {
    fn drop(&mut self) {
        if self.handle != 0 {
            unsafe { cnativeapi::native_tray_icon_free(self.handle) };
        }
    }
}

/// A `TrayIcon` owned elsewhere; using it does not release it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct TrayIconRef(cnativeapi::native_tray_icon_t);

impl TrayIconRef {
    pub(crate) fn from_raw(handle: cnativeapi::native_tray_icon_t) -> Self {
        Self(handle)
    }

    pub fn as_raw(&self) -> cnativeapi::native_tray_icon_t {
        self.0
    }

    /// Runs `f` against the borrowed handle. The `TrayIcon` it receives
    /// must not outlive the call.
    pub fn with<R>(&self, f: impl FnOnce(&TrayIcon) -> R) -> R {
        let borrowed = std::mem::ManuallyDrop::new(TrayIcon { handle: self.0 });
        f(&borrowed)
    }
}

