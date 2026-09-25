# deno_floating_toolbar_example

A floating toolbar like the one above the iOS Simulator — the `deno desktop`
counterpart of `flutter_floating_toolbar_example`: a second window, transparent,
frameless and shadowless, that belongs to the main window and stays centred above it
while the main window is moved, resized, minimized and restored.

- Drag, resize or minimize the main window: the pill comes along.
- Press a colour or **Stamp** in the pill: the main window changes. Both windows render
  one model that Deno owns.
- **Detach toolbar** makes the pill an independent window; **Hide toolbar** hides it.
- The log shows the created / minimized / restored events as they arrive.

How: `setTitleBarStyle(Hidden)`, a transparent background, `setHasShadow(false)`, not
resizable, not movable, not in the taskbar; `toolbar.setParentWindow(main)` keeps it
above the main window and hides it with it; a `WindowManager` listener re-centres it on
the main window's moved and resized events. On Wayland applications cannot place their
windows, so there the pill is dragged by hand.

## Known issues (macOS)

- The toolbar window is transparent, and macOS may let clicks on the pill fall through
  to whatever is behind it (see `deno_shaped_window_example`); following the main
  window was checked with a real mouse, the pill's buttons were not.

## Running

```bash
npm install     # at the repository root: builds the nativeapi addon
cd examples/deno_floating_toolbar_example
deno task dev
```

Requires Deno 2.9+ (`deno desktop`). macOS is the platform this was checked on.
