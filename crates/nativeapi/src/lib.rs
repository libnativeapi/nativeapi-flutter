//! Native API - Rust bindings for cross-platform native system APIs
//!
//! This crate provides safe, high-level Rust bindings for the nativeapi library,
//! offering seamless access to native system APIs across different platforms.

pub use cnativeapi::{native_point_t, native_rectangle_t, native_size_t};

// Re-export convenience functions
pub use cnativeapi::{from_cstring, to_cstring};

pub mod url_opener;
pub use url_opener::{UrlOpenErrorCode, UrlOpenResult, UrlOpener};

/// Result type for nativeapi operations
pub type Result<T> = std::result::Result<T, Error>;

/// Error types for nativeapi operations
#[derive(Debug, thiserror::Error)]
pub enum Error {
    #[error("Null pointer error")]
    NullPointer,
    #[error("String conversion error: {0}")]
    StringConversion(#[from] std::ffi::NulError),
    #[error("Invalid UTF-8: {0}")]
    InvalidUtf8(#[from] std::str::Utf8Error),
    #[error("Window creation failed")]
    WindowCreationFailed,
    #[error("Application error: {0}")]
    Application(String),
}

/// Initialize the nativeapi library
pub fn init() -> Result<()> {
    // Any initialization code can go here
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_init() {
        assert!(init().is_ok());
    }
}
