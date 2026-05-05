# cnativeapi

Native API C bindings for Flutter, auto-generated via [ffigen](https://pub.dev/packages/ffigen) from the [libnativeapi](https://github.com/libnativeapi/nativeapi) C library.

> This package provides low-level FFI bindings and is typically used as an internal dependency of [`nativeapi`](https://pub.dev/packages/nativeapi). You generally don't need to depend on it directly.

## Platform Support

| Android | iOS | Linux | macOS | Windows |
|:-------:|:---:|:-----:|:-----:|:-------:|
| ✅ | ✅ | ✅ | ✅ | ✅ |

## Usage

If you need to use the raw C bindings directly:

```dart
import 'package:cnativeapi/cnativeapi.dart';
```

For higher-level Dart APIs, use the [`nativeapi`](https://pub.dev/packages/nativeapi) package instead.

## Regenerating Bindings

Bindings are generated from C headers using `ffigen`. To regenerate:

```bash
cd packages/cnativeapi
dart run ffigen --config ffigen.yaml
```

Regeneration is needed when:
- The native C library ([libnativeapi/nativeapi](https://github.com/libnativeapi/nativeapi)) is updated
- The `ffigen.yaml` configuration is modified

## License

[MIT](./LICENSE)
