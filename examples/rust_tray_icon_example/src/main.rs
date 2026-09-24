//! Tray icon example — creates a tray icon with an image and a context menu,
//! and listens for clicks.
//!
//! Usage:
//!   cargo run -p tray_icon_example

use nativeapi::image::Image;
use nativeapi::menu::{Menu, MenuItem, MenuItemType};
use nativeapi::tray_icon::{ContextMenuTrigger, TrayIcon, TrayIconEvent};
use nativeapi::tray_manager::TrayManager;

/// A 1x1 transparent PNG, so the example needs no asset on disk.
const PIXEL_PNG: &str = "data:image/png;base64,\
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==";

fn main() {
    // --- 1. Platform support ---
    if !TrayManager::is_supported() {
        println!("System tray is not supported on this platform.");
        return;
    }

    let Some(tray) = TrayIcon::new() else {
        eprintln!("Failed to create a tray icon.");
        std::process::exit(1);
    };
    println!("Created tray icon #{}", tray.get_id());

    // --- 2. Events ---
    let listener = tray.add_listener(|event| match event {
        TrayIconEvent::Clicked { tray_icon_id } => println!("[tray] {tray_icon_id} clicked"),
        TrayIconEvent::RightClicked { tray_icon_id } => {
            println!("[tray] {tray_icon_id} right-clicked")
        }
        TrayIconEvent::DoubleClicked { tray_icon_id } => {
            println!("[tray] {tray_icon_id} double-clicked")
        }
    });

    // --- 3. Appearance ---
    tray.set_title(Some("NativeAPI"));
    tray.set_tooltip(Some("Rust tray icon example"));
    println!("Title: {:?}", tray.get_title());
    println!("Tooltip: {:?}", tray.get_tooltip());

    match Image::from_base64(PIXEL_PNG) {
        Some(image) => {
            println!("Icon: {:?}, size {:?}", image.format(), image.size());
            tray.set_icon(Some(&image));
        }
        None => println!("Could not decode the embedded icon."),
    }

    // --- 4. Context menu ---
    if let Some(menu) = Menu::new() {
        for label in ["Show", "Preferences"] {
            if let Some(item) = MenuItem::with_label_and_type(label, MenuItemType::Normal) {
                menu.add_item(Some(&item));
            }
        }
        menu.add_separator();
        if let Some(quit) = MenuItem::with_label_and_type("Quit", MenuItemType::Normal) {
            menu.add_item(Some(&quit));
        }

        tray.set_context_menu(Some(&menu));
        tray.set_context_menu_trigger(ContextMenuTrigger::RightClicked);
        println!("Trigger: {:?}", tray.get_context_menu_trigger());
        if let Some(attached) = tray.get_context_menu() {
            println!("Context menu #{} attached", attached.id());
        }
    }

    // --- 5. Visibility and geometry ---
    let shown = tray.set_visible(true);
    println!("Visible: {shown} (is_visible = {})", tray.is_visible());
    let bounds = tray.get_bounds();
    println!(
        "Bounds: ({}, {}) {}x{}",
        bounds.x, bounds.y, bounds.width, bounds.height
    );

    // --- 6. The manager's view ---
    let all = TrayManager::get_all();
    println!("TrayManager tracks {} icon(s)", all.len());
    if let Some(same) = TrayManager::get(tray.get_id()) {
        println!("Looked up tray icon #{} by id", same.get_id());
    }

    // --- 7. Clean up ---
    tray.remove_listener(listener);
    tray.set_visible(false);
}
