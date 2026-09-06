// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.

// Pulled into lib.rs with `include!("modules.rs");`.

pub mod accessibility_manager;
pub mod app_info;
pub mod application;
pub mod color;
pub mod device_info;
pub mod dialog;
pub mod display;
pub mod display_manager;
pub mod geometry;
pub mod image;
pub mod keyboard;
pub mod keyboard_monitor;
pub mod launch_at_login;
pub mod menu;
pub mod message_dialog;
pub mod placement;
pub mod positioning_strategy;
pub mod preferences;
pub mod secure_storage;
pub mod shortcut;
pub mod shortcut_manager;
pub mod tray_icon;
pub mod tray_manager;
pub mod url_opener;
pub mod window;
pub mod window_manager;

// Flat re-exports, so `use nativeapi::Display;` works alongside
// `use nativeapi::display::Display;`.
pub use accessibility_manager::{AccessibilityManager};
pub use app_info::{AppInfo};
pub use application::{ApplicationEvent, Application};
pub use color::{Color};
pub use device_info::{DeviceInfo};
pub use dialog::{DialogModality};
pub use display::{DisplayId, DisplayOrientation, DisplayEvent, Display, DisplayRef};
pub use display_manager::{DisplayManager};
pub use geometry::{Point, Size, Rectangle};
pub use image::{Image, ImageRef};
pub use keyboard::{ModifierKey, KeyboardAccelerator, KeyboardEvent};
pub use keyboard_monitor::{KeyboardMonitor, KeyboardMonitorRef};
pub use launch_at_login::{LaunchAtLogin, LaunchAtLoginRef};
pub use menu::{MenuId, MenuItemId, MenuItemType, MenuItemState, MenuEvent, MenuItem, MenuItemRef, Menu, MenuRef};
pub use message_dialog::{MessageDialog, MessageDialogRef};
pub use placement::{Placement};
pub use positioning_strategy::{PositioningStrategyType, PositioningStrategy, PositioningStrategyRef};
pub use preferences::{Preferences, PreferencesRef};
pub use secure_storage::{SecureStorage, SecureStorageRef};
pub use shortcut::{ShortcutId, ShortcutScope, ShortcutOptions, ShortcutEvent, Shortcut, ShortcutRef};
pub use shortcut_manager::{ShortcutManager};
pub use tray_icon::{TrayIconId, ContextMenuTrigger, TrayIconEvent, TrayIcon, TrayIconRef};
pub use tray_manager::{TrayManager};
pub use url_opener::{UrlOpenErrorCode, UrlOpenResult, UrlOpener};
pub use window::{WindowId, TitleBarStyle, VisualEffect, ResizeEdge, WindowEvent, Window, WindowRef};
pub use window_manager::{WindowManager};
