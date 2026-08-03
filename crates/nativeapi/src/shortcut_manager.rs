// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

use crate::shortcut::{Shortcut, ShortcutEvent, ShortcutId, ShortcutOptions, ShortcutScope};

/// Identifies one registered event listener.
pub type ListenerId = cnativeapi::native_listener_id_t;

pub struct ShortcutManager;

impl ShortcutManager {
    pub fn is_supported() -> bool {
        unsafe {
            cnativeapi::native_shortcut_manager_is_supported()
        }
    }

    pub fn register_with_accelerator_and_callback(accelerator: &str, callback: impl Fn() + 'static) -> Option<Shortcut> {
        let accelerator_native = CString::new(accelerator).expect("string argument contains interior nul byte");
        unsafe extern "C" fn trampoline(user_data: *mut std::ffi::c_void) {
            if user_data.is_null() {
                return;
            }
            let callback = &*(user_data as *const std::sync::Arc<dyn Fn()>);
            callback();
        }
        fn leak_callback(callback: std::sync::Arc<dyn Fn()>) -> *mut std::ffi::c_void {
            // The C ABI keeps the pointer but offers no hook to reclaim it.
            Box::into_raw(Box::new(callback)) as *mut std::ffi::c_void
        }
        let callback_user_data = leak_callback(std::sync::Arc::new(callback));
        unsafe {
            Shortcut::from_raw(cnativeapi::native_shortcut_manager_register_with_accelerator_and_callback(accelerator_native.as_ptr(), Some(trampoline), callback_user_data))
        }
    }

    pub fn register_with_options(options: &ShortcutOptions) -> Option<Shortcut> {
        let options_raw = options.to_raw();
        unsafe {
            Shortcut::from_raw(cnativeapi::native_shortcut_manager_register_with_options(options_raw.raw))
        }
    }

    pub fn unregister_with_id(id: ShortcutId) -> bool {
        unsafe {
            cnativeapi::native_shortcut_manager_unregister_with_id(id)
        }
    }

    pub fn unregister_with_accelerator(accelerator: &str) -> bool {
        let accelerator_native = CString::new(accelerator).expect("string argument contains interior nul byte");
        unsafe {
            cnativeapi::native_shortcut_manager_unregister_with_accelerator(accelerator_native.as_ptr())
        }
    }

    pub fn unregister_all() -> i32 {
        unsafe {
            cnativeapi::native_shortcut_manager_unregister_all()
        }
    }

    pub fn get_with_id(id: ShortcutId) -> Option<Shortcut> {
        unsafe {
            Shortcut::from_raw(cnativeapi::native_shortcut_manager_get_with_id(id))
        }
    }

    pub fn get_with_accelerator(accelerator: &str) -> Option<Shortcut> {
        let accelerator_native = CString::new(accelerator).expect("string argument contains interior nul byte");
        unsafe {
            Shortcut::from_raw(cnativeapi::native_shortcut_manager_get_with_accelerator(accelerator_native.as_ptr()))
        }
    }

    pub fn get_all() -> Vec<Shortcut> {
        unsafe {
            let mut list = cnativeapi::native_shortcut_manager_get_all();
            let mut items = Vec::new();
            if !list.shortcuts.is_null() {
                for index in 0..list.count as isize {
                    if let Some(item) = Shortcut::from_raw(*list.shortcuts.offset(index)) {
                        items.push(item);
                    }
                }
            }
            // Handles are now owned by `items`; drop just the array.
            cnativeapi::native_shortcut_list_release(&mut list);
            items
        }
    }

    pub fn get_by_scope(scope: ShortcutScope) -> Vec<Shortcut> {
        unsafe {
            let mut list = cnativeapi::native_shortcut_manager_get_by_scope(scope.to_raw());
            let mut items = Vec::new();
            if !list.shortcuts.is_null() {
                for index in 0..list.count as isize {
                    if let Some(item) = Shortcut::from_raw(*list.shortcuts.offset(index)) {
                        items.push(item);
                    }
                }
            }
            // Handles are now owned by `items`; drop just the array.
            cnativeapi::native_shortcut_list_release(&mut list);
            items
        }
    }

    pub fn is_available(accelerator: &str) -> bool {
        let accelerator_native = CString::new(accelerator).expect("string argument contains interior nul byte");
        unsafe {
            cnativeapi::native_shortcut_manager_is_available(accelerator_native.as_ptr())
        }
    }

    pub fn is_valid_accelerator(accelerator: &str) -> bool {
        let accelerator_native = CString::new(accelerator).expect("string argument contains interior nul byte");
        unsafe {
            cnativeapi::native_shortcut_manager_is_valid_accelerator(accelerator_native.as_ptr())
        }
    }

    pub fn set_enabled(enabled: bool) {
        unsafe {
            cnativeapi::native_shortcut_manager_set_enabled(enabled);
        }
    }

    pub fn is_enabled() -> bool {
        unsafe {
            cnativeapi::native_shortcut_manager_is_enabled()
        }
    }

    pub fn emit_shortcut_activated(id: ShortcutId, accelerator: &str) {
        let accelerator_native = CString::new(accelerator).expect("string argument contains interior nul byte");
        unsafe {
            cnativeapi::native_shortcut_manager_emit_shortcut_activated(id, accelerator_native.as_ptr());
        }
    }

    /// Registers `callback` for every `ShortcutEvent` this `ShortcutManager` emits.
    ///
    /// The closure is leaked: the C ABI takes a `user_data` pointer but
    /// offers no hook to reclaim it, so removing the listener stops the
    /// calls without freeing the closure.
    pub fn add_listener(callback: impl Fn(&ShortcutEvent) + 'static) -> ListenerId {
        unsafe extern "C" fn trampoline(event: *const cnativeapi::native_shortcut_event_t, user_data: *mut std::ffi::c_void) {
            if event.is_null() || user_data.is_null() {
                return;
            }
            let callback = &*(user_data as *const Box<dyn Fn(&ShortcutEvent)>);
            if let Some(event) = ShortcutEvent::from_raw(&*event) {
                callback(&event);
            }
        }
        let boxed: Box<Box<dyn Fn(&ShortcutEvent)>> = Box::new(Box::new(callback));
        let user_data = Box::into_raw(boxed) as *mut std::ffi::c_void;
        unsafe { cnativeapi::native_shortcut_manager_add_listener(Some(trampoline), user_data) }
    }

    /// Unregisters a listener. Returns false if unknown.
    pub fn remove_listener(listener_id: ListenerId) -> bool {
        unsafe { cnativeapi::native_shortcut_manager_remove_listener(listener_id) }
    }

}

