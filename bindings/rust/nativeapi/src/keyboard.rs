// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

#[repr(i32)]
#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum ModifierKey {
    None = 0,
    Shift = 1,
    Ctrl = 2,
    Alt = 4,
    Meta = 8,
    Fn = 16,
    CapsLock = 32,
    NumLock = 64,
    ScrollLock = 128,
}

impl ModifierKey {
    pub(crate) fn from_raw(raw: cnativeapi::native_modifier_key_t) -> Self {
        match raw {
            cnativeapi::NATIVE_MODIFIER_KEY_NONE => Self::None,
            cnativeapi::NATIVE_MODIFIER_KEY_SHIFT => Self::Shift,
            cnativeapi::NATIVE_MODIFIER_KEY_CTRL => Self::Ctrl,
            cnativeapi::NATIVE_MODIFIER_KEY_ALT => Self::Alt,
            cnativeapi::NATIVE_MODIFIER_KEY_META => Self::Meta,
            cnativeapi::NATIVE_MODIFIER_KEY_FN => Self::Fn,
            cnativeapi::NATIVE_MODIFIER_KEY_CAPS_LOCK => Self::CapsLock,
            cnativeapi::NATIVE_MODIFIER_KEY_NUM_LOCK => Self::NumLock,
            cnativeapi::NATIVE_MODIFIER_KEY_SCROLL_LOCK => Self::ScrollLock,
            _ => Self::None,
        }
    }

    pub(crate) fn to_raw(self) -> cnativeapi::native_modifier_key_t {
        self as cnativeapi::native_modifier_key_t
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct KeyboardAccelerator {
    pub modifiers: ModifierKey,
    pub key: Option<String>,
}

impl KeyboardAccelerator {
    pub(crate) unsafe fn from_raw(raw: &cnativeapi::native_keyboard_accelerator_t) -> Self {
        Self {
            modifiers: ModifierKey::from_raw(raw.modifiers),
            key: if raw.key.is_null() { None } else { Some(CStr::from_ptr(raw.key).to_string_lossy().into_owned()) },
        }
    }

    pub(crate) fn to_raw(&self) -> RawOfKeyboardAccelerator {
        let mut raw = cnativeapi::native_keyboard_accelerator_t::default();
        raw.modifiers = self.modifiers.to_raw();
        let key_owned = self.key.as_deref().map(|value| CString::new(value).unwrap_or_default());
        raw.key = key_owned.as_ref().map_or(std::ptr::null_mut(), |value| value.as_ptr() as *mut _);
        RawOfKeyboardAccelerator { raw, _owned: (key_owned, ()) }
    }
}

/// `KeyboardAccelerator` in its C form, keeping any borrowed buffers alive.
pub(crate) struct RawOfKeyboardAccelerator {
    pub(crate) raw: cnativeapi::native_keyboard_accelerator_t,
    _owned: (Option<CString>, ()),
}

/// One `KeyboardEvent`, in its concrete form.
#[derive(Debug, Clone, PartialEq)]
pub enum KeyboardEvent {
    KeyPressed { keycode: i32 },
    KeyReleased { keycode: i32 },
    ModifierKeysChanged { keycode: i32, modifier_keys: u32 },
}

impl KeyboardEvent {
    pub(crate) unsafe fn from_raw(raw: &cnativeapi::native_keyboard_event_t) -> Option<Self> {
        Some(match raw.type_ {
            cnativeapi::NATIVE_KEYBOARD_EVENT_TYPE_KEY_PRESSED => Self::KeyPressed { keycode: raw.keycode },
            cnativeapi::NATIVE_KEYBOARD_EVENT_TYPE_KEY_RELEASED => Self::KeyReleased { keycode: raw.keycode },
            cnativeapi::NATIVE_KEYBOARD_EVENT_TYPE_MODIFIER_KEYS_CHANGED => Self::ModifierKeysChanged { keycode: raw.keycode, modifier_keys: raw.data.modifier_keys_changed.modifier_keys },
            _ => return None,
        })
    }
}

