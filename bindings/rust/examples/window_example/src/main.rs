//! Window example — creates a window, walks through its geometry, style and
//! state flags, and subscribes to window events.
//!
//! The window is never shown: this runs without an event loop so it stays
//! useful in a terminal. `application_example` shows the loop.
//!
//! Usage:
//!   cargo run -p window_example

use nativeapi::geometry::{Point, Rectangle, Size};
use nativeapi::window::{TitleBarStyle, VisualEffect, Window, WindowEvent};
use nativeapi::window_manager::WindowManager;

fn main() {
    // --- 1. Create ---
    let Some(window) = Window::new() else {
        eprintln!("Failed to create a window.");
        std::process::exit(1);
    };
    println!("Created window #{}", window.id());

    // --- 2. Events ---
    // One listener receives every window event; the payload says which.
    let listener = WindowManager::add_listener(|event| match event {
        WindowEvent::Focused { window_id } => println!("[event] window {window_id} focused"),
        WindowEvent::Blurred { window_id } => println!("[event] window {window_id} blurred"),
        WindowEvent::Moved {
            window_id,
            new_position,
        } => println!(
            "[event] window {window_id} moved to ({}, {})",
            new_position.x, new_position.y
        ),
        WindowEvent::Resized {
            window_id,
            new_size,
        } => println!(
            "[event] window {window_id} resized to {}x{}",
            new_size.width, new_size.height
        ),
        other => println!("[event] {other:?}"),
    });
    println!("Registered window listener #{listener}");

    // --- 3. Title and geometry ---
    window.set_title("Rust Window Example");
    println!("Title: {:?}", window.title());

    window.set_size(
        &Size {
            width: 800.0,
            height: 600.0,
        },
        false,
    );
    window.set_minimum_size(&Size {
        width: 400.0,
        height: 300.0,
    });
    window.set_position(&Point { x: 120.0, y: 80.0 });
    window.center();

    let bounds: Rectangle = window.bounds();
    println!(
        "Bounds: ({}, {}) {}x{}",
        bounds.x, bounds.y, bounds.width, bounds.height
    );
    println!("Content size: {:?}", window.content_size());

    // --- 4. Style ---
    window.set_title_bar_style(TitleBarStyle::Hidden);
    window.set_visual_effect(VisualEffect::Blur);
    window.set_opacity(0.95);
    window.set_has_shadow(true);
    println!(
        "Title bar: {:?}, visual effect: {:?}, opacity: {}",
        window.title_bar_style(),
        window.visual_effect(),
        window.opacity()
    );
    println!("Background color: {:?}", window.background_color());

    // --- 5. Capability flags ---
    window.set_resizable(true);
    window.set_minimizable(true);
    window.set_maximizable(false);
    window.set_always_on_top(true);
    println!(
        "resizable={} minimizable={} maximizable={} always_on_top={}",
        window.is_resizable(),
        window.is_minimizable(),
        window.is_maximizable(),
        window.is_always_on_top()
    );

    // --- 6. State ---
    println!(
        "visible={} focused={} minimized={} maximized={} full_screen={}",
        window.is_visible(),
        window.is_focused(),
        window.is_minimized(),
        window.is_maximized(),
        window.is_full_screen()
    );

    // --- 7. The manager's view of things ---
    let all = WindowManager::get_all();
    println!("WindowManager tracks {} window(s)", all.len());
    if let Some(current) = WindowManager::get_current() {
        println!("Current window: #{}", current.id());
    }
    if let Some(same) = WindowManager::get(window.id()) {
        println!("Looked up window #{} by id", same.id());
    }

    // Hooks run before the native show/hide, which is where a UI framework
    // would slot its own bookkeeping.
    WindowManager::set_will_show_hook(Some(Box::new(|id| {
        println!("[hook] window {id} is about to be shown");
    })));
    println!(
        "has_will_show_hook = {}",
        WindowManager::has_will_show_hook()
    );
    WindowManager::set_will_show_hook(None);

    // --- 8. Clean up ---
    WindowManager::remove_listener(listener);
    // Dropping `window` releases this reference to the handle.
}
