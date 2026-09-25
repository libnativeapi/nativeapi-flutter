## Unreleased

* Raw bindings for the view module (`native_view_*`, `native_label_*`,
  `native_button_*`, `native_text_field_*`, `native_image_view_*`,
  `native_window_get_content_view`) and `native_edge_insets_t`.
* cnativeapi is now a plain Dart package instead of a Flutter FFI plugin, so it
  works in Dart command-line apps as well as Flutter apps. A build hook
  (`hook/build.dart`) compiles the nativeapi core with the target's toolchain
  in place of the per-platform CMake, CocoaPods and SwiftPM projects.
* **Breaking:** the bindings are top-level `@Native` functions. The
  `CNativeApiBindings` class and the `cnativeApiBindings` instance are gone;
  call `native_window_create()` instead of
  `cnativeApiBindings.native_window_create()`. Enum-typed struct fields are
  now also readable as the Dart enum; the raw value is `<field>AsInt`.
* **Breaking:** every function taking a callback, and every struct with a
  callback field, takes a `native_release_user_data_t` after its `user_data`
  (`nullptr` if there is nothing to release). The core calls it exactly once,
  on the main thread, once it can no longer call the callback.
* The WinUI 3 backend on Windows (`NATIVEAPI_ENABLE_WINUI3`) is not built by
  the hook; the Win32 implementations are used.

## 0.3.1

* `native_window_set_content_under_title_bar`,
  `native_window_is_content_under_title_bar` and
  `native_window_is_content_under_title_bar_supported` are new, and
  `NATIVE_TITLE_BAR_STYLE_HIDDEN` now hides the window control buttons on macOS too.
  See the `nativeapi` changelog.
* `native_window_set_visual_effect` returns whether the effect is in force;
  `native_window_is_visual_effect_supported` is new, and so are the effects `MICA_ALT`,
  `HUD`, `POPOVER` and `MENU`. The effect is read from the native window, shows in a
  Flutter window on macOS, and on Windows Blur is a plain blur-behind that works on
  Windows 10. See the `nativeapi` changelog.
* `LaunchAtLogin` on Windows: an app running from an MSIX package gets a shortcut in the
  user's Startup folder, because the `Run` registry key an MSIX container writes is
  virtualized and never read. `IsEnabled()` also reads Explorer's `StartupApproved\Run`
  flag and `Enable()` clears it, so an entry the user switched off in Task Manager is not
  reported as enabled and enabling it again really enables it. The registry is written
  through the wide API, so a non-ASCII identifier or path survives.
* `LaunchAtLogin` on macOS: `setProgram()` naming the running application registers that
  application whatever the identifier says, instead of failing because the identifier does
  not name a bundled login item helper. Arguments are recorded but never delivered —
  `SMAppService` starts the app bundle, nothing else — where before any argument made
  `enable()` fail.

## 0.3.0

* **Breaking:** requires Flutter 3.47 / Dart 3.13.
* Android: the shared library is linked with 16 KB page alignment, so it loads on the
  Android 15 devices that use 16 KB memory pages.
* Linux: building no longer asks for `libayatana-appindicator3-dev`. The tray icon has been a
  StatusNotifierItem over D-Bus for a while; only the plugin's CMake file still required
  and linked the library.
* Update the embedded core: a translucent window background is see-through on Windows and
  Linux, `native_window_set_has_shadow` works on Linux, Linux hides GTK's header bar for
  `titleBarStyle = hidden` instead of un-decorating the window, and a Linux window's
  content size is measured without the shadow margin.

## 0.2.7

* Same as 0.2.6; released together with nativeapi 0.2.7 (there is no nativeapi 0.2.6).

## 0.2.6

* Update the embedded core and regenerate the C bindings.
* Add `native_tray_icon_set_icon_template` / `_is_icon_template`, `_set_icon_size` /
  `_get_icon_size`, `_set_icon_position` / `_get_icon_position` and
  `native_tray_icon_position_t`. macOS no longer forces tray icons to be template images.
* Add `native_window_set_parent_window` / `native_window_get_parent_window`, and the
  `NATIVE_WINDOW_EVENT_TYPE_CREATED` / `_CLOSED` window events.
* macOS: a window background color with alpha makes the window non-opaque.
* Windows: tray icons are added again when Explorer restarts; menu item clicks are emitted
  before the popup call returns, and its result says whether the menu was shown.
* Linux: one D-Bus connection per tray icon; window geometry measured by frame and content.
* Fix window handlers being called for menus that were already destroyed.

## 0.2.5

* Update the embedded core and regenerate the C bindings.
* Add `native_drag_source_*`, `native_drop_target_*` and `native_window_drag_session_*`
  for dragging files and text in and out of windows and for tear-off window drags, plus
  `native_window_manager_get_window_at_point`.
* Add `native_window_set_visible_in_taskbar` / `native_window_is_visible_in_taskbar`.
* Emit the window resized, moved, minimized, maximized and restored events, which the
  ABI declared the whole way through but never dispatched.
* Windows: track full screen as window state instead of comparing rectangles, fix
  `native_window_set_has_shadow`, the hidden title bar style, `native_window_is_minimized`,
  window hit testing and late drag starts, submenu detach/reattach and Top End placement.
* Linux: fix `native_window_manager_get_current` and `native_window_is_focused`,
  implement `native_window_start_dragging`, keep the application running instead of
  exiting at once, stop crashing on window-relative context menus, and survive monitors
  being replaced.
* macOS: keep the mouse gesture after a native window drag or resize starts.

## 0.2.4

* Windows: compile the C API directly into the plugin DLL to retain exported entry points.
* Compile Apple core sources as separate translation units to avoid duplicate definitions.
* Update the embedded core and generated C bindings.

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
