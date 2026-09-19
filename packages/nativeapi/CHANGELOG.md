## Unreleased

* Add `package:nativeapi/windowing.dart`: `controller.nativeWindow` / `nativeWindowOf()`
  turn a window created with Flutter's experimental multi-window API into a nativeapi
  `Window`, so Flutter-rendered secondary windows can be styled, positioned and observed
  from Dart alone. Kept out of the main library because it needs the Flutter main channel
  with `--enable-windowing`.
  Not part of the pub.dev package yet: it does not analyze on stable Flutter, so use a git
  dependency for it.

## 0.2.7

* Add `WindowCreatedEvent` and `WindowClosedEvent`. `WindowManager.addListener` now reports
  a window the first time it is shown and when it is closed for good, whoever created or
  closed it — including windows made with Flutter's multi-window API. A window that is
  never shown emits neither; hiding is not closing.
* Add `Window.setParentWindow` / `Window.parentWindow` for child windows — floating
  toolbars, palettes, inspectors. A child stays above its parent and hides when the parent
  is minimized. On macOS it also moves with its parent; on Windows and Linux follow the
  parent's `WindowMovedEvent` for that. On Windows a child is destroyed with its parent.
* `WindowEvent` and the other event base classes now expose what every variant carries
  (`event.windowId`, …), so reading it no longer needs a match on the concrete type.
* macOS and Windows: a `Window.backgroundColor` with alpha now really makes the window
  see-through. macOS marks the window non-opaque and drops the Flutter view's black
  backing; Windows, which ignored the alpha, has the compositor draw the color.
* Linux: `Window.titleBarStyle = hidden` on a window that is not shown yet no longer
  leaves its content 52 px short in both directions on Wayland (it now hides GTK's own
  header bar instead of un-decorating the window).
* Add `floating_toolbar_example`: a transparent, frameless Flutter window attached to the
  main window, from Dart alone.
* Add `TrayIcon.isIconTemplate`, `iconSize` and `iconPosition` (with `TrayIconPosition`).
  **Behaviour change on macOS:** an icon is no longer forced to be a template image, so
  coloured icons keep their colours — set `isIconTemplate = true` for a monochrome glyph
  that should follow the menu bar. The default size is still 18 x 18 points; a zero size
  draws the image at its own size. The `Image` given to `icon` is no longer modified.
  Windows and Linux record the three values without using them.
* Windows: tray icons come back after Explorer restarts instead of disappearing for good.
* Linux: every tray icon gets its own D-Bus connection, so a second icon in the same
  process appears instead of failing to register, and a disposed icon leaves the panel
  at once.
* Linux: window size and position are measured by the frame and the content instead of
  the `GdkWindow`.
* Windows: a menu item's click event is emitted before `Menu.open` returns, and `open`
  reports failure from whether the menu was actually shown.
* Fix a crash when a window message arrived for a menu that had already been destroyed.

## 0.2.5

* Add drag and drop: `DropTarget` / `DragSource` bindings, and the `DropRegion` and
  `DragOutArea` widgets for dropping files and text onto a window and dragging them out
  of it.
* Add `DragToMoveArea` and `DragToResizeArea` widgets for custom window chrome, with
  optional target windows and configurable resize handles.
* Add `WindowDragSession` and `WindowManager.getWindowAtPoint` for tear-off windows that
  follow the cursor and can dock back into another window.
* Add `Window.isVisibleInTaskbar` for keeping a window out of the taskbar — the
  `skipTaskbar` counterpart, inverted so it reads like the other flags. Windows adds and
  removes the taskbar button (and keeps it away across hide/show), Linux sets the window
  manager's skip-taskbar hint, macOS drops the window from the app's Window menu.
* Window events now actually fire. `WindowResizedEvent`, `WindowMovedEvent`,
  `WindowMinimizedEvent`, `WindowMaximizedEvent` and `WindowRestoredEvent` existed all
  the way through the bindings but were never emitted — only focused and blurred worked.
  Wayland cannot report moves or minimization to a client, so those stay silent there.
* Fix `Window.hasShadow` doing nothing on Windows: turning it off now removes the
  window's drop shadow, which is what a frameless window usually wants.
* Fix `Window.titleBarStyle` on Windows: hiding the title bar now takes effect straight
  away instead of only after a fullscreen round trip, the content fills the space the
  title bar left, and the top edge stays resizable.
* Fix `Window.isFullScreen` on Windows being answered from the window's rectangle, so
  moving or centering a full screen window left it stuck in full screen for good. Also
  fix `Window.isMinimized` always being false there, which made `restore()` a no-op.
* Fix `Window.startDragging` not moving the window on Windows, and on macOS the gesture
  after a `startDragging` / `startResizing` being ignored; implement it on Linux.
* Linux fixes: `WindowManager.getCurrent()` and `Window.isFocused` now find the focused
  window, an app no longer exits immediately instead of running, opening a context menu
  relative to a window no longer crashes, and the display getters survive monitors being
  replaced or the screen blanking.
* Windows fixes: window hit testing and late drag starts, submenu detach/reattach, and
  Top End menu placement.
* Add `window_drag_areas_example`, `drag_drop_example`, `detachable_window_example` and
  `browser_tabs_example`.

## 0.2.4

* Update to `cnativeapi` 0.2.4 with Windows DLL export and Apple build fixes.
* Fix storage example initialization and collection access by using the `all` getter.
* Sync generated Dart bindings with the updated core.

## 0.2.3

* Add `Window.isNonActivating`. A non-activating window can be shown on top and take
  keyboard input without activating the app, so the previously active app keeps its
  activation and the app's other windows stay put when it is hidden. Only macOS has
  observable behavior (the window becomes a non-activating `NSPanel` in place); Windows
  and Linux record the flag
* macOS: `Window.isFocusable = false` now actually prevents the window from becoming key

## 0.2.2

* Fix macOS build failure in 0.2.1 coming from `cnativeapi` — see its changelog

## 0.2.1

* Add `AppInfo` API for the running app's name, identifier, version and build number
* Add `DeviceInfo` API for the machine's name, model, manufacturer, OS, kernel and architecture
* Fix `WindowFocusedEvent` and `WindowBlurredEvent` never firing — the native layer
  dispatched no window events at all, so `WindowManager.addListener` was silent

## 0.2.0

* **Breaking:** regenerate the Dart API from the new code generator; the object identity/lifecycle model is unified and many signatures changed
* **Breaking:** rework the event system — `EventEmitter` and the separate `WindowEvent`/`MenuEvent`/`TrayIconEvent` classes are replaced by typed event listeners on each object
* Add `Application` API
* Add `KeyboardMonitor` API
* Add `Shortcut` and `ShortcutManager` APIs for global shortcuts
* Add `ImageAsset` widget helper
* Fix tray icon bounds on multi-display setups (macOS)
* Fix macOS global shortcuts never firing

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
