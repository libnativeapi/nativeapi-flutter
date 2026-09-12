# Native API examples

The main example links to **Desktop Features: Dialogs, Pickers, Notifications**.
Run the same page directly with `flutter run -d windows --target lib/desktop_features.dart`.

## Windows WinUI 3 tests

From the Flutter repository root (`bindings/flutter` in the workspace):

```powershell
./tools/run_windows_example.ps1 -Example desktop -WinUI3
./tools/run_windows_example.ps1 -Example window -WinUI3
./tools/run_windows_example.ps1 -Example menu -WinUI3
```

The launcher restores core's pinned build packages and bundles the bootstrap DLL
beside the executable. Visual Studio with desktop C++ tools and Windows App Runtime
1.6 are required. See [core's WinUI guide](../../cnativeapi/cxx_impl/docs/winui3.md)
for runtime setup. Omit `-WinUI3` to test Win32; add `-BuildOnly` to compile without
launching. The launcher restores the caller's environment variables when it exits.

| Example | What to test |
| --- | --- |
| `desktop`: file pickers | Open one/multiple `.txt` or `.png` files, save with a suggested `.txt` filename, select a folder, cancel. Inspect result, paths and errors. WinRT save may create an empty file. |
| `desktop`: message dialog | Basic/extended dialogs inside the current window, primary/secondary/close results, default button, input and checkbox state; none/window/application modality. Resize/maximize the parent while open. Use **Auto progress + close (5s)** to test live updates and programmatic closing. |
| `desktop`: notifications | Check initialization, send twice to replace the tag, click the banner/action and inspect the activation argument, remove the tagged notification. OS settings may suppress banners. |
| `window`: Appearance | Apply indigo/white title-bar colors to the selected window, then reset them. |
| `menu`: app bar backend selector | Switch native/WinUI 3 and test context and positioning menus, including submenus. Unsupported options are disabled. |

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
