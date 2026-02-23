//! Application management module

use crate::{Error, Result};
use cnativeapi::{
    native_application_add_event_listener, native_application_event_t,
    native_application_get_instance, native_application_is_running, native_application_quit,
    native_application_run, native_application_run_with_window, native_application_set_icon,
    native_application_t, native_run_app, to_cstring,
};
use std::sync::{Arc, Mutex};

/// High-level application wrapper
pub struct Application {
    handle: native_application_t,
    event_listeners: Arc<Mutex<Vec<Box<dyn Fn(&native_application_event_t) + Send + Sync>>>>,
}

impl Application {
    /// Get the singleton application instance
    pub fn get_instance() -> Result<Self> {
        let handle = unsafe { native_application_get_instance() };
        if handle.is_null() {
            return Err(Error::NullPointer);
        }

        Ok(Application {
            handle,
            event_listeners: Arc::new(Mutex::new(Vec::new())),
        })
    }

    /// Run the application event loop
    pub fn run(&self) -> Result<i32> {
        let exit_code = unsafe { native_application_run(self.handle) };
        Ok(exit_code)
    }

    /// Run the application with a specific window
    pub fn run_with_window(&self, window: &crate::Window) -> Result<i32> {
        let exit_code = unsafe { native_application_run_with_window(self.handle, window.handle()) };
        Ok(exit_code)
    }

    /// Request the application to quit
    pub fn quit(&self, exit_code: i32) {
        unsafe {
            native_application_quit(self.handle, exit_code);
        }
    }

    /// Check if the application is running
    pub fn is_running(&self) -> bool {
        unsafe { native_application_is_running(self.handle) }
    }

    /// Set the application icon
    pub fn set_icon(&self, icon_path: &str) -> Result<bool> {
        let c_path = to_cstring(icon_path)?;
        let success = unsafe { native_application_set_icon(self.handle, c_path.as_ptr()) };
        Ok(success)
    }

    /// Add an event listener
    pub fn add_event_listener<F>(&self, callback: F) -> Result<usize>
    where
        F: Fn(&native_application_event_t) + Send + Sync + 'static,
    {
        let mut listeners = self.event_listeners.lock().unwrap();
        let listener_id = listeners.len();
        listeners.push(Box::new(callback));

        // Create a C-compatible callback
        extern "C" fn event_callback(event: *const native_application_event_t) {
            if !event.is_null() {
                let event = unsafe { &*event };
                // In a real implementation, you'd need a way to map this back to the Rust callback
                // This is a simplified version
                println!("Event received: {:?}", event);
            }
        }

        let c_listener_id =
            unsafe { native_application_add_event_listener(self.handle, Some(event_callback)) };

        if c_listener_id == 0 {
            listeners.pop(); // Remove the listener we just added
            return Err(Error::Application(
                "Failed to add event listener".to_string(),
            ));
        }

        Ok(listener_id)
    }
}

/// Convenience function to run an application with a window
pub fn run_app(window: &crate::Window) -> Result<i32> {
    let exit_code = unsafe { native_run_app(window.handle()) };
    Ok(exit_code)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_application_creation() {
        // Note: This test may fail in CI environments without a display
        if let Ok(app) = Application::get_instance() {
            assert!(!app.handle.is_null());
        }
    }
}
