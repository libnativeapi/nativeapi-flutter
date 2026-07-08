//! UrlOpener example — demonstrates how to check URL opening support
//! and open URLs using the system default browser.
//!
//! Usage:
//!   cargo run -p url_opener_example
//!   cargo run -p url_opener_example -- "https://www.example.com"

use nativeapi::UrlOpener;

fn main() {
    // --- 1. Check support ---
    let supported = UrlOpener::is_supported();
    println!("URL opening supported: {supported}");

    if !supported {
        eprintln!("URL opening is not supported on this platform.");
        std::process::exit(1);
    }

    // --- 2. Pick a URL ---
    let url = std::env::args()
        .nth(1)
        .unwrap_or_else(|| "https://www.rust-lang.org".to_string());

    // --- 3. Check if the URL can be opened ---
    if UrlOpener::can_open(&url) {
        println!("Opening: {url}");

        // --- 4. Open it ---
        let result = UrlOpener::open(&url);
        println!("Success: {}, error_code: {:?}", result.success, result.error_code);
    } else {
        eprintln!("Cannot open URL: {url}");
    }

    println!("Done (see system browser).");
}
