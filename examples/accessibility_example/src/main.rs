//! Accessibility example — checks whether the process is trusted for
//! accessibility APIs, and asks for permission if not.
//!
//! On macOS `enable()` opens the System Settings pane; elsewhere it is a
//! no-op and `is_enabled()` reports true.
//!
//! Usage:
//!   cargo run -p accessibility_example

use nativeapi::accessibility_manager::AccessibilityManager;

fn main() {
    let enabled = AccessibilityManager::is_enabled();
    println!("Accessibility enabled: {enabled}");

    if enabled {
        println!("Global keyboard monitoring and shortcuts will work.");
        return;
    }

    println!("Requesting accessibility permission...");
    AccessibilityManager::enable();
    println!(
        "After the request: {}",
        AccessibilityManager::is_enabled()
    );
    println!(
        "Grant the permission in System Settings > Privacy & Security > \
         Accessibility, then run this again."
    );
}
