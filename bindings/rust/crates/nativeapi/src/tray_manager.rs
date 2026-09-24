// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
#![allow(dead_code)]
#![allow(unused_imports)]

use cnativeapi;
use std::ffi::{CStr, CString};

use crate::tray_icon::{TrayIcon, TrayIconId};

pub struct TrayManager;

impl TrayManager {
    pub fn is_supported() -> bool {
        unsafe {
            cnativeapi::native_tray_manager_is_supported()
        }
    }

    pub fn get(id: TrayIconId) -> Option<TrayIcon> {
        unsafe {
            TrayIcon::from_raw(cnativeapi::native_tray_manager_get(id))
        }
    }

    pub fn get_all() -> Vec<TrayIcon> {
        unsafe {
            let mut list = cnativeapi::native_tray_manager_get_all();
            let mut items = Vec::new();
            if !list.tray_icons.is_null() {
                for index in 0..list.count as isize {
                    if let Some(item) = TrayIcon::from_raw(*list.tray_icons.offset(index)) {
                        items.push(item);
                    }
                }
            }
            // Handles are now owned by `items`; drop just the array.
            cnativeapi::native_tray_icon_list_release(&mut list);
            items
        }
    }

}

