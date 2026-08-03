// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

use crate::image::Image;
use crate::keyboard::KeyboardAccelerator;
use crate::placement::Placement;
use crate::positioning_strategy::PositioningStrategy;

/// Identifies one registered event listener.
pub type ListenerId = cnativeapi::native_listener_id_t;

pub type MenuId = u32;

pub type MenuItemId = u32;

#[repr(i32)]
#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum MenuItemType {
    Normal = 0,
    Checkbox = 1,
    Radio = 2,
    Separator = 3,
    Submenu = 4,
}

impl MenuItemType {
    pub(crate) fn from_raw(raw: cnativeapi::native_menu_item_type_t) -> Self {
        match raw {
            cnativeapi::NATIVE_MENU_ITEM_TYPE_NORMAL => Self::Normal,
            cnativeapi::NATIVE_MENU_ITEM_TYPE_CHECKBOX => Self::Checkbox,
            cnativeapi::NATIVE_MENU_ITEM_TYPE_RADIO => Self::Radio,
            cnativeapi::NATIVE_MENU_ITEM_TYPE_SEPARATOR => Self::Separator,
            cnativeapi::NATIVE_MENU_ITEM_TYPE_SUBMENU => Self::Submenu,
            _ => Self::Normal,
        }
    }

    pub(crate) fn to_raw(self) -> cnativeapi::native_menu_item_type_t {
        self as cnativeapi::native_menu_item_type_t
    }
}

#[repr(i32)]
#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum MenuItemState {
    Unchecked = 0,
    Checked = 1,
    Mixed = 2,
}

impl MenuItemState {
    pub(crate) fn from_raw(raw: cnativeapi::native_menu_item_state_t) -> Self {
        match raw {
            cnativeapi::NATIVE_MENU_ITEM_STATE_UNCHECKED => Self::Unchecked,
            cnativeapi::NATIVE_MENU_ITEM_STATE_CHECKED => Self::Checked,
            cnativeapi::NATIVE_MENU_ITEM_STATE_MIXED => Self::Mixed,
            _ => Self::Unchecked,
        }
    }

    pub(crate) fn to_raw(self) -> cnativeapi::native_menu_item_state_t {
        self as cnativeapi::native_menu_item_state_t
    }
}

/// One `MenuEvent`, in its concrete form.
#[derive(Debug, Clone, PartialEq)]
pub enum MenuEvent {
    Opened { menu_id: MenuId },
    Closed { menu_id: MenuId },
    ItemClicked { item_id: MenuItemId },
    ItemSubmenuOpened { item_id: MenuItemId },
    ItemSubmenuClosed { item_id: MenuItemId },
}

impl MenuEvent {
    pub(crate) unsafe fn from_raw(raw: &cnativeapi::native_menu_event_t) -> Option<Self> {
        Some(match raw.type_ {
            cnativeapi::NATIVE_MENU_EVENT_TYPE_OPENED => Self::Opened { menu_id: raw.data.opened.menu_id },
            cnativeapi::NATIVE_MENU_EVENT_TYPE_CLOSED => Self::Closed { menu_id: raw.data.closed.menu_id },
            cnativeapi::NATIVE_MENU_EVENT_TYPE_ITEM_CLICKED => Self::ItemClicked { item_id: raw.data.item_clicked.item_id },
            cnativeapi::NATIVE_MENU_EVENT_TYPE_ITEM_SUBMENU_OPENED => Self::ItemSubmenuOpened { item_id: raw.data.item_submenu_opened.item_id },
            cnativeapi::NATIVE_MENU_EVENT_TYPE_ITEM_SUBMENU_CLOSED => Self::ItemSubmenuClosed { item_id: raw.data.item_submenu_closed.item_id },
            _ => return None,
        })
    }
}

/// Owned handle to a native `MenuItem`.
#[derive(Debug)]
pub struct MenuItem {
    handle: cnativeapi::native_menu_item_t,
}

impl MenuItem {
    /// Adopts a handle returned by the C API.
    ///
    /// # Safety
    /// `handle` must be a live handle that is not owned elsewhere.
    pub unsafe fn from_raw(handle: cnativeapi::native_menu_item_t) -> Option<Self> {
        if handle == 0 {
            None
        } else {
            Some(Self { handle })
        }
    }

    /// Borrows the underlying C handle.
    pub fn as_raw(&self) -> cnativeapi::native_menu_item_t {
        self.handle
    }

