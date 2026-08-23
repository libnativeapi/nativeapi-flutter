# nativeapi

A modern cross-platform C++ library providing seamless, unified access to native system APIs across multiple platforms.

🚧 Work in Progress: This package is currently under active development.

## Requirements

### Build Requirements

- CMake 3.10 or later
- C++17 compatible compiler:
  - Windows: Visual Studio 2017 or later / MinGW-w64
  - macOS: Xcode 9.0 or later (Clang)
  - Linux: GCC 7.0+ or Clang 5.0+

### Platform-specific Dependencies

#### Linux

- GTK 3.0 development headers

```bash
# Ubuntu/Debian
sudo apt-get install libgtk-3-dev

# CentOS/RHEL/Fedora
sudo yum install gtk3-devel
# or
sudo dnf install gtk3-devel
```

#### macOS

- Cocoa framework (included with Xcode)

#### Windows

- Windows SDK

## Building from Source

### Quick Start

```bash
# Clone the repository
git clone https://github.com/libnativeapi/nativeapi.git
cd nativeapi
```

```bash
# Create build directory
mkdir build
cd build

# Configure and build
cmake ..
cmake --build . --config Release
```

## Development

### Code Formatting

Format the codebase using clang-format:

```bash
clang-format -i **/*.cpp **/*.h **/*.mm
```

## Language Bindings

Currently available language bindings for nativeapi:

- [nativeapi-flutter](https://github.com/libnativeapi/nativeapi-flutter) - Flutter bindings
- [nativeapi-swift](https://github.com/leanflutter/nativeapi-swift) - Swift bindings

These bindings provide native system API access while preserving the library's core functionality.

## License

[MIT](./LICENSE)
