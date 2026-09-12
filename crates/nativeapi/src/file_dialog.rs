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
pub enum FileDialogMode {
    OpenFile = 0,
    OpenFiles = 1,
    SaveFile = 2,
    SelectFolder = 3,
}

impl FileDialogMode {
    pub(crate) fn from_raw(raw: cnativeapi::native_file_dialog_mode_t) -> Self {
        match raw {
            cnativeapi::NATIVE_FILE_DIALOG_MODE_OPEN_FILE => Self::OpenFile,
            cnativeapi::NATIVE_FILE_DIALOG_MODE_OPEN_FILES => Self::OpenFiles,
            cnativeapi::NATIVE_FILE_DIALOG_MODE_SAVE_FILE => Self::SaveFile,
            cnativeapi::NATIVE_FILE_DIALOG_MODE_SELECT_FOLDER => Self::SelectFolder,
            _ => Self::OpenFile,
        }
    }

    pub(crate) fn to_raw(self) -> cnativeapi::native_file_dialog_mode_t {
        self as cnativeapi::native_file_dialog_mode_t
    }
}

#[repr(i32)]
#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum FileDialogResult {
    None = 0,
    Accepted = 1,
    Cancelled = 2,
    Failed = 3,
}

impl FileDialogResult {
    pub(crate) fn from_raw(raw: cnativeapi::native_file_dialog_result_t) -> Self {
        match raw {
            cnativeapi::NATIVE_FILE_DIALOG_RESULT_NONE => Self::None,
            cnativeapi::NATIVE_FILE_DIALOG_RESULT_ACCEPTED => Self::Accepted,
            cnativeapi::NATIVE_FILE_DIALOG_RESULT_CANCELLED => Self::Cancelled,
            cnativeapi::NATIVE_FILE_DIALOG_RESULT_FAILED => Self::Failed,
            _ => Self::None,
        }
    }

    pub(crate) fn to_raw(self) -> cnativeapi::native_file_dialog_result_t {
        self as cnativeapi::native_file_dialog_result_t
    }
}

/// Owned handle to a native `FileDialog`.
#[derive(Debug)]
pub struct FileDialog {
    handle: cnativeapi::native_file_dialog_t,
}

impl FileDialog {
    /// Adopts a handle returned by the C API.
    ///
    /// # Safety
    /// `handle` must be a live handle that is not owned elsewhere.
    pub unsafe fn from_raw(handle: cnativeapi::native_file_dialog_t) -> Option<Self> {
        if handle == 0 {
            None
        } else {
            Some(Self { handle })
        }
    }

    /// Borrows the underlying C handle.
    pub fn as_raw(&self) -> cnativeapi::native_file_dialog_t {
        self.handle
    }

    /// Creates a new `FileDialog`; returns `None` if the native side failed.
    pub fn new(mode: FileDialogMode) -> Option<Self> {
        unsafe {
            Self::from_raw(cnativeapi::native_file_dialog_create(mode.to_raw()))
        }
    }

    pub fn is_supported() -> bool {
        unsafe {
            cnativeapi::native_file_dialog_is_supported()
        }
    }

    pub fn set_parent_window(&self, window: Option<&Window>) -> bool {
        unsafe {
            cnativeapi::native_file_dialog_set_parent_window(self.handle, window.map_or(0, |value| value.as_raw()))
        }
    }

    pub fn set_file_types(&self, extensions: &[String]) -> bool {
        let extensions_owned: Vec<CString> = extensions
            .iter()
            .map(|value| CString::new(value.as_str()).unwrap_or_default())
            .collect();
        let mut extensions_ptrs: Vec<*mut std::os::raw::c_char> =
            extensions_owned.iter().map(|value| value.as_ptr() as *mut _).collect();
        let extensions_native = cnativeapi::native_string_list_t {
            items: extensions_ptrs.as_mut_ptr(),
            count: extensions_ptrs.len() as std::os::raw::c_long,
        };
        unsafe {
            cnativeapi::native_file_dialog_set_file_types(self.handle, extensions_native)
        }
    }

    pub fn set_suggested_file_name(&self, name: &str) -> bool {
        let name_native = CString::new(name).expect("string argument contains interior nul byte");
        unsafe {
            cnativeapi::native_file_dialog_set_suggested_file_name(self.handle, name_native.as_ptr())
        }
    }

    pub fn modality(&self) -> DialogModality {
        unsafe {
            DialogModality::from_raw(cnativeapi::native_file_dialog_get_modality(self.handle))
        }
    }

    pub fn set_modality(&self, modality: DialogModality) {
        unsafe {
            cnativeapi::native_file_dialog_set_modality(self.handle, modality.to_raw());
        }
    }

    pub fn open(&self) -> bool {
        unsafe {
            cnativeapi::native_file_dialog_open(self.handle)
        }
    }

    pub fn close(&self) -> bool {
        unsafe {
            cnativeapi::native_file_dialog_close(self.handle)
        }
    }

    pub fn result(&self) -> FileDialogResult {
        unsafe {
            FileDialogResult::from_raw(cnativeapi::native_file_dialog_get_result(self.handle))
        }
    }

    pub fn paths(&self) -> Vec<String> {
        unsafe {
            let mut list = cnativeapi::native_file_dialog_get_paths(self.handle);
            let mut items = Vec::new();
            if !list.items.is_null() {
                for index in 0..list.count as isize {
                    let ptr = *list.items.offset(index);
                    if !ptr.is_null() {
                        items.push(CStr::from_ptr(ptr).to_string_lossy().into_owned());
                    }
                }
            }
            cnativeapi::native_string_list_free(&mut list);
            items
        }
    }

    pub fn last_error(&self) -> Option<String> {
        unsafe {
            let ptr = cnativeapi::native_file_dialog_get_last_error(self.handle);
            if ptr.is_null() {
                return None;
            }
            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();
            cnativeapi::free_c_str(ptr);
            Some(value)
        }
    }

}

impl Drop for FileDialog {
    fn drop(&mut self) {
        if self.handle != 0 {
            unsafe { cnativeapi::native_file_dialog_free(self.handle) };
        }
    }
}

/// A `FileDialog` owned elsewhere; using it does not release it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct FileDialogRef(cnativeapi::native_file_dialog_t);

impl FileDialogRef {
    pub(crate) fn from_raw(handle: cnativeapi::native_file_dialog_t) -> Self {
        Self(handle)
    }

    pub fn as_raw(&self) -> cnativeapi::native_file_dialog_t {
        self.0
    }

    /// Runs `f` against the borrowed handle. The `FileDialog` it receives
    /// must not outlive the call.
    pub fn with<R>(&self, f: impl FnOnce(&FileDialog) -> R) -> R {
        let borrowed = std::mem::ManuallyDrop::new(FileDialog { handle: self.0 });
        f(&borrowed)
    }
}

