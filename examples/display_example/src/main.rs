//! Display example — enumerates the connected displays and prints their
//! properties.
//!
//! Usage:
//!   cargo run -p display_example

use nativeapi::{Display, DisplayManager};

fn main() {
    // --- 1. All connected displays ---
    let displays = DisplayManager::get_all();
    println!("Found {} display(s):", displays.len());
    for (index, display) in displays.iter().enumerate() {
        println!("\nDisplay {}:", index + 1);
        describe(display);
    }

    // --- 2. Primary display ---
    match DisplayManager::get_primary() {
        Some(primary) => println!(
            "\nPrimary display: {}",
            primary.name().unwrap_or_else(|| "(unnamed)".to_string())
        ),
        None => println!("\nNo primary display available."),
    }

    // --- 3. Cursor position ---
    let cursor = DisplayManager::get_cursor_position();
    println!("Cursor position: ({}, {})", cursor.x, cursor.y);
}

fn describe(display: &Display) {
    let size = display.size();
    let position = display.position();
    let work_area = display.work_area();

    println!("  ID:           {}", display.id().unwrap_or_default());
    println!("  Name:         {}", display.name().unwrap_or_default());
    println!("  Size:         {} x {}", size.width, size.height);
    println!("  Position:     ({}, {})", position.x, position.y);
    println!(
        "  Work area:    ({}, {}) {} x {}",
        work_area.x, work_area.y, work_area.width, work_area.height
    );
    println!("  Scale factor: {}", display.scale_factor());
    println!("  Primary:      {}", display.is_primary());
    println!("  Orientation:  {:?}", display.orientation());
    println!("  Refresh rate: {} Hz", display.refresh_rate());
    println!("  Bit depth:    {}", display.bit_depth());
}
