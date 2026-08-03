# Native API Rust

A Rust wrapper for the [nativeapi](https://github.com/libnativeapi/nativeapi) C/C++ library, providing seamless, unified access to native system APIs across different platforms.

## Overview

This project integrates the C/C++ nativeapi library as a git submodule and provides both low-level FFI bindings and high-level Rust APIs for cross-platform native system operations including:

- **Window Management**: Create, manage, and manipulate native windows
- **Application Lifecycle**: Handle application events and lifecycle management
- **Cross-platform Support**: Works on macOS, Windows, Linux, iOS, and Android

## Project Structure

```
nativeapi-rust/
├── crates/
│   ├── cnativeapi/           # Low-level C FFI bindings
│   │   ├── src/lib.rs        # Rust FFI declarations
│   │   ├── build.rs          # CMake build script
│   │   ├── cxx_impl/   # Git submodule (C/C++ implementation)
│   │   └── Cargo.toml
│   └── nativeapi/            # High-level Rust API
│       ├── src/
│       │   ├── lib.rs        # Main library interface
│       │   ├── application.rs # Application management
│       │   └── window.rs     # Window management
│       ├── examples/         # Usage examples
│       └── Cargo.toml
├── Cargo.toml               # Workspace configuration
└── README.md
```

## Installation and Setup

### Prerequisites

- **Rust**: Install from [rustup.rs](https://rustup.rs/)
- **CMake**: Required for building the C/C++ library
  - macOS: `brew install cmake`
  - Linux: `sudo apt install cmake` or `sudo dnf install cmake`
  - Windows: Download from [cmake.org](https://cmake.org/download/)
- **C++ Compiler**: 
  - macOS: Xcode Command Line Tools
  - Linux: GCC or Clang
  - Windows: MSVC or MinGW

### Platform-specific Dependencies

#### Linux
```bash
# Ubuntu/Debian
sudo apt install libgtk-3-dev libx11-dev libxi-dev libayatana-appindicator3-dev

# Fedora/CentOS
sudo dnf install gtk3-devel libX11-devel libXi-devel ayatana-appindicator-gtk3-devel
```

#### macOS
No additional dependencies required (uses Cocoa framework).

#### Windows
No additional dependencies required (uses Win32 API).

### Build Instructions

1. **Clone with submodules**:
```bash
git clone --recursive https://github.com/yourusername/nativeapi-rust.git
cd nativeapi-rust
```

2. **Build the project**:
```bash
cargo build
```

3. **Build examples**:
```bash
cargo build --examples
```

## Usage Examples

### Basic Window Creation

```rust
use nativeapi::{init, Window, WindowOptions, Result};

fn main() -> Result<()> {
    // Initialize the library
    init()?;
    
    // Create window options
    let options = WindowOptions {
        title: "My Native Window".to_string(),
        size: (800.0, 600.0),
        centered: true,
        ..Default::default()
    };
    
    // Create and show window
    let mut window = Window::new(options)?;
    window.show();
    
    // Window operations
    window.set_title("Updated Title")?;
    window.set_size(1000.0, 700.0);
    
    Ok(())
}
```

### Application Lifecycle Management

```rust
use nativeapi::{init, run_app, Window, WindowOptions, Result};

fn main() -> Result<()> {
    init()?;
    
    let options = WindowOptions::default();
    let window = Window::new(options)?;
    
    // Run the application event loop
    let exit_code = run_app(&window)?;
    println!("Application exited with code: {}", exit_code);
    
    Ok(())
}
```

### Low-Level FFI Usage

```rust
use cnativeapi::*;
use std::ffi::CString;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Direct C API usage
    let options = unsafe { native_window_options_create() };
    let title = CString::new("FFI Window")?;
    
    unsafe {
        (*options).title = title.as_ptr() as *mut _;
        (*options).size = NativeSize { width: 640.0, height: 480.0 };
    }
    
    let window = unsafe { native_window_manager_create(options) };
    unsafe { native_window_show(window) };
    
    // Cleanup
    unsafe {
        let window_id = native_window_get_id(window);
        native_window_manager_destroy(window_id);
        native_window_options_destroy(options);
    }
    
    Ok(())
}
```

## Running Examples

Each example is its own crate under `examples/`, covering one module of the
API. They print what they do, so running one is the quickest way to see the
shape of a binding.

```bash
cargo run -p display_example          # displays, work areas, display events
cargo run -p storage_example          # Preferences and SecureStorage
cargo run -p url_opener_example       # open a URL with the system handler
cargo run -p window_example           # window geometry, style, state, events
cargo run -p menu_example             # menu items, accelerators, submenus
cargo run -p tray_icon_example        # tray icon, context menu, click events
cargo run -p shortcut_example         # global shortcuts and shortcut events
cargo run -p keyboard_example         # keyboard monitor and modifier events
cargo run -p application_example      # menu bar, primary window, event loop
cargo run -p launch_at_login_example  # launch-at-login registration
cargo run -p message_dialog_example   # message dialogs and modality
cargo run -p accessibility_example    # accessibility permission
```

Two of them take arguments:

```bash
cargo run -p application_example -- --dry-run   # skip the blocking event loop
cargo run -p message_dialog_example -- --open   # actually show the modal dialog
cargo run -p url_opener_example -- "https://example.com"
```

Notes:

- `application_example` opens a window and blocks until you close it; the other
  examples finish on their own.
- `shortcut_example` and `keyboard_example` need accessibility permission on
  macOS. Without it they report that registration or monitoring failed rather
  than crashing — run `accessibility_example` first.
- `launch_at_login_example` writes a real login-item registration and then puts
  it back the way it found it.

## API Reference

### High-Level API (`nativeapi` crate)

#### Window Management
- `Window::new(options)` - Create a new window
- `window.show()` / `window.hide()` - Control visibility
- `window.set_title()` / `window.get_title()` - Title management
- `window.set_size()` / `window.get_size()` - Size management
- `window.set_position()` / `window.get_position()` - Position management
- `window.center()` - Center window on screen
- `window.focus()` - Focus the window

#### Application Management
- `Application::get_instance()` - Get application singleton
- `app.run()` - Run the event loop
- `app.quit(exit_code)` - Request application exit
- `run_app(window)` - Convenience function to run with window

### Low-Level API (`cnativeapi` crate)

Direct FFI bindings to the C API. See `examples/low_level_ffi.rs` for usage patterns.

## Cross-Platform Notes

### macOS
- Uses Cocoa framework
- Supports dock icon management
- Native menu bar integration available

### Windows  
- Uses Win32 API
- Supports taskbar integration
- DWM (Desktop Window Manager) integration

### Linux
- Uses GTK+ 3.0
- X11 window management
- System tray support via AppIndicator

### Mobile Platforms
- **iOS**: UIKit integration (requires additional setup)
- **Android**: Native activity support (requires NDK)

## Development

### Adding New Features

1. **C API**: Add functions to the submodule's C API
2. **FFI Bindings**: Update `cnativeapi/src/lib.rs` with new extern declarations
3. **High-Level API**: Add safe wrappers in `nativeapi/src/`
4. **Examples**: Create examples demonstrating new functionality

### Building from Source

```bash
# Clean build
cargo clean
cargo build

# Build with verbose output for debugging
cargo build --verbose

# Build release version
cargo build --release
```

### Testing

```bash
# Run unit tests
cargo test

# Test specific crate
cargo test -p nativeapi
cargo test -p cnativeapi
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests and examples
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [nativeapi](https://github.com/libnativeapi/nativeapi) - The underlying C/C++ library
- Rust community for excellent FFI support
- Platform maintainers for native API documentation

---

For more detailed information, see the API documentation generated by `cargo doc --open`.