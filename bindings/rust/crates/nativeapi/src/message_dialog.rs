// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

use crate::dialog::DialogModality;
use crate::window::Window;

#[repr(i32)]
#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum MessageDialogResult {
    None = 0,
    Primary = 1,
    Secondary = 2,
    Close = 3,
}

impl MessageDialogResult {
    pub(crate) fn from_raw(raw: cnativeapi::native_message_dialog_result_t) -> Self {
        match raw {
            cnativeapi::NATIVE_MESSAGE_DIALOG_RESULT_NONE => Self::None,
            cnativeapi::NATIVE_MESSAGE_DIALOG_RESULT_PRIMARY => Self::Primary,
            cnativeapi::NATIVE_MESSAGE_DIALOG_RESULT_SECONDARY => Self::Secondary,
            cnativeapi::NATIVE_MESSAGE_DIALOG_RESULT_CLOSE => Self::Close,
            _ => Self::None,
        }
    }

    pub(crate) fn to_raw(self) -> cnativeapi::native_message_dialog_result_t {
        self as cnativeapi::native_message_dialog_result_t
    }
}

/// Owned handle to a native `MessageDialog`.
#[derive(Debug)]
pub struct MessageDialog {
    handle: cnativeapi::native_message_dialog_t,
}

impl MessageDialog {
    /// Adopts a handle returned by the C API.
    ///
    /// # Safety
    /// `handle` must be a live handle that is not owned elsewhere.
    pub unsafe fn from_raw(handle: cnativeapi::native_message_dialog_t) -> Option<Self> {
        if handle == 0 {
            None
        } else {
            Some(Self { handle })
        }
    }

    /// Borrows the underlying C handle.
    pub fn as_raw(&self) -> cnativeapi::native_message_dialog_t {
        self.handle
    }

    /// Creates a new `MessageDialog`; returns `None` if the native side failed.
    pub fn new(title: &str, message: &str) -> Option<Self> {
        let title_native = CString::new(title).expect("string argument contains interior nul byte");
        let message_native = CString::new(message).expect("string argument contains interior nul byte");
        unsafe {
            Self::from_raw(cnativeapi::native_message_dialog_create(title_native.as_ptr(), message_native.as_ptr()))
        }
    }

    pub fn is_extended_supported() -> bool {
        unsafe {
            cnativeapi::native_message_dialog_is_extended_supported()
        }
    }

    pub fn set_buttons(&self, primary: &str, secondary: &str, close: &str) -> bool {
        let primary_native = CString::new(primary).expect("string argument contains interior nul byte");
        let secondary_native = CString::new(secondary).expect("string argument contains interior nul byte");
        let close_native = CString::new(close).expect("string argument contains interior nul byte");
        unsafe {
            cnativeapi::native_message_dialog_set_buttons(self.handle, primary_native.as_ptr(), secondary_native.as_ptr(), close_native.as_ptr())
        }
    }

    pub fn set_default_button(&self, button: MessageDialogResult) -> bool {
        unsafe {
            cnativeapi::native_message_dialog_set_default_button(self.handle, button.to_raw())
        }
    }

    pub fn set_parent_window(&self, window: Option<&Window>) -> bool {
        unsafe {
            cnativeapi::native_message_dialog_set_parent_window(self.handle, window.map_or(0, |value| value.as_raw()))
        }
    }

    pub fn result(&self) -> MessageDialogResult {
        unsafe {
            MessageDialogResult::from_raw(cnativeapi::native_message_dialog_get_result(self.handle))
        }
    }

    pub fn is_open(&self) -> bool {
        unsafe {
            cnativeapi::native_message_dialog_is_open(self.handle)
        }
    }

    pub fn set_input_enabled(&self, enabled: bool) -> bool {
        unsafe {
            cnativeapi::native_message_dialog_set_input_enabled(self.handle, enabled)
        }
    }

    pub fn set_input_text(&self, text: &str) -> bool {
        let text_native = CString::new(text).expect("string argument contains interior nul byte");
        unsafe {
            cnativeapi::native_message_dialog_set_input_text(self.handle, text_native.as_ptr())
        }
    }

    pub fn input_text(&self) -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_message_dialog_get_input_text(self.handle);
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn set_checkbox(&self, label: &str, checked: bool) -> bool {
        let label_native = CString::new(label).expect("string argument contains interior nul byte");
        unsafe {
            cnativeapi::native_message_dialog_set_checkbox(self.handle, label_native.as_ptr(), checked)
        }
    }

    pub fn is_checkbox_checked(&self) -> bool {
        unsafe {
            cnativeapi::native_message_dialog_is_checkbox_checked(self.handle)
        }
    }

    pub fn set_progress(&self, value: f64) -> bool {
        unsafe {
            cnativeapi::native_message_dialog_set_progress(self.handle, value)
        }
    }

    pub fn set_title(&self, title: &str) {
        let title_native = CString::new(title).expect("string argument contains interior nul byte");
        unsafe {
            cnativeapi::native_message_dialog_set_title(self.handle, title_native.as_ptr());
        }
    }

    pub fn title(&self) -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_message_dialog_get_title(self.handle);
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn set_message(&self, message: &str) {
        let message_native = CString::new(message).expect("string argument contains interior nul byte");
        unsafe {
            cnativeapi::native_message_dialog_set_message(self.handle, message_native.as_ptr());
        }
    }

    pub fn message(&self) -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_message_dialog_get_message(self.handle);
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn modality(&self) -> DialogModality {
        unsafe {
            DialogModality::from_raw(cnativeapi::native_message_dialog_get_modality(self.handle))
        }
    }

    pub fn set_modality(&self, modality: DialogModality) {
        unsafe {
            cnativeapi::native_message_dialog_set_modality(self.handle, modality.to_raw());
        }
    }

    pub fn open(&self) -> bool {
        unsafe {
            cnativeapi::native_message_dialog_open(self.handle)
        }
    }

    pub fn close(&self) -> bool {
        unsafe {
            cnativeapi::native_message_dialog_close(self.handle)
        }
    }

}

impl Drop for MessageDialog {
    fn drop(&mut self) {
        if self.handle != 0 {
            unsafe { cnativeapi::native_message_dialog_free(self.handle) };
        }
    }
}

/// A `MessageDialog` owned elsewhere; using it does not release it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct MessageDialogRef(cnativeapi::native_message_dialog_t);

impl MessageDialogRef {
    pub(crate) fn from_raw(handle: cnativeapi::native_message_dialog_t) -> Self {
        Self(handle)
    }

    pub fn as_raw(&self) -> cnativeapi::native_message_dialog_t {
        self.0
    }

    /// Runs `f` against the borrowed handle. The `MessageDialog` it receives
    /// must not outlive the call.
    pub fn with<R>(&self, f: impl FnOnce(&MessageDialog) -> R) -> R {
        let borrowed = std::mem::ManuallyDrop::new(MessageDialog { handle: self.0 });
        f(&borrowed)
    }
}

