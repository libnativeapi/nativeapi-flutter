## 0.2.3

* Add `native_window_set_non_activating` / `native_window_is_non_activating`
* macOS: `native_window_set_focusable` is now implemented (it was a no-op)

## 0.2.2

* Fix macOS build failure in 0.2.1: `redefinition of 'ToStdString'`. The macOS unity
  build compiles every platform `.mm` into one translation unit, and `app_info`,
  `device_info` and `launch_at_login` each defined that helper privately

## 0.2.1

* Update `cxx_impl` to core 5a5afc7
* Add `AppInfo` C bindings (name, identifier, version, build number)
* Add `DeviceInfo` C bindings (name, model, manufacturer, OS, kernel, architecture)
* Fix window focused/blurred events never being dispatched on macOS, Windows and Linux

## 0.2.0

* Regenerate the complete C bindings from the new code generator
* Unify the object identity/lifecycle model with a generational handle table
* Fix tray icon bounds on multi-display setups (macOS)
* Fix macOS global shortcuts never firing
* Rewrite EventEmitter locking and dispatch; add a main-thread dispatcher
* Add `UrlOpener` CanOpen support
* Require C++17 and propagate the requirement to consumers
* Remove the obsolete Python bindgen tooling

## 0.1.4

* Fix macOS menu item disabled state not being respected
* Fix Windows window `SetMinimumSize`/`SetMaximumSize` not working
* Add per-monitor DPI scaling for Windows display and window geometry
* Track menu item enabled state and update flags on Windows
* Adjust Linux tray icon menu trigger handling

## 0.1.3

* Remove duplicate macOS deployment target build setting from the podspec
* Update storage example Darwin integration to use Swift Package Manager

## 0.1.2

* Add LaunchAtLogin C bindings

## 0.1.1

* Add multi-platform FFI C bindings (Android, iOS, Linux, macOS, Windows)
* Migrate iOS and macOS native bindings to SwiftPM
* Add UrlOpener C bindings
* Add autostart and global shortcuts C bindings
* Add window visual effects and color C bindings
* Add title bar style and control button C bindings
* Introduce bindgen code generation toolchain

## 0.1.0

* Initial release
