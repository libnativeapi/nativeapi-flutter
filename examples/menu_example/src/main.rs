//! Menu example — builds a menu with every item type, attaches accelerators
//! and a submenu, and listens for menu events.
//!
//! Usage:
//!   cargo run -p menu_example

use nativeapi::geometry::Point;
use nativeapi::keyboard::{KeyboardAccelerator, ModifierKey};
use nativeapi::menu::{Menu, MenuEvent, MenuItem, MenuItemState, MenuItemType};
use nativeapi::placement::Placement;
use nativeapi::positioning_strategy::PositioningStrategy;

fn main() {
    let Some(menu) = Menu::new() else {
        eprintln!("Failed to create a menu.");
        std::process::exit(1);
    };
    println!("Created menu #{}", menu.id());

    // A menu and each of its items are separate emitters, so listen on both.
    let menu_listener = menu.add_listener(|event| println!("[menu] {event:?}"));

    // --- 1. A plain item with an accelerator ---
    let Some(new_file) = MenuItem::with_label_and_type("New File", MenuItemType::Normal) else {
        eprintln!("Failed to create a menu item.");
        std::process::exit(1);
    };
    new_file.set_tooltip(Some("Create an empty document"));
    new_file.set_accelerator(Some(&KeyboardAccelerator {
        modifiers: ModifierKey::Ctrl,
        key: Some("N".to_string()),
    }));
    let click_listener = new_file.add_listener(|event| {
        if let MenuEvent::ItemClicked { item_id } = event {
            println!("[item] {item_id} clicked");
        }
    });
    menu.add_item(&new_file);

    menu.add_separator();

    // --- 2. A checkbox, cycled through its three states ---
    let Some(word_wrap) = MenuItem::with_label_and_type("Word Wrap", MenuItemType::Checkbox) else {
        return;
    };
    for state in [
        MenuItemState::Unchecked,
        MenuItemState::Checked,
        MenuItemState::Mixed,
    ] {
        word_wrap.set_state(state);
        println!("Word Wrap state -> {:?}", word_wrap.state());
    }
    menu.add_item(&word_wrap);

    // --- 3. A radio group ---
    for (index, label) in ["Light", "Dark", "Auto"].iter().enumerate() {
        let Some(item) = MenuItem::with_label_and_type(label, MenuItemType::Radio) else {
            continue;
        };
        item.set_radio_group(1);
        if index == 0 {
            item.set_state(MenuItemState::Checked);
        }
        menu.add_item(&item);
    }

    // --- 4. A submenu ---
    let Some(tools) = Menu::new() else { return };
    for label in ["Clear Cache", "Reset Settings"] {
        if let Some(item) = MenuItem::with_label_and_type(label, MenuItemType::Normal) {
            tools.add_item(&item);
        }
    }
    let Some(tools_item) = MenuItem::with_label_and_type("Tools", MenuItemType::Submenu) else {
        return;
    };
    tools_item.set_submenu(&tools);
    menu.add_item(&tools_item);

    // --- 5. A disabled item ---
    if let Some(quit) = MenuItem::with_label_and_type("Quit", MenuItemType::Normal) {
        quit.set_enabled(false);
        println!("Quit enabled = {}", quit.is_enabled());
        menu.add_item(&quit);
    }

    // --- 6. Inspect ---
    println!("Menu holds {} item(s)", menu.item_count());
    for item in menu.all_items() {
        println!(
            "  #{} {:?} type={:?} enabled={}",
            item.id(),
            item.label(),
            item.r#type(),
            item.is_enabled()
        );
    }
    if let Some(found) = menu.get_item_by_id(new_file.id()) {
        println!("Found by id: {:?}", found.label());
    }

    // --- 7. Open as a context menu ---
    // Without a running event loop this is expected to fail; it shows the
    // shape of the call.
    if let Some(strategy) = PositioningStrategy::absolute(&Point { x: 100.0, y: 200.0 }) {
        println!("Positioning at {:?}", strategy.absolute_position());
        let opened = menu.open(&strategy, Placement::BottomStart);
        println!("Context menu opened: {opened}");
        if opened {
            menu.close();
        }
    }
    if let Some(at_cursor) = PositioningStrategy::cursor_position() {
        println!("Cursor strategy type: {:?}", at_cursor.r#type());
    }

    // --- 8. Clean up ---
    new_file.remove_listener(click_listener);
    menu.remove_listener(menu_listener);
    menu.clear();
    println!("After clear: {} item(s)", menu.item_count());
}
