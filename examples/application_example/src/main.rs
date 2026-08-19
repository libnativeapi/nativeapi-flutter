//! Application example — wires up an app: a menu bar, a primary window, and
//! lifecycle events, then runs the event loop.
//!
//! This one *does* open a window and block. Pass `--dry-run` to exercise
//! everything except the loop, which is what CI does.
//!
//! Usage:
//!   cargo run -p application_example
//!   cargo run -p application_example -- --dry-run

use nativeapi::application::{Application, ApplicationEvent};
use nativeapi::geometry::Size;
use nativeapi::menu::{Menu, MenuItem, MenuItemType};
use nativeapi::window::Window;

fn main() {
    let dry_run = std::env::args().any(|arg| arg == "--dry-run");

    // --- 1. Lifecycle events ---
    let listener = Application::add_listener(|event| match event {
        ApplicationEvent::Started => println!("[app] started"),
        ApplicationEvent::Exiting { exit_code } => println!("[app] exiting ({exit_code})"),
        ApplicationEvent::Activated => println!("[app] activated"),
        ApplicationEvent::Deactivated => println!("[app] deactivated"),
        ApplicationEvent::QuitRequested => {
            println!("[app] quit requested");
            Application::quit(0);
        }
    });

    println!("Single instance: {}", Application::is_single_instance());

    // --- 2. Menu bar ---
    if let Some(menu_bar) = Menu::new() {
        if let Some(about) = MenuItem::with_label_and_type("About", MenuItemType::Normal) {
            menu_bar.add_item(Some(&about));
        }
        menu_bar.add_separator();
        if let Some(quit) = MenuItem::with_label_and_type("Quit", MenuItemType::Normal) {
            quit.add_listener(|_| Application::quit(0));
            menu_bar.add_item(Some(&quit));
        }
        println!("Menu bar installed: {}", Application::set_menu_bar(Some(&menu_bar)));
    }

    // --- 3. Primary window ---
    let Some(window) = Window::new() else {
        eprintln!("Failed to create a window.");
        std::process::exit(1);
    };
    window.set_title("Rust Application Example");
    window.set_size(
        &Size {
            width: 640.0,
            height: 480.0,
        },
        false,
    );
    window.center();

    Application::set_primary_window(Some(&window));
    if let Some(primary) = Application::get_primary_window() {
        println!("Primary window: #{}", primary.id());
    }
    println!("Known windows: {}", Application::get_all_windows().len());

    // --- 4. Run ---
    if dry_run {
        println!("--dry-run: skipping the event loop.");
        println!("is_running = {}", Application::is_running());
        Application::remove_listener(listener);
        return;
    }

    window.show();
    println!("Running. Close the window or press Ctrl+C to quit.");
    let exit_code = Application::run_with_window(Some(&window));
    println!("Exited with {exit_code}");

    Application::remove_listener(listener);
    std::process::exit(exit_code);
}
