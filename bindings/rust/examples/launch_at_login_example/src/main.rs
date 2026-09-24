//! Launch-at-login example — reads the current registration, sets a custom
//! program and arguments where the platform allows it, and toggles the state.
//!
//! Usage:
//!   cargo run -p launch_at_login_example

use nativeapi::launch_at_login::LaunchAtLogin;

fn main() {
    // --- 1. Platform support ---
    if !LaunchAtLogin::is_supported() {
        println!("Launch at login is not supported on this platform.");
        return;
    }

    // On macOS the default constructor registers the main app itself; a custom
    // identifier is for a bundled login-item helper.
    let manager = if cfg!(target_os = "macos") {
        LaunchAtLogin::new()
    } else {
        LaunchAtLogin::with_id_and_display_name("com.example.rust-demo", "Rust Demo")
    };
    let Some(manager) = manager else {
        eprintln!("Failed to create a LaunchAtLogin manager.");
        std::process::exit(1);
    };

    // --- 2. Current configuration ---
    println!("Id:           {:?}", manager.id());
    println!("Display name: {:?}", manager.display_name());
    println!("Executable:   {:?}", manager.executable_path());
    println!("Arguments:    {:?}", manager.arguments());
    println!("Enabled:      {}", manager.is_enabled());

    // --- 3. Customise ---
    manager.set_display_name("Rust Demo (renamed)");
    if !cfg!(target_os = "macos") {
        // macOS SMAppService cannot take an arbitrary executable or arguments.
        if let Some(executable) = manager.executable_path() {
            let arguments = vec!["--minimized".to_string(), "--from-login".to_string()];
            let stored = manager.set_program(&executable, &arguments);
            println!("set_program stored locally: {stored}");
            println!("Arguments now: {:?}", manager.arguments());
        }
    }

    // --- 4. Toggle ---
    // Enabling touches the real OS registration, so put it back afterwards.
    let was_enabled = manager.is_enabled();
    println!("Enabling...  {}", manager.enable());
    println!("Enabled:     {}", manager.is_enabled());
    if !was_enabled {
        println!("Restoring... {}", manager.disable());
    }
    println!("Final state: {}", manager.is_enabled());
}
