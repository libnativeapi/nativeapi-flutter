// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

use crate::menu::Menu;
use crate::window::Window;

/// Identifies one registered event listener.
pub type ListenerId = cnativeapi::native_listener_id_t;

/// One `ApplicationEvent`, in its concrete form.
#[derive(Debug, Clone, PartialEq)]
pub enum ApplicationEvent {
    Started,
    Exiting { exit_code: i32 },
    Activated,
    Deactivated,
    QuitRequested,
}

impl ApplicationEvent {
    pub(crate) unsafe fn from_raw(raw: &cnativeapi::native_application_event_t) -> Option<Self> {
        Some(match raw.type_ {
            cnativeapi::NATIVE_APPLICATION_EVENT_TYPE_STARTED => Self::Started,
            cnativeapi::NATIVE_APPLICATION_EVENT_TYPE_EXITING => Self::Exiting { exit_code: raw.data.exiting.exit_code },
            cnativeapi::NATIVE_APPLICATION_EVENT_TYPE_ACTIVATED => Self::Activated,
            cnativeapi::NATIVE_APPLICATION_EVENT_TYPE_DEACTIVATED => Self::Deactivated,
            cnativeapi::NATIVE_APPLICATION_EVENT_TYPE_QUIT_REQUESTED => Self::QuitRequested,
            _ => return None,
        })
    }
}

pub struct Application;

impl Application {
    pub fn run() -> i32 {
        unsafe {
            cnativeapi::native_application_run()
        }
    }

    pub fn run_with_window(window: &Window) -> i32 {
        unsafe {
            cnativeapi::native_application_run_with_window(window.as_raw())
        }
    }

    pub fn quit(exit_code: i32) {
        unsafe {
            cnativeapi::native_application_quit(exit_code);
        }
    }

    pub fn is_running() -> bool {
        unsafe {
            cnativeapi::native_application_is_running()
        }
    }

    pub fn is_single_instance() -> bool {
        unsafe {
            cnativeapi::native_application_is_single_instance()
        }
    }

    pub fn set_icon(icon_path: &str) -> bool {
        let icon_path_native = CString::new(icon_path).expect("string argument contains interior nul byte");
        unsafe {
            cnativeapi::native_application_set_icon(icon_path_native.as_ptr())
        }
    }

    pub fn set_dock_icon_visible(visible: bool) -> bool {
        unsafe {
            cnativeapi::native_application_set_dock_icon_visible(visible)
        }
    }

    pub fn set_menu_bar(menu: &Menu) -> bool {
        unsafe {
            cnativeapi::native_application_set_menu_bar(menu.as_raw())
        }
    }

    pub fn get_primary_window() -> Option<Window> {
        unsafe {
            Window::from_raw(cnativeapi::native_application_get_primary_window())
        }
    }

    pub fn set_primary_window(window: &Window) {
        unsafe {
            cnativeapi::native_application_set_primary_window(window.as_raw());
        }
    }

    pub fn get_all_windows() -> Vec<Window> {
        unsafe {
            let mut list = cnativeapi::native_application_get_all_windows();
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

    /// Registers `callback` for every `ApplicationEvent` this `Application` emits.
    ///
    /// The closure is leaked: the C ABI takes a `user_data` pointer but
    /// offers no hook to reclaim it, so removing the listener stops the
    /// calls without freeing the closure.
    pub fn add_listener(callback: impl Fn(&ApplicationEvent) + 'static) -> ListenerId {
        unsafe extern "C" fn trampoline(event: *const cnativeapi::native_application_event_t, user_data: *mut std::ffi::c_void) {
            if event.is_null() || user_data.is_null() {
                return;
            }
            let callback = &*(user_data as *const Box<dyn Fn(&ApplicationEvent)>);
            if let Some(event) = ApplicationEvent::from_raw(&*event) {
                callback(&event);
            }
        }
        let boxed: Box<Box<dyn Fn(&ApplicationEvent)>> = Box::new(Box::new(callback));
        let user_data = Box::into_raw(boxed) as *mut std::ffi::c_void;
        unsafe { cnativeapi::native_application_add_listener(Some(trampoline), user_data) }
    }

    /// Unregisters a listener. Returns false if unknown.
    pub fn remove_listener(listener_id: ListenerId) -> bool {
        unsafe { cnativeapi::native_application_remove_listener(listener_id) }
    }

}

