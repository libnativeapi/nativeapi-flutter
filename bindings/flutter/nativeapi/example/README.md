# Native API examples

The main example links to **Desktop Features: Dialogs, Pickers, Notifications**.
Run the same page directly with `flutter run -d windows --target lib/desktop_features.dart`.

## Windows WinUI 3 tests

WinUI 3 is a build-time option of core (`NATIVEAPI_ENABLE_WINUI3` and the package
paths it needs are CMake cache variables; see
[core's WinUI guide](https://github.com/libnativeapi/nativeapi-core/blob/main/docs/winui3.md)).
The Flutter plugin does not forward them to core's build yet, so a Flutter build is
always the Win32 backend; test the WinUI 3 backends through core's C++ examples until
it does. The checks below apply to both backends. The `window`, `menu` and `tray`
rows are the repository's `examples/flutter_window_example`,
`examples/flutter_menu_example` and `examples/flutter_tray_icon_example`; `desktop`
is this example:

```powershell
flutter run -d windows --target lib/desktop_features.dart
```

| Example | What to test |
| --- | --- |
| `desktop`: file pickers | Open one/multiple `.txt` or `.png` files, save with a suggested `.txt` filename, select a folder, cancel. Inspect result, paths and errors. WinRT save may create an empty file. |
| `desktop`: message dialog | Basic/extended dialogs inside the current window, primary/secondary/close results, default button, input and checkbox state; none/window/application modality. Resize/maximize the parent while open. Use **Auto progress + close (5s)** to test live updates and programmatic closing. |
| `desktop`: notifications | Check initialization, send twice to replace the tag, click the banner/action and inspect the activation argument, remove the tagged notification. OS settings may suppress banners. |
| `window`: Appearance | Apply indigo/white title-bar colors to the selected window, then reset them. |
| `menu`: app bar backend selector | Switch native/WinUI 3 and test context and positioning menus, including submenus. Unsupported options are disabled. |
| `tray`: app bar backend selector | Starts with one tray icon and right-click trigger. Right-click the tray icon or press **Open Menu** on its card; test items and nested submenus. Switching backend applies to existing and newly created tray icons. |

Menu and tray examples select WinUI 3 initially when supported, otherwise Native.
The menu example's checkbox/disabled-item reproduction also uses the selected backend.

File pickers are currently implemented on Windows. Extended dialogs, notifications
and title-bar colors require WinUI 3. Unsupported APIs and operation failures are
reported on screen. Results retain the latest 100 entries and can be copied.

Use Flutter's main isolate with merged platform/UI threads for native UI and
synchronous callbacks. Do not move these calls into a worker isolate.

The WinUI dialog covers the current window's client area with a dimming layer,
without adding another captioned window. Underlying content is blocked even for
`none` (asynchronous presentation); the automatic test uses a timer to update it.
Closing restores the original content and focus. Parentless/tray-only callers
still use core's standalone fallback.

The notification listener is registered before initialization and removed when the
page is disposed. This example tests activation while running; production apps must
also handle notification-triggered startup and shutdown.
