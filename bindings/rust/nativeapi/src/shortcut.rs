// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

pub type ShortcutId = u32;

#[repr(i32)]
#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum ShortcutScope {
    Global = 0,
    Application = 1,
}

impl ShortcutScope {
    pub(crate) fn from_raw(raw: cnativeapi::native_shortcut_scope_t) -> Self {
        match raw {
            cnativeapi::NATIVE_SHORTCUT_SCOPE_GLOBAL => Self::Global,
            cnativeapi::NATIVE_SHORTCUT_SCOPE_APPLICATION => Self::Application,
            _ => Self::Global,
        }
    }

    pub(crate) fn to_raw(self) -> cnativeapi::native_shortcut_scope_t {
        self as cnativeapi::native_shortcut_scope_t
    }
}

#[derive(Clone)]
pub struct ShortcutOptions {
    pub accelerator: Option<String>,
    pub callback: Option<std::sync::Arc<dyn Fn()>>,
    pub description: Option<String>,
    pub scope: ShortcutScope,
    pub enabled: bool,
}

impl ShortcutOptions {
    pub(crate) unsafe fn from_raw(raw: &cnativeapi::native_shortcut_options_t) -> Self {
        Self {
            accelerator: if raw.accelerator.is_null() { None } else { Some(CStr::from_ptr(raw.accelerator).to_string_lossy().into_owned()) },
            callback: None,
            description: if raw.description.is_null() { None } else { Some(CStr::from_ptr(raw.description).to_string_lossy().into_owned()) },
            scope: ShortcutScope::from_raw(raw.scope),
            enabled: raw.enabled,
        }
    }

    pub(crate) fn to_raw(&self) -> RawOfShortcutOptions {
        let mut raw = cnativeapi::native_shortcut_options_t::default();
        let accelerator_owned = self.accelerator.as_deref().map(|value| CString::new(value).unwrap_or_default());
        raw.accelerator = accelerator_owned.as_ref().map_or(std::ptr::null_mut(), |value| value.as_ptr() as *mut _);
        if let Some(callback) = &self.callback {
            unsafe extern "C" fn trampoline(user_data: *mut std::ffi::c_void) {
                if user_data.is_null() {
                    return;
                }
                let callback = &*(user_data as *const std::sync::Arc<dyn Fn()>);
                callback();
            }
            fn into_user_data(callback: std::sync::Arc<dyn Fn()>) -> *mut std::ffi::c_void {
                Box::into_raw(Box::new(callback)) as *mut std::ffi::c_void
            }
            unsafe extern "C" fn release(user_data: *mut std::ffi::c_void) {
                if !user_data.is_null() {
                    drop(Box::from_raw(user_data as *mut std::sync::Arc<dyn Fn()>));
                }
            }
            raw.callback = Some(trampoline);
            raw.callback_user_data = into_user_data(callback.clone());
            raw.callback_release_user_data = Some(release);
        }
        let description_owned = self.description.as_deref().map(|value| CString::new(value).unwrap_or_default());
        raw.description = description_owned.as_ref().map_or(std::ptr::null_mut(), |value| value.as_ptr() as *mut _);
        raw.scope = self.scope.to_raw();
        raw.enabled = self.enabled;
        RawOfShortcutOptions { raw, _owned: (accelerator_owned, description_owned) }
    }
}

/// `ShortcutOptions` in its C form, keeping any borrowed buffers alive.
pub(crate) struct RawOfShortcutOptions {
    pub(crate) raw: cnativeapi::native_shortcut_options_t,
    _owned: (Option<CString>, Option<CString>),
}

/// One `ShortcutEvent`, in its concrete form.
#[derive(Debug, Clone, PartialEq)]
pub enum ShortcutEvent {
    Activated { shortcut_id: ShortcutId, accelerator: Option<String> },
    Registered { shortcut_id: ShortcutId, accelerator: Option<String> },
    Unregistered { shortcut_id: ShortcutId, accelerator: Option<String> },
    RegistrationFailed { shortcut_id: ShortcutId, accelerator: Option<String>, error_message: Option<String> },
}

impl ShortcutEvent {
    pub(crate) unsafe fn from_raw(raw: &cnativeapi::native_shortcut_event_t) -> Option<Self> {
        Some(match raw.type_ {
            cnativeapi::NATIVE_SHORTCUT_EVENT_TYPE_ACTIVATED => Self::Activated { shortcut_id: raw.shortcut_id, accelerator: if raw.accelerator.is_null() { None } else { Some(CStr::from_ptr(raw.accelerator).to_string_lossy().into_owned()) } },
            cnativeapi::NATIVE_SHORTCUT_EVENT_TYPE_REGISTERED => Self::Registered { shortcut_id: raw.shortcut_id, accelerator: if raw.accelerator.is_null() { None } else { Some(CStr::from_ptr(raw.accelerator).to_string_lossy().into_owned()) } },
            cnativeapi::NATIVE_SHORTCUT_EVENT_TYPE_UNREGISTERED => Self::Unregistered { shortcut_id: raw.shortcut_id, accelerator: if raw.accelerator.is_null() { None } else { Some(CStr::from_ptr(raw.accelerator).to_string_lossy().into_owned()) } },
            cnativeapi::NATIVE_SHORTCUT_EVENT_TYPE_REGISTRATION_FAILED => Self::RegistrationFailed { shortcut_id: raw.shortcut_id, accelerator: if raw.accelerator.is_null() { None } else { Some(CStr::from_ptr(raw.accelerator).to_string_lossy().into_owned()) }, error_message: if raw.data.registration_failed.error_message.is_null() { None } else { Some(CStr::from_ptr(raw.data.registration_failed.error_message).to_string_lossy().into_owned()) } },
            _ => return None,
        })
    }
}

