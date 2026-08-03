// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

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

    pub fn set_will_show_hook(hook: Option<Box<dyn Fn(u32)>>) {
        unsafe extern "C" fn trampoline(arg0: u32, user_data: *mut std::ffi::c_void) {
            if user_data.is_null() {
                return;
            }
            let callback = &*(user_data as *const std::sync::Arc<dyn Fn(u32)>);
            callback(arg0);
        }
        fn leak_callback(callback: std::sync::Arc<dyn Fn(u32)>) -> *mut std::ffi::c_void {
            // The C ABI keeps the pointer but offers no hook to reclaim it.
            Box::into_raw(Box::new(callback)) as *mut std::ffi::c_void
        }
        let hook_user_data = hook
            .map(|value| leak_callback(std::sync::Arc::from(value)))
            .unwrap_or(std::ptr::null_mut());
        unsafe {
            cnativeapi::native_window_manager_set_will_show_hook(if hook_user_data.is_null() { None } else { Some(trampoline) }, hook_user_data);
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
        fn leak_callback(callback: std::sync::Arc<dyn Fn(u32)>) -> *mut std::ffi::c_void {
            // The C ABI keeps the pointer but offers no hook to reclaim it.
            Box::into_raw(Box::new(callback)) as *mut std::ffi::c_void
        }
        let hook_user_data = hook
            .map(|value| leak_callback(std::sync::Arc::from(value)))
            .unwrap_or(std::ptr::null_mut());
        unsafe {
            cnativeapi::native_window_manager_set_will_hide_hook(if hook_user_data.is_null() { None } else { Some(trampoline) }, hook_user_data);
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
    /// The closure is leaked: the C ABI takes a `user_data` pointer but
    /// offers no hook to reclaim it, so removing the listener stops the
    /// calls without freeing the closure.
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
        unsafe { cnativeapi::native_window_manager_add_listener(Some(trampoline), user_data) }
    }

    /// Unregisters a listener. Returns false if unknown.
    pub fn remove_listener(listener_id: ListenerId) -> bool {
        unsafe { cnativeapi::native_window_manager_remove_listener(listener_id) }
    }

}

