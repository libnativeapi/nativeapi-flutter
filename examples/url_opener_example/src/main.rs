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

    println!("Opening: {url}");

    // --- 3. Open it ---
    let opener = UrlOpener {
        handle: std::ptr::null_mut(),
    };

    // 模版会自动将 &str 转为 CString 再传给 C API
    let _result = opener.open(&url);

    println!("Done (see system browser).");
}
