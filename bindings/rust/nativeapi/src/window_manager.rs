// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

use crate::geometry::Point;
use crate::window::{Window, WindowEvent, WindowId};

/// Identifies one registered event listener.
pub type ListenerId = cnativeapi::native_listener_id_t;

pub struct WindowManager;

impl WindowManager {
    pub fn get(id: WindowId) -> Option<Window> {
        unsafe {
            Window::from_raw(cnativeapi::native_window_manager_get(id))
        }
    }

    pub fn get_all() -> Vec<Window> {
        unsafe {
            let mut list = cnativeapi::native_window_manager_get_all();
            let mut items = Vec::new();
            if !list.windows.is_null() {
                for index in 0..list.count as isize {
                    if let Some(item) = Window::from_raw(*list.windows.offset(index)) {
                        items.push(item);
                    }
                }
            }
            // Handles are now owned by `items`; drop just the array.
            cnativeapi::native_window_list_release(&mut list);
            items
        }
    }

    pub fn get_current() -> Option<Window> {
        unsafe {
            Window::from_raw(cnativeapi::native_window_manager_get_current())
        }
    }

    pub fn get_window_at_point(point: &Point, excluded_window_id: WindowId) -> Option<Window> {
        let point_raw = point.to_raw();
        unsafe {
            Window::from_raw(cnativeapi::native_window_manager_get_window_at_point(point_raw.raw, excluded_window_id))
        }
    }

    pub fn set_will_show_hook(hook: Option<Box<dyn Fn(u32)>>) {
        unsafe extern "C" fn trampoline(arg0: u32, user_data: *mut std::ffi::c_void) {
            if user_data.is_null() {
                return;
            }
            let callback = &*(user_data as *const std::sync::Arc<dyn Fn(u32)>);
            callback(arg0);
        }
        fn into_user_data(callback: std::sync::Arc<dyn Fn(u32)>) -> *mut std::ffi::c_void {
            Box::into_raw(Box::new(callback)) as *mut std::ffi::c_void
        }
        unsafe extern "C" fn release(user_data: *mut std::ffi::c_void) {
            if !user_data.is_null() {
                drop(Box::from_raw(user_data as *mut std::sync::Arc<dyn Fn(u32)>));
            }
        }
        let hook_user_data = hook
            .map(|value| into_user_data(std::sync::Arc::from(value)))
            .unwrap_or(std::ptr::null_mut());
        unsafe {
            cnativeapi::native_window_manager_set_will_show_hook(if hook_user_data.is_null() { None } else { Some(trampoline) }, hook_user_data, Some(release));
        }
    }

    pub fn set_will_hide_hook(hook: Option<Box<dyn Fn(u32)>>) {
        unsafe extern "C" fn trampoline(arg0: u32, user_data: *mut std::ffi::c_void) {
            if user_data.is_null() {
                return;
            }
            let callback = &*(user_data as *const std::sync::Arc<dyn Fn(u32)>);
            callback(arg0);
        }
        fn into_user_data(callback: std::sync::Arc<dyn Fn(u32)>) -> *mut std::ffi::c_void {
            Box::into_raw(Box::new(callback)) as *mut std::ffi::c_void
        }
        unsafe extern "C" fn release(user_data: *mut std::ffi::c_void) {
            if !user_data.is_null() {
                drop(Box::from_raw(user_data as *mut std::sync::Arc<dyn Fn(u32)>));
            }
        }
        let hook_user_data = hook
            .map(|value| into_user_data(std::sync::Arc::from(value)))
            .unwrap_or(std::ptr::null_mut());
        unsafe {
            cnativeapi::native_window_manager_set_will_hide_hook(if hook_user_data.is_null() { None } else { Some(trampoline) }, hook_user_data, Some(release));
        }
    }

    pub fn has_will_show_hook() -> bool {
        unsafe {
            cnativeapi::native_window_manager_has_will_show_hook()
        }
    }

    pub fn has_will_hide_hook() -> bool {
        unsafe {
            cnativeapi::native_window_manager_has_will_hide_hook()
        }
    }

    pub fn handle_will_show(id: WindowId) {
        unsafe {
            cnativeapi::native_window_manager_handle_will_show(id);
        }
    }

    pub fn handle_will_hide(id: WindowId) {
        unsafe {
            cnativeapi::native_window_manager_handle_will_hide(id);
        }
    }

    pub fn call_original_show(id: WindowId) -> bool {
        unsafe {
            cnativeapi::native_window_manager_call_original_show(id)
        }
    }

    pub fn call_original_hide(id: WindowId) -> bool {
        unsafe {
            cnativeapi::native_window_manager_call_original_hide(id)
        }
    }

    /// Registers `callback` for every `WindowEvent` this `WindowManager` emits.
    ///
    /// The closure is dropped on the main thread once the listener is removed
    /// or its emitter destroyed.
    pub fn add_listener(callback: impl Fn(&WindowEvent) + 'static) -> ListenerId {
        unsafe extern "C" fn trampoline(event: *const cnativeapi::native_window_event_t, user_data: *mut std::ffi::c_void) {
            if event.is_null() || user_data.is_null() {
                return;
            }
            let callback = &*(user_data as *const Box<dyn Fn(&WindowEvent)>);
            if let Some(event) = WindowEvent::from_raw(&*event) {
                callback(&event);
            }
        }
        let boxed: Box<Box<dyn Fn(&WindowEvent)>> = Box::new(Box::new(callback));
        let user_data = Box::into_raw(boxed) as *mut std::ffi::c_void;
        unsafe extern "C" fn release(user_data: *mut std::ffi::c_void) {
            drop(Box::from_raw(user_data as *mut Box<dyn Fn(&WindowEvent)>));
        }
        unsafe { cnativeapi::native_window_manager_add_listener(Some(trampoline), user_data, Some(release)) }
    }

    /// Unregisters a listener. Returns false if unknown.
    pub fn remove_listener(listener_id: ListenerId) -> bool {
        unsafe { cnativeapi::native_window_manager_remove_listener(listener_id) }
    }

}

