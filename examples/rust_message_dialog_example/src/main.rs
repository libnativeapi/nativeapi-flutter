//! Message dialog example — builds dialogs with each modality and opens them.
//!
//! `open()` shows a *modal* dialog and blocks until the user dismisses it, so
//! it is opt-in — everything else runs unattended.
//!
//! Usage:
//!   cargo run -p message_dialog_example
//!   cargo run -p message_dialog_example -- --open

use nativeapi::dialog::DialogModality;
use nativeapi::message_dialog::MessageDialog;

fn main() {
    // --- 1. Create ---
    let Some(dialog) = MessageDialog::new(
        "Update Available",
        "A new version is available. Would you like to update?",
    ) else {
        eprintln!("Failed to create a message dialog.");
        std::process::exit(1);
    };
    println!("Title:   {:?}", dialog.title());
    println!("Message: {:?}", dialog.message());

    // --- 2. Update the content before showing it ---
    dialog.set_title("System Update");
    dialog.set_message("Version 2.0 is ready to install.");
    println!("Retitled to {:?}", dialog.title());

    // --- 3. Modality ---
    for modality in [
        DialogModality::None,
        DialogModality::Application,
        DialogModality::Window,
    ] {
        dialog.set_modality(modality);
        println!("Modality -> {:?}", dialog.modality());
    }

    // --- 4. Open and close ---
    if !std::env::args().any(|arg| arg == "--open") {
        println!("Pass --open to actually show the dialog (it blocks until dismissed).");
        return;
    }
    dialog.set_modality(DialogModality::Application);
    let opened = dialog.open();
    println!("Opened: {opened}");
    if opened {
        println!("Closed: {}", dialog.close());
    }
}
