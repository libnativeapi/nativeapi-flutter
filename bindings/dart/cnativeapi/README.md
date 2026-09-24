# cnativeapi

Raw Dart FFI bindings to the C API of [libnativeapi](https://github.com/libnativeapi/nativeapi-core), generated with [ffigen](https://pub.dev/packages/ffigen).

> This package provides low-level FFI bindings and is typically used as an internal dependency of [`nativeapi`](https://pub.dev/packages/nativeapi). You generally don't need to depend on it directly.

It is a plain Dart package and does not depend on Flutter. Its [build hook](https://dart.dev/tools/hooks) (`hook/build.dart`) compiles the nativeapi core into a shared library whenever a Dart or Flutter app that depends on it is built, and every function is an `@Native` external bound to that library.

## Platform Support

| Android | iOS | Linux | macOS | Windows |
|:-------:|:---:|:-----:|:-----:|:-------:|
| ✅ | ✅ | ✅ | ✅ | ✅ |

Building needs a C++17 toolchain for the target: Xcode on macOS and iOS, the Android NDK, Visual Studio on Windows, and on Linux clang or GCC plus the GTK 3, X11 and Xi development packages (found with `pkg-config`).

## Usage

```dart
import 'package:cnativeapi/cnativeapi.dart';
```

See [example/cnativeapi_example.dart](example/cnativeapi_example.dart); run it with `dart run example/cnativeapi_example.dart`.

For higher-level Dart APIs, use the [`nativeapi`](https://pub.dev/packages/nativeapi) package instead.

## Regenerating Bindings

Bindings are generated from the C headers in `core/src/capi/`. From the repository root:

```bash
./codegen
```

or, for this package alone, `./codegen ffigen` (set `LIBCLANG_PATH` if ffigen cannot find libclang).

## License

[MIT](./LICENSE)