    /// Creates a new `MenuItem`; returns `None` if the native side failed.
    pub fn with_label_and_type(label: &str, r#type: MenuItemType) -> Option<Self> {
        let label_native = CString::new(label).expect("string argument contains interior nul byte");
        unsafe {
            Self::from_raw(cnativeapi::native_menu_item_create_with_label_and_type(label_native.as_ptr(), r#type.to_raw()))
        }
    }

    /// Creates a new `MenuItem`; returns `None` if the native side failed.
    pub fn with_native_item(native_item: *mut std::ffi::c_void) -> Option<Self> {
        unsafe {
            Self::from_raw(cnativeapi::native_menu_item_create_with_native_item(native_item))
        }
    }

    pub fn id(&self) -> MenuItemId {
        unsafe {
            cnativeapi::native_menu_item_get_id(self.handle)
        }
    }

    pub fn r#type(&self) -> MenuItemType {
        unsafe {
            MenuItemType::from_raw(cnativeapi::native_menu_item_get_type(self.handle))
        }
    }

    pub fn set_label(&self, label: Option<&str>) {
        let label_native = label.map(|value| CString::new(value).expect("string argument contains interior nul byte"));
        unsafe {
            cnativeapi::native_menu_item_set_label(self.handle, label_native.as_ref().map_or(std::ptr::null(), |value| value.as_ptr()));
        }
    }

    pub fn label(&self) -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_menu_item_get_label(self.handle);
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn set_icon(&self, image: &Image) {
        unsafe {
            cnativeapi::native_menu_item_set_icon(self.handle, image.as_raw());
        }
    }

    pub fn icon(&self) -> Option<Image> {
        unsafe {
            Image::from_raw(cnativeapi::native_menu_item_get_icon(self.handle))
        }
    }

    pub fn set_tooltip(&self, tooltip: Option<&str>) {
        let tooltip_native = tooltip.map(|value| CString::new(value).expect("string argument contains interior nul byte"));
        unsafe {
            cnativeapi::native_menu_item_set_tooltip(self.handle, tooltip_native.as_ref().map_or(std::ptr::null(), |value| value.as_ptr()));
        }
    }

    pub fn tooltip(&self) -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_menu_item_get_tooltip(self.handle);
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn set_accelerator(&self, accelerator: Option<&KeyboardAccelerator>) {
        let accelerator_raw = accelerator.map(|value| value.to_raw());
        unsafe {
            cnativeapi::native_menu_item_set_accelerator(self.handle, accelerator_raw.as_ref().map_or(std::ptr::null(), |value| &value.raw as *const _));
        }
    }

    pub fn accelerator(&self) -> KeyboardAccelerator {
        unsafe {
            let raw = cnativeapi::native_menu_item_get_accelerator(self.handle);
            KeyboardAccelerator::from_raw(&raw)
        }
    }

    pub fn set_enabled(&self, enabled: bool) {
        unsafe {
            cnativeapi::native_menu_item_set_enabled(self.handle, enabled);
        }
    }

    pub fn is_enabled(&self) -> bool {
        unsafe {
            cnativeapi::native_menu_item_is_enabled(self.handle)
        }
    }

    pub fn set_state(&self, state: MenuItemState) {
        unsafe {
            cnativeapi::native_menu_item_set_state(self.handle, state.to_raw());
        }
    }

    pub fn state(&self) -> MenuItemState {
        unsafe {
            MenuItemState::from_raw(cnativeapi::native_menu_item_get_state(self.handle))
        }
    }

    pub fn set_radio_group(&self, group_id: i32) {
        unsafe {
            cnativeapi::native_menu_item_set_radio_group(self.handle, group_id);
        }
    }

    pub fn radio_group(&self) -> i32 {
        unsafe {
            cnativeapi::native_menu_item_get_radio_group(self.handle)
        }
    }

    pub fn set_submenu(&self, submenu: &Menu) {
        unsafe {
            cnativeapi::native_menu_item_set_submenu(self.handle, submenu.as_raw());
        }
    }

    pub fn submenu(&self) -> Option<Menu> {
        unsafe {
            Menu::from_raw(cnativeapi::native_menu_item_get_submenu(self.handle))
        }
    }

    /// Platform-specific native object behind this handle.
    pub fn native_object(&self) -> *mut std::ffi::c_void {
        unsafe { cnativeapi::native_menu_item_get_native_object(self.handle) }
    }

    /// Registers `callback` for every `MenuEvent` this `MenuItem` emits.
    ///
    /// The closure is leaked: the C ABI takes a `user_data` pointer but
    /// offers no hook to reclaim it, so removing the listener stops the
    /// calls without freeing the closure.
    pub fn add_listener(&self, callback: impl Fn(&MenuEvent) + 'static) -> ListenerId {
        unsafe extern "C" fn trampoline(event: *const cnativeapi::native_menu_event_t, user_data: *mut std::ffi::c_void) {
            if event.is_null() || user_data.is_null() {
                return;
            }
            let callback = &*(user_data as *const Box<dyn Fn(&MenuEvent)>);
            if let Some(event) = MenuEvent::from_raw(&*event) {
                callback(&event);
            }
        }
        let boxed: Box<Box<dyn Fn(&MenuEvent)>> = Box::new(Box::new(callback));
        let user_data = Box::into_raw(boxed) as *mut std::ffi::c_void;
        unsafe { cnativeapi::native_menu_item_add_listener(self.handle, Some(trampoline), user_data) }
    }

    /// Unregisters a listener. Returns false if unknown.
    pub fn remove_listener(&self, listener_id: ListenerId) -> bool {
        unsafe { cnativeapi::native_menu_item_remove_listener(self.handle, listener_id) }
    }

}

impl Drop for MenuItem {
    fn drop(&mut self) {
        if self.handle != 0 {
            unsafe { cnativeapi::native_menu_item_free(self.handle) };
        }
    }
}

/// A `MenuItem` owned elsewhere; using it does not release it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct MenuItemRef(cnativeapi::native_menu_item_t);

impl MenuItemRef {
    pub(crate) fn from_raw(handle: cnativeapi::native_menu_item_t) -> Self {
        Self(handle)
    }

