## 0.4.0

The first release built from the nativeapi repository, where the Rust binding now
lives next to the other bindings and is generated from the C++ headers of
[nativeapi-core](https://github.com/libnativeapi/nativeapi-core).

* `nativeapi` covers the whole core API: `Application`, `Window` and
  `WindowManager` (title bar styles, visual effects, custom shadows, window and
  input shapes, drag sessions), `TrayIcon`, `Menu`, `Display` and
  `DisplayManager`, keyboard monitoring and global shortcuts, file and message
  dialogs, drag and drop, notifications, launch at login, preferences and secure
  storage, URL opening, accessibility, app and device info, and native views
  (`View`, `Label`, `Button`, `TextField`, `ImageView`).
* Callbacks are released once the core lets them go: a listener when it is
  removed or its emitter destroyed, a replaced callback, and any callback whose
  registration failed.
* `cnativeapi` carries a copy of the core sources and builds them with CMake
  from `build.rs`; building needs CMake and a C++17 compiler, and on Linux GTK 3,
  X11 and XInput development packages.
* The `nativeapi` crate no longer ships a placeholder `nativeapi` binary.

## 0.0.1

* Initial release.
