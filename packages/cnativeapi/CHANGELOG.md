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