    pub fn as_raw(&self) -> cnativeapi::native_menu_item_t {
        self.0
    }

    /// Runs `f` against the borrowed handle. The `MenuItem` it receives
    /// must not outlive the call.
    pub fn with<R>(&self, f: impl FnOnce(&MenuItem) -> R) -> R {
        let borrowed = std::mem::ManuallyDrop::new(MenuItem { handle: self.0 });
        f(&borrowed)
    }
}

/// Owned handle to a native `Menu`.
#[derive(Debug)]
pub struct Menu {
    handle: cnativeapi::native_menu_t,
}

impl Menu {
    /// Adopts a handle returned by the C API.
    ///
    /// # Safety
    /// `handle` must be a live handle that is not owned elsewhere.
    pub unsafe fn from_raw(handle: cnativeapi::native_menu_t) -> Option<Self> {
        if handle == 0 {
            None
        } else {
            Some(Self { handle })
        }
    }

    /// Borrows the underlying C handle.
    pub fn as_raw(&self) -> cnativeapi::native_menu_t {
        self.handle
    }

    /// Creates a new `Menu`; returns `None` if the native side failed.
    pub fn new() -> Option<Self> {
        unsafe {
            Self::from_raw(cnativeapi::native_menu_create())
        }
    }

    /// Creates a new `Menu`; returns `None` if the native side failed.
    pub fn with_native_menu(native_menu: *mut std::ffi::c_void) -> Option<Self> {
        unsafe {
            Self::from_raw(cnativeapi::native_menu_create_with_native_menu(native_menu))
        }
    }

    pub fn id(&self) -> MenuId {
        unsafe {
            cnativeapi::native_menu_get_id(self.handle)
        }
    }

    pub fn add_item(&self, item: &MenuItem) {
        unsafe {
            cnativeapi::native_menu_add_item(self.handle, item.as_raw());
        }
    }

    pub fn insert_item(&self, index: std::os::raw::c_ulong, item: &MenuItem) {
        unsafe {
            cnativeapi::native_menu_insert_item(self.handle, index, item.as_raw());
        }
    }

    pub fn remove_item(&self, item: &MenuItem) -> bool {
        unsafe {
            cnativeapi::native_menu_remove_item(self.handle, item.as_raw())
        }
    }

    pub fn remove_item_by_id(&self, item_id: MenuItemId) -> bool {
        unsafe {
            cnativeapi::native_menu_remove_item_by_id(self.handle, item_id)
        }
    }

    pub fn remove_item_at(&self, index: std::os::raw::c_ulong) -> bool {
        unsafe {
            cnativeapi::native_menu_remove_item_at(self.handle, index)
        }
    }

