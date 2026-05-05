# nativeapi

Flutter bindings for [nativeapi](https://github.com/libnativeapi/libnativeapi) - providing seamless, unified access to native system APIs.

🚧 **Work in Progress**: This package is currently under active development.

## Platform Support

| Android | iOS | Linux | macOS | Windows |
|:-------:|:---:|:-----:|:-----:|:-------:|
| ✅ | ✅ | ✅ | ✅ | ✅ |

## Features

- **Window Management** — create, show, hide, center windows; control title bar style, visual effects, and control buttons
- **Tray Icon** — system tray icon with menu and context menu trigger support
- **Display Management** — enumerate and query multi-screen display info
- **Menu** — native menu system with event callbacks
- **Dialogs** — message dialogs and native dialog APIs
- **Accessibility** — accessibility manager API
- **Preferences** — persistent key-value storage
- **Secure Storage** — encrypted key-value storage
- **URL Opener** — open URLs with the system default browser/handler
- **Positioning** — flexible window positioning strategies and placement support
- **Widgets** — `ContextMenuRegion` for context menu integration

## Getting Started

Add `nativeapi` to your `pubspec.yaml`:

```yaml
dependencies:
  nativeapi: ^0.1.1
```

Then run:

```bash
flutter pub get
```

## Usage

```dart
import 'package:nativeapi/nativeapi.dart';

// Window management - get the current window and manipulate it
final windowManager = WindowManager.instance;
final window = windowManager.getCurrent();
window?.show();
window?.center();
window?.titleBarStyle = TitleBarStyle.hidden;

// Listen to window events
windowManager.addCallbackListener<WindowFocusedEvent>((event) {
  print('Window focused: ${event.windowId}');
});

// Tray icon
final trayIcon = TrayIcon();
trayIcon.icon = Image.fromAsset('assets/tray_icon.png');
trayIcon.contextMenu = Menu();
trayIcon.contextMenuTrigger = ContextMenuTrigger.rightClicked;
trayIcon.on<TrayIconClickedEvent>((event) {
  print('Tray icon clicked');
});

// URL opener (synchronous)
final result = UrlOpener.instance.open('https://example.com');
print('Opened: ${result.success}');

// Preferences (synchronous, dispose when done)
final prefs = Preferences();
prefs.set('theme', 'dark');
final theme = prefs.get('theme', 'light'); // second arg is default value
prefs.dispose();
```

> 📖 More detailed documentation and examples are coming soon. See the [`examples/`](https://github.com/libnativeapi/nativeapi-flutter/tree/main/examples) directory for working sample apps.

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

4. Run an example app:

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
- The native C library ([libnativeapi/nativeapi](https://github.com/libnativeapi/nativeapi)) is updated
- The ffigen configuration is modified

## License

[MIT](./LICENSE)
