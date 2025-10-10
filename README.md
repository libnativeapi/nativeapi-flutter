# nativeapi

Flutter bindings for [nativeapi](https://github.com/libnativeapi/libnativeapi) - providing seamless, unified access to native system APIs.

🚧 **Work in Progress**: This package is currently under active development.

## Getting Started

Add `nativeapi` to your `pubspec.yaml`:

```yaml
dependencies:
  nativeapi: ^0.1.0-dev.1
```

Then run:

```bash
flutter pub get
```

### Usage

> 📖 Detailed documentation and examples are coming soon!

```dart
import 'package:nativeapi/nativeapi.dart';

// Example usage will be added here
```

## Development

### Prerequisites

- Flutter (>=3.35.0)
- Dart SDK (>=3.9.0)

### Setup

1. Clone the repository:

```bash
git clone https://github.com/libnativeapi/nativeapi-flutter.git
cd nativeapi-flutter
```

2. Initialize submodules:

```bash
git submodule update --init --recursive
```

3. Install dependencies:

```bash
melos bootstrap
```

4. Run the example app:

```bash
cd examples/display_example
flutter run
```

### FFI Bindings

This project uses ffigen to generate Dart FFI bindings from C headers. To regenerate the bindings:

```bash
cd packages/cnativeapi
dart run ffigen --config ffigen.yaml
```

The ffigen configuration is defined in `packages/cnativeapi/ffigen.yaml`. You typically need to regenerate bindings when:
- The native C library (libnativeapi) is updated
- The ffigen configuration is modified

## License

[MIT](./LICENSE)