    pub fn clear(&self) {
        unsafe {
            cnativeapi::native_menu_clear(self.handle);
        }
    }

    pub fn add_separator(&self) {
        unsafe {
            cnativeapi::native_menu_add_separator(self.handle);
        }
    }

    pub fn insert_separator(&self, index: std::os::raw::c_ulong) {
        unsafe {
            cnativeapi::native_menu_insert_separator(self.handle, index);
        }
    }

    pub fn item_count(&self) -> std::os::raw::c_ulong {
        unsafe {
            cnativeapi::native_menu_get_item_count(self.handle)
        }
    }

    pub fn get_item_at(&self, index: std::os::raw::c_ulong) -> Option<MenuItem> {
        unsafe {
            MenuItem::from_raw(cnativeapi::native_menu_get_item_at(self.handle, index))
        }
    }

    pub fn get_item_by_id(&self, item_id: MenuItemId) -> Option<MenuItem> {
        unsafe {
            MenuItem::from_raw(cnativeapi::native_menu_get_item_by_id(self.handle, item_id))
        }
    }

    pub fn all_items(&self) -> Vec<MenuItem> {
        unsafe {
            let mut list = cnativeapi::native_menu_get_all_items(self.handle);
            let mut items = Vec::new();
            if !list.menu_items.is_null() {
                for index in 0..list.count as isize {
                    if let Some(item) = MenuItem::from_raw(*list.menu_items.offset(index)) {
                        items.push(item);
                    }
                }
            }
            // Handles are now owned by `items`; drop just the array.
            cnativeapi::native_menu_item_list_release(&mut list);
            items
        }
    }

    pub fn open(&self, strategy: &PositioningStrategy, placement: Placement) -> bool {
        unsafe {
            cnativeapi::native_menu_open(self.handle, strategy.as_raw(), placement.to_raw())
        }
    }

    pub fn close(&self) -> bool {
        unsafe {
            cnativeapi::native_menu_close(self.handle)
        }
    }

    /// Platform-specific native object behind this handle.
    pub fn native_object(&self) -> *mut std::ffi::c_void {
        unsafe { cnativeapi::native_menu_get_native_object(self.handle) }
    }

    /// Registers `callback` for every `MenuEvent` this `Menu` emits.
    ///
    /// The closure is leaked: the C ABI takes a `user_data` pointer but
    /// offers no hook to reclaim it, so removing the listener stops the
    /// calls without freeing the closure.
    pub fn add_listener(&self, callback: impl Fn(&MenuEvent) + 'static) -> ListenerId {
        unsafe extern "C" fn trampoline(event: *const cnativeapi::native_menu_event_t, user_data: *mut std::ffi::c_void) {
            if event.is_null() || user_data.is_null() {
                return;
            }
            let callback = &*(user_data as *const Box<dyn Fn(&MenuEvent)>);
            if let Some(event) = MenuEvent::from_raw(&*event) {
                callback(&event);
            }
        }
        let boxed: Box<Box<dyn Fn(&MenuEvent)>> = Box::new(Box::new(callback));
        let user_data = Box::into_raw(boxed) as *mut std::ffi::c_void;
        unsafe { cnativeapi::native_menu_add_listener(self.handle, Some(trampoline), user_data) }
    }

    /// Unregisters a listener. Returns false if unknown.
    pub fn remove_listener(&self, listener_id: ListenerId) -> bool {
        unsafe { cnativeapi::native_menu_remove_listener(self.handle, listener_id) }
    }

}

impl Drop for Menu {
    fn drop(&mut self) {
        if self.handle != 0 {
            unsafe { cnativeapi::native_menu_free(self.handle) };
        }
    }
}

/// A `Menu` owned elsewhere; using it does not release it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct MenuRef(cnativeapi::native_menu_t);

impl MenuRef {
    pub(crate) fn from_raw(handle: cnativeapi::native_menu_t) -> Self {
        Self(handle)
    }

    pub fn as_raw(&self) -> cnativeapi::native_menu_t {
        self.0
    }

    /// Runs `f` against the borrowed handle. The `Menu` it receives
    /// must not outlive the call.
    pub fn with<R>(&self, f: impl FnOnce(&Menu) -> R) -> R {
        let borrowed = std::mem::ManuallyDrop::new(Menu { handle: self.0 });
        f(&borrowed)
    }
}

