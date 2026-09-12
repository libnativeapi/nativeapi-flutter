//! Keyboard example — starts a keyboard monitor and prints key and modifier
//! events for a few seconds.
//!
//! Monitoring the keyboard globally needs accessibility permission on macOS
//! and a display server on Linux; without them the monitor simply reports that
//! it is not running.
//!
//! Usage:
//!   cargo run -p keyboard_example

use nativeapi::keyboard::{KeyboardEvent, ModifierKey};
use nativeapi::keyboard_monitor::KeyboardMonitor;

fn main() {
    let Some(monitor) = KeyboardMonitor::new() else {
        eprintln!("Failed to create a keyboard monitor.");
        std::process::exit(1);
    };

    // --- 1. Events ---
    let listener = monitor.add_listener(|event| match event {
        KeyboardEvent::KeyPressed { keycode } => println!("[key] pressed  {keycode}"),
        KeyboardEvent::KeyReleased { keycode } => println!("[key] released {keycode}"),
        KeyboardEvent::ModifierKeysChanged { modifier_keys, .. } => {
            println!(
                "[key] modifiers {:#06x} -> {}",
                modifier_keys,
                describe(*modifier_keys)
            );
        }
    });

    // --- 2. Start ---
    monitor.start();
    if monitor.is_monitoring() {
        println!("Monitoring for 5 seconds — press some keys.");
        std::thread::sleep(std::time::Duration::from_secs(5));
    } else {
        println!(
            "Monitor did not start. This is expected without accessibility \
             permission or a display server."
        );
    }

    // --- 3. Stop ---
    monitor.stop();
    println!("is_monitoring = {}", monitor.is_monitoring());
    monitor.remove_listener(listener);
}

/// The modifier mask is a bit set of `ModifierKey` values.
fn describe(mask: u32) -> String {
    let flags = [
        (ModifierKey::Shift, "Shift"),
        (ModifierKey::Ctrl, "Ctrl"),
        (ModifierKey::Alt, "Alt"),
        (ModifierKey::Meta, "Meta"),
        (ModifierKey::Fn, "Fn"),
        (ModifierKey::CapsLock, "CapsLock"),
        (ModifierKey::NumLock, "NumLock"),
        (ModifierKey::ScrollLock, "ScrollLock"),
    ];
    let names: Vec<&str> = flags
        .iter()
        .filter(|(flag, _)| mask & (*flag as u32) != 0)
        .map(|(_, name)| *name)
        .collect();
    if names.is_empty() {
        "none".to_string()
    } else {
        names.join(" + ")
    }
}
