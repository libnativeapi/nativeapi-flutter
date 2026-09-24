// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

/// Identifies one registered event listener.
pub type ListenerId = cnativeapi::native_listener_id_t;

/// One `NotificationEvent`, in its concrete form.
#[derive(Debug, Clone, PartialEq)]
pub enum NotificationEvent {
    Activated { argument: Option<String> },
}

impl NotificationEvent {
    pub(crate) unsafe fn from_raw(raw: &cnativeapi::native_notification_event_t) -> Option<Self> {
        Some(match raw.type_ {
            cnativeapi::NATIVE_NOTIFICATION_EVENT_TYPE_ACTIVATED => Self::Activated { argument: if raw.data.activated.argument.is_null() { None } else { Some(CStr::from_ptr(raw.data.activated.argument).to_string_lossy().into_owned()) } },
            _ => return None,
        })
    }
}

pub struct NotificationManager;

impl NotificationManager {
    pub fn is_supported() -> bool {
        unsafe {
            cnativeapi::native_notification_manager_is_supported()
        }
    }

    pub fn initialize() -> bool {
        unsafe {
            cnativeapi::native_notification_manager_initialize()
        }
    }

    pub fn shutdown() {
        unsafe {
            cnativeapi::native_notification_manager_shutdown();
        }
    }

    pub fn show(title: &str, message: &str, tag: &str, button_label: &str) -> bool {
        let title_native = CString::new(title).expect("string argument contains interior nul byte");
        let message_native = CString::new(message).expect("string argument contains interior nul byte");
        let tag_native = CString::new(tag).expect("string argument contains interior nul byte");
        let button_label_native = CString::new(button_label).expect("string argument contains interior nul byte");
        unsafe {
            cnativeapi::native_notification_manager_show(title_native.as_ptr(), message_native.as_ptr(), tag_native.as_ptr(), button_label_native.as_ptr())
        }
    }

    pub fn remove(tag: &str) -> bool {
        let tag_native = CString::new(tag).expect("string argument contains interior nul byte");
        unsafe {
            cnativeapi::native_notification_manager_remove(tag_native.as_ptr())
        }
    }

    pub fn get_last_error() -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_notification_manager_get_last_error();
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    /// Registers `callback` for every `NotificationEvent` this `NotificationManager` emits.
    ///
    /// The closure is leaked: the C ABI takes a `user_data` pointer but
    /// offers no hook to reclaim it, so removing the listener stops the
    /// calls without freeing the closure.
    pub fn add_listener(callback: impl Fn(&NotificationEvent) + 'static) -> ListenerId {
        unsafe extern "C" fn trampoline(event: *const cnativeapi::native_notification_event_t, user_data: *mut std::ffi::c_void) {
            if event.is_null() || user_data.is_null() {
                return;
            }
            let callback = &*(user_data as *const Box<dyn Fn(&NotificationEvent)>);
            if let Some(event) = NotificationEvent::from_raw(&*event) {
                callback(&event);
            }
        }
        let boxed: Box<Box<dyn Fn(&NotificationEvent)>> = Box::new(Box::new(callback));
        let user_data = Box::into_raw(boxed) as *mut std::ffi::c_void;
        unsafe { cnativeapi::native_notification_manager_add_listener(Some(trampoline), user_data) }
    }

    /// Unregisters a listener. Returns false if unknown.
    pub fn remove_listener(listener_id: ListenerId) -> bool {
        unsafe { cnativeapi::native_notification_manager_remove_listener(listener_id) }
    }

}

