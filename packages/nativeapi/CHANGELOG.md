## 0.1.4

* Fix macOS menu item disabled state not being respected
* Fix Windows window `SetMinimumSize`/`SetMaximumSize` not working
* Add per-monitor DPI scaling for Windows display and window geometry
* Track menu item enabled state and update flags on Windows
* Adjust Linux tray icon menu trigger handling
* Enhance window example UI with event logging and three-tab interface
* Add menu example enhancements (disabled menu items, bug repro)
* Remove CocoaPods artifacts from macOS Xcode project

## 0.1.3

* Remove CocoaPods integration from the storage example
* Update Darwin example integration to use Swift Package Manager

## 0.1.2

* Add `LaunchAtLogin` API for managing app startup at user login
* Fix bindgen Dart template generation for `LaunchAtLogin` string-array arguments
* Fix bindgen Dart template generation for static native API calls

## 0.1.1

* Add `WindowManager` API with full lifecycle support (show, hide, center, pre-show/pre-hide hooks, visual effects, title bar style, control buttons)
* Add `TrayManager` / `TrayIcon` API with context menu trigger support
* Add `DisplayManager` / `Display` multi-screen management API
* Add `Menu` / `MenuEvent` menu system
* Add `MessageDialog` / `Dialog` APIs
* Add `AccessibilityManager` API
* Add `Preferences` storage
* Add `SecureStorage` secure storage
* Add `UrlOpener` API
* Add `PositioningStrategy` / `Placement` window positioning support
* Add `ContextMenuRegion` widget

## 0.1.0

* Initial release
