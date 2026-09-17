# nativeapi-rust

Rust bindings for [nativeapi](https://github.com/libnativeapi/nativeapi) — unified access to native system APIs: windows, tray icons, menus, displays, keyboard, dialogs, storage and more.

| Linux | macOS | Windows |
|:-----:|:-----:|:-------:|
| ✅ | ✅ | ✅ |

🚧 **Work in Progress**: this crate is under active development.

## Installation

```bash
cargo add nativeapi
```

Building requires CMake and a C++17 compiler (the core library is compiled by `build.rs`). On Linux, also install:

```bash
sudo apt install libgtk-3-dev libx11-dev libxi-dev libayatana-appindicator3-dev
```

The crate is split into `nativeapi` (safe API) and `cnativeapi` (raw FFI).

## Quick Start

```rust
use nativeapi::DisplayManager;

fn main() {
    for display in DisplayManager::get_all() {
        let size = display.size();
        println!("{}: {}x{}", display.name().unwrap_or_default(), size.width, size.height);
    }
}
```

## Examples

See [`examples/`](examples). Each directory is a crate covering one module:

```bash
cargo run -p display_example
cargo run -p window_example
cargo run -p tray_icon_example
```

`shortcut_example` and `keyboard_example` need accessibility permission on macOS — run `accessibility_example` first.

## Contributing

This repository is developed from the [workspace](https://github.com/libnativeapi/workspace), which checks out the core library, every binding and the code generator together:

```bash
git clone --recursive https://github.com/libnativeapi/workspace.git
```

Files marked `AUTO-GENERATED. DO NOT EDIT.` are generated from the C++ headers in [nativeapi](https://github.com/libnativeapi/nativeapi). To change the API, send a pull request there; maintainers regenerate the bindings.

- API requests and native behavior bugs → [nativeapi issues](https://github.com/libnativeapi/nativeapi/issues)
- Bugs specific to one binding → that binding's repository
- Not sure → [nativeapi issues](https://github.com/libnativeapi/nativeapi/issues)

## License

MIT
