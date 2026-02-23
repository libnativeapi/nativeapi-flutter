//! Window management module

use crate::{Error, Result};
use cnativeapi::{
    from_cstring, native_window_focus, native_window_get_id, native_window_get_position,
    native_window_get_size, native_window_get_title, native_window_hide, native_window_id_t,
    native_window_is_focused, native_window_is_visible, native_window_manager_create,
    native_window_manager_destroy, native_window_options_create, native_window_options_destroy,
    native_window_options_set_centered, native_window_options_set_maximum_size,
    native_window_options_set_minimum_size, native_window_options_set_size,
    native_window_options_set_title, native_window_set_position, native_window_set_size,
    native_window_set_title, native_window_show, native_window_t, to_cstring,
};
use std::ffi::CString;

/// Window creation options
#[derive(Debug, Clone)]
pub struct WindowOptions {
    pub title: String,
    pub size: (f64, f64),
    pub minimum_size: Option<(f64, f64)>,
    pub maximum_size: Option<(f64, f64)>,
    pub centered: bool,
}

impl Default for WindowOptions {
    fn default() -> Self {
        Self {
            title: "Native API Window".to_string(),
            size: (800.0, 600.0),
            minimum_size: None,
            maximum_size: None,
            centered: true,
        }
    }
}

/// High-level window wrapper
pub struct Window {
    handle: native_window_t,
    id: native_window_id_t,
    _title: CString, // Keep the CString alive
}

impl Window {
    /// Create a new window with the given options
    pub fn new(options: WindowOptions) -> Result<Self> {
        let title_cstring = to_cstring(&options.title)?;

        // Create native window options
        let native_options = unsafe { native_window_options_create() };
        if native_options.is_null() {
            return Err(Error::WindowCreationFailed);
        }

        // Set up the native options using the new API
        unsafe {
            // Set title
            native_window_options_set_title(native_options, title_cstring.as_ptr());

            // Set size
            native_window_options_set_size(native_options, options.size.0, options.size.1);

            // Set minimum size if provided
            if let Some((min_w, min_h)) = options.minimum_size {
                native_window_options_set_minimum_size(native_options, min_w, min_h);
            }

            // Set maximum size if provided
            if let Some((max_w, max_h)) = options.maximum_size {
                native_window_options_set_maximum_size(native_options, max_w, max_h);
            }

            // Set centered option
            native_window_options_set_centered(native_options, options.centered);
        }

        // Create the window using window manager
        let handle = unsafe { native_window_manager_create(native_options) };

        // Clean up the options
        unsafe {
            native_window_options_destroy(native_options);
        }

        if handle.is_null() {
            return Err(Error::WindowCreationFailed);
        }

        // Get the window ID
        let id = unsafe { native_window_get_id(handle) };

        Ok(Window {
            handle,
            id,
            _title: title_cstring,
        })
    }

    /// Get the native window handle (for internal use)
    pub(crate) fn handle(&self) -> native_window_t {
        self.handle
    }

    /// Show the window
    pub fn show(&self) {
        unsafe {
            native_window_show(self.handle);
        }
    }

    /// Hide the window
    pub fn hide(&self) {
        unsafe {
            native_window_hide(self.handle);
        }
    }

    /// Set the window title
    pub fn set_title(&mut self, title: &str) -> Result<()> {
        self._title = to_cstring(title)?;
        unsafe {
            native_window_set_title(self.handle, self._title.as_ptr());
        }
        Ok(())
    }

    /// Get the window title
    pub fn get_title(&self) -> Result<String> {
        unsafe {
            let title_ptr = native_window_get_title(self.handle);
            if let Some(title_str) = from_cstring(title_ptr) {
                Ok(title_str.to_string())
            } else {
                Err(Error::NullPointer)
            }
        }
    }

    /// Set the window size
    pub fn set_size(&self, width: f64, height: f64) {
        unsafe {
            native_window_set_size(self.handle, width, height, false);
        }
    }

    /// Get the window size
    pub fn get_size(&self) -> (f64, f64) {
        unsafe {
            let size = native_window_get_size(self.handle);
            (size.width, size.height)
        }
    }

    /// Set the window position
    pub fn set_position(&self, x: f64, y: f64) {
        unsafe {
            native_window_set_position(self.handle, x, y);
        }
    }

    /// Get the window position
    pub fn get_position(&self) -> (f64, f64) {
        unsafe {
            let position = native_window_get_position(self.handle);
            (position.x, position.y)
        }
    }

    /// Center the window on screen
    /// Note: This is a simplified implementation that assumes standard screen size
    pub fn center(&self) {
        // Get current window size
        let (width, height) = self.get_size();

        // Assume standard screen size (this could be improved by querying actual screen size)
        let screen_width = 1920.0;
        let screen_height = 1080.0;

        // Calculate center position
        let center_x = (screen_width - width) / 2.0;
        let center_y = (screen_height - height) / 2.0;

        // Set the centered position
        self.set_position(center_x, center_y);
    }

    /// Check if the window is visible
    pub fn is_visible(&self) -> bool {
        unsafe { native_window_is_visible(self.handle) }
    }

    /// Check if the window is focused
    pub fn is_focused(&self) -> bool {
        unsafe { native_window_is_focused(self.handle) }
    }

    /// Focus the window
    pub fn focus(&self) {
        unsafe {
            native_window_focus(self.handle);
        }
    }
}

impl Drop for Window {
    fn drop(&mut self) {
        if !self.handle.is_null() {
            unsafe {
                native_window_manager_destroy(self.id);
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_window_options_default() {
        let options = WindowOptions::default();
        assert_eq!(options.title, "Native API Window");
        assert_eq!(options.size, (800.0, 600.0));
        assert!(options.centered);
    }
}
