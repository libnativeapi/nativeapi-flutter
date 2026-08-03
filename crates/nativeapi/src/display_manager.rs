// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

use crate::display::{Display, DisplayEvent};
use crate::geometry::Point;

/// Identifies one registered event listener.
pub type ListenerId = cnativeapi::native_listener_id_t;

pub struct DisplayManager;

impl DisplayManager {
    pub fn get_all() -> Vec<Display> {
        unsafe {
            let mut list = cnativeapi::native_display_manager_get_all();
            let mut items = Vec::new();
            if !list.displays.is_null() {
                for index in 0..list.count as isize {
                    if let Some(item) = Display::from_raw(*list.displays.offset(index)) {
                        items.push(item);
                    }
                }
            }
            // Handles are now owned by `items`; drop just the array.
            cnativeapi::native_display_list_release(&mut list);
            items
        }
    }

    pub fn get_primary() -> Option<Display> {
        unsafe {
            Display::from_raw(cnativeapi::native_display_manager_get_primary())
        }
    }

    pub fn get_cursor_position() -> Point {
        unsafe {
            let raw = cnativeapi::native_display_manager_get_cursor_position();
            Point::from_raw(&raw)
        }
    }

    /// Registers `callback` for every `DisplayEvent` this `DisplayManager` emits.
    ///
    /// The closure is leaked: the C ABI takes a `user_data` pointer but
    /// offers no hook to reclaim it, so removing the listener stops the
    /// calls without freeing the closure.
    pub fn add_listener(callback: impl Fn(&DisplayEvent) + 'static) -> ListenerId {
        unsafe extern "C" fn trampoline(event: *const cnativeapi::native_display_event_t, user_data: *mut std::ffi::c_void) {
            if event.is_null() || user_data.is_null() {
                return;
            }
            let callback = &*(user_data as *const Box<dyn Fn(&DisplayEvent)>);
            if let Some(event) = DisplayEvent::from_raw(&*event) {
                callback(&event);
            }
        }
        let boxed: Box<Box<dyn Fn(&DisplayEvent)>> = Box::new(Box::new(callback));
        let user_data = Box::into_raw(boxed) as *mut std::ffi::c_void;
        unsafe { cnativeapi::native_display_manager_add_listener(Some(trampoline), user_data) }
    }

    /// Unregisters a listener. Returns false if unknown.
    pub fn remove_listener(listener_id: ListenerId) -> bool {
        unsafe { cnativeapi::native_display_manager_remove_listener(listener_id) }
    }

}