/// Owned handle to a native `Shortcut`.
#[derive(Debug)]
pub struct Shortcut {
    handle: cnativeapi::native_shortcut_t,
}

impl Shortcut {
    /// Adopts a handle returned by the C API.
    ///
    /// # Safety
    /// `handle` must be a live handle that is not owned elsewhere.
    pub unsafe fn from_raw(handle: cnativeapi::native_shortcut_t) -> Option<Self> {
        if handle == 0 {
            None
        } else {
            Some(Self { handle })
        }
    }

    /// Borrows the underlying C handle.
    pub fn as_raw(&self) -> cnativeapi::native_shortcut_t {
        self.handle
    }

    /// Creates a new `Shortcut`; returns `None` if the native side failed.
    pub fn with_id_and_options(id: ShortcutId, options: &ShortcutOptions) -> Option<Self> {
        let options_raw = options.to_raw();
        unsafe {
            Self::from_raw(cnativeapi::native_shortcut_create_with_id_and_options(id, options_raw.raw))
        }
    }

    /// Creates a new `Shortcut`; returns `None` if the native side failed.
    pub fn with_id_and_accelerator_and_callback(id: ShortcutId, accelerator: &str, callback: impl Fn() + 'static) -> Option<Self> {
        let accelerator_native = CString::new(accelerator).expect("string argument contains interior nul byte");
        unsafe extern "C" fn trampoline(user_data: *mut std::ffi::c_void) {
            if user_data.is_null() {
                return;
            }
            let callback = &*(user_data as *const std::sync::Arc<dyn Fn()>);
            callback();
        }
        fn into_user_data(callback: std::sync::Arc<dyn Fn()>) -> *mut std::ffi::c_void {
            Box::into_raw(Box::new(callback)) as *mut std::ffi::c_void
        }
        unsafe extern "C" fn release(user_data: *mut std::ffi::c_void) {
            if !user_data.is_null() {
                drop(Box::from_raw(user_data as *mut std::sync::Arc<dyn Fn()>));
            }
        }
        let callback_user_data = into_user_data(std::sync::Arc::new(callback));
        unsafe {
            Self::from_raw(cnativeapi::native_shortcut_create_with_id_and_accelerator_and_callback(id, accelerator_native.as_ptr(), Some(trampoline), callback_user_data, Some(release)))
        }
    }

    pub fn id(&self) -> ShortcutId {
        unsafe {
            cnativeapi::native_shortcut_get_id(self.handle)
        }
    }

    pub fn accelerator(&self) -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_shortcut_get_accelerator(self.handle);
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn description(&self) -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_shortcut_get_description(self.handle);
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

    pub fn set_description(&self, description: &str) {
        let description_native = CString::new(description).expect("string argument contains interior nul byte");
        unsafe {
            cnativeapi::native_shortcut_set_description(self.handle, description_native.as_ptr());
        }
    }

    pub fn scope(&self) -> ShortcutScope {
        unsafe {
            ShortcutScope::from_raw(cnativeapi::native_shortcut_get_scope(self.handle))
        }
    }

    pub fn set_enabled(&self, enabled: bool) {
        unsafe {
            cnativeapi::native_shortcut_set_enabled(self.handle, enabled);
        }
    }

    pub fn is_enabled(&self) -> bool {
        unsafe {
            cnativeapi::native_shortcut_is_enabled(self.handle)
        }
    }

    pub fn invoke(&self) {
        unsafe {
            cnativeapi::native_shortcut_invoke(self.handle);
        }
    }

    pub fn set_callback(&self, callback: impl Fn() + 'static) {
        unsafe extern "C" fn trampoline(user_data: *mut std::ffi::c_void) {
            if user_data.is_null() {
                return;
            }
            let callback = &*(user_data as *const std::sync::Arc<dyn Fn()>);
            callback();
        }
        fn into_user_data(callback: std::sync::Arc<dyn Fn()>) -> *mut std::ffi::c_void {
            Box::into_raw(Box::new(callback)) as *mut std::ffi::c_void
        }
        unsafe extern "C" fn release(user_data: *mut std::ffi::c_void) {
            if !user_data.is_null() {
                drop(Box::from_raw(user_data as *mut std::sync::Arc<dyn Fn()>));
            }
        }
        let callback_user_data = into_user_data(std::sync::Arc::new(callback));
        unsafe {
            cnativeapi::native_shortcut_set_callback(self.handle, Some(trampoline), callback_user_data, Some(release));
        }
    }

}

impl Drop for Shortcut {
    fn drop(&mut self) {
        if self.handle != 0 {
            unsafe { cnativeapi::native_shortcut_free(self.handle) };
        }
    }
}

/// A `Shortcut` owned elsewhere; using it does not release it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ShortcutRef(cnativeapi::native_shortcut_t);

impl ShortcutRef {
    pub(crate) fn from_raw(handle: cnativeapi::native_shortcut_t) -> Self {
        Self(handle)
    }

    pub fn as_raw(&self) -> cnativeapi::native_shortcut_t {
        self.0
    }

    /// Runs `f` against the borrowed handle. The `Shortcut` it receives
    /// must not outlive the call.
    pub fn with<R>(&self, f: impl FnOnce(&Shortcut) -> R) -> R {
        let borrowed = std::mem::ManuallyDrop::new(Shortcut { handle: self.0 });
        f(&borrowed)
    }
}

