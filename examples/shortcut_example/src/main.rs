//! Shortcut example — registers global shortcuts two ways, inspects them, and
//! listens for shortcut events.
//!
//! Registering a global shortcut needs OS permission on some platforms; the
//! example reports failures instead of panicking.
//!
//! Usage:
//!   cargo run -p shortcut_example

use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::Arc;

use nativeapi::shortcut::{ShortcutEvent, ShortcutOptions, ShortcutScope};
use nativeapi::shortcut_manager::ShortcutManager;

fn main() {
    // --- 1. Platform support ---
    if !ShortcutManager::is_supported() {
        println!("Global shortcuts are not supported on this platform.");
        return;
    }

    // --- 2. Events ---
    let listener = ShortcutManager::add_listener(|event| match event {
        ShortcutEvent::Activated {
            shortcut_id,
            accelerator,
        } => println!("[shortcut] {shortcut_id} activated ({accelerator:?})"),
        ShortcutEvent::RegistrationFailed {
            accelerator,
            error_message,
            ..
        } => println!("[shortcut] {accelerator:?} failed: {error_message:?}"),
        other => println!("[shortcut] {other:?}"),
    });

    // --- 3. Validation, before trying to register ---
    for candidate in ["Ctrl+Shift+A", "NotAKey"] {
        println!(
            "{candidate}: valid={} available={}",
            ShortcutManager::is_valid_accelerator(candidate),
            ShortcutManager::is_available(candidate)
        );
    }

    // --- 4. Register with a bare callback ---
    let hits = Arc::new(AtomicUsize::new(0));
    let counter = Arc::clone(&hits);
    let first = ShortcutManager::register_with_accelerator_and_callback("Ctrl+Shift+A", move || {
        let count = counter.fetch_add(1, Ordering::Relaxed) + 1;
        println!("Ctrl+Shift+A fired {count} time(s)");
    });
    match &first {
        Some(shortcut) => println!("Registered #{} -> {:?}", shortcut.id(), shortcut.accelerator()),
        None => println!("Could not register Ctrl+Shift+A"),
    }

    // --- 5. Register with full options ---
    let options = ShortcutOptions {
        accelerator: Some("Ctrl+Shift+B".to_string()),
        callback: Some(Arc::new(|| println!("Ctrl+Shift+B fired"))),
        description: Some("Second demo shortcut".to_string()),
        scope: ShortcutScope::Global,
        enabled: true,
    };
    let second = ShortcutManager::register_with_options(&options);
    if let Some(shortcut) = &second {
        println!(
            "Registered #{} scope={:?} description={:?}",
            shortcut.id(),
            shortcut.scope(),
            shortcut.description()
        );

        // Enable/disable without unregistering.
        shortcut.set_enabled(false);
        println!("Disabled -> is_enabled = {}", shortcut.is_enabled());
        shortcut.set_enabled(true);

        shortcut.set_description("Updated description");
        println!("Description now {:?}", shortcut.description());

        // Invoking directly is what a test harness would do.
        shortcut.invoke();
    }

    // --- 6. Enumerate ---
    println!("All shortcuts: {}", ShortcutManager::get_all().len());
    println!(
        "Global scope:  {}",
        ShortcutManager::get_by_scope(ShortcutScope::Global).len()
    );
    if let Some(found) = ShortcutManager::get_with_accelerator("Ctrl+Shift+A") {
        println!("Lookup by accelerator -> #{}", found.id());
    }

    println!("Activations so far: {}", hits.load(Ordering::Relaxed));

    // --- 7. Clean up ---
    if let Some(shortcut) = &first {
        ShortcutManager::unregister_with_id(shortcut.id());
    }
    ShortcutManager::unregister_with_accelerator("Ctrl+Shift+B");
    let remaining = ShortcutManager::unregister_all();
    println!("Unregistered {remaining} remaining shortcut(s)");
    ShortcutManager::remove_listener(listener);
}
