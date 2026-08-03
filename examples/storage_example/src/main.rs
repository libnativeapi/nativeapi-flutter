//! Storage example — writes and reads key/value pairs through Preferences,
//! and reports whether SecureStorage is available on this platform.
//!
//! Usage:
//!   cargo run -p storage_example

use nativeapi::{Preferences, SecureStorage};

fn main() {
    let prefs = Preferences::with_scope("com.example.codegen-demo")
        .expect("failed to create preferences");

    println!("Scope: {}", prefs.scope().unwrap_or_default());

    // --- 1. Write ---
    prefs.set("theme", "dark");
    prefs.set("language", "zh-CN");
    println!("Stored {} item(s)", prefs.size());

    // --- 2. Read back ---
    println!("theme    = {:?}", prefs.get("theme", ""));
    println!("missing  = {:?}", prefs.get("missing", "fallback"));
    println!("contains(language) = {}", prefs.contains("language"));

    // --- 3. Containers ---
    // NOTE: on macOS these currently report the merged NSUserDefaults view,
    // not just this scope — a platform-implementation issue, not a binding one.
    let keys = prefs.keys();
    println!("keys returned: {}", keys.len());
    println!("theme in keys: {}", keys.iter().any(|key| key == "theme"));

    let all = prefs.all();
    println!("all returned:  {} entry/entries", all.len());
    println!("all[\"language\"] = {:?}", all.get("language"));

    // --- 4. Clean up ---
    // NOTE: `clear()` is intentionally not called here. On macOS the platform
    // implementation iterates the *merged* NSUserDefaults view, so it would try
    // to delete keys that do not belong to this scope.
    prefs.remove("theme");
    prefs.remove("language");
    println!("after remove: {} item(s)", prefs.size());

    // --- 5. Secure storage ---
    println!("\nSecureStorage available: {}", SecureStorage::is_available());
}
