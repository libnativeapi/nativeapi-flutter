# gpui_multiple_window_example

Three [GPUI](https://www.gpui.rs) windows laid out on the primary display by
nativeapi: `WindowManager::set_will_show_hook` catches each window just before
it is shown, sizes and positions it against `Display::work_area`, and then lets
the show through with `WindowManager::call_original_show` — the GPUI
counterpart of `flutter_multiple_window_example`, built on the Rust binding.

## Running

```bash
cd examples/gpui_multiple_window_example
cargo run
```

This crate is its own cargo workspace, not a member of the root one: GPUI is a
large dependency with its own platform requirements, and the root workspace's CI
builds every member. It enables GPUI's `runtime_shaders` feature, so building on
macOS does not need Xcode's Metal toolchain.

## Using it

The three windows cover 60% of the work area, centred: **Primary Window** takes
the top row (full width, half the height); **Secondary Window** and **Tertiary
Window** share the bottom row, left and right.

**A Window** in the primary window does what the Flutter button does: it finds
the window titled *Primary Window* through `WindowManager::get_all`, makes it
1000 × 1000 and shows it — and the will-show hook puts it straight back into its
slot.

A will-show hook *replaces* the platform's show: a window whose hook does not
call `WindowManager::call_original_show(id)` never appears.

## How it works

| API | Role |
| --- | --- |
| `WindowManager::set_will_show_hook` | Called instead of the show, with the window's id. |
| `WindowManager::get(id)` / `Window::title` | Which window is about to show. |
| `DisplayManager::get_primary` / `Display::work_area` | The area to lay the windows out on. |
| `Window::set_size` / `set_position` | The layout (frame size, top-left corner). |
| `WindowManager::call_original_show` | Lets the show through. |
| `Window::show` | Shows each window, through the hook. |
| `nativeapi_gpui::WindowExt::native_window` | The nativeapi `Window` behind a GPUI window (the `NSWindow*` / `HWND`). |

### Does the hook catch GPUI's own show?

On macOS the hook swizzles `-[NSWindow makeKeyAndOrderFront:]`, and GPUI calls
exactly that inside `open_window` (for `focus: true, show: true`, the default),
after setting the title. So yes, the hook fires for GPUI's show, and the window
is already registered with nativeapi then (`WindowManager::get` enumerates
`NSApp.windows`). But right after that call GPUI moves the window back to the
origin it was asked for (`setFrameTopLeftPoint:` in `MacWindow::open`), so only
the hook's **size** sticks, not its **position**: all three windows end up at
GPUI's centred origin.

The example therefore opens the windows with `show: false` and shows them with
nativeapi's `Window::show` from a GPUI task. That show goes through the same
hook, and nothing moves the window afterwards. The task matters too: the hook
resizes the window, and GPUI only hears about a resize when none of its updates
is running.

(With `focus: false` GPUI shows a window with `orderFront:`, which the hook
does not catch at all. How the hook meets GPUI's show on Windows has not been
checked.)

## Differences from the Flutter example

- The will-hide hook logs, like Flutter's, but then also calls
  `call_original_hide`: a hook replaces the hide just like the show, and the
  Flutter example's hook, which only prints, would keep any hide from happening.
- Closing the last window quits the app.
- The Material app bar is a plain GPUI header under the native title bar.

## Platform notes

- macOS and Windows. Checked on macOS (layout against the work area); not run on
  Windows.
- The hook fires twice per `Window::show` on macOS (seen in a log; presumably
  `-setIsVisible:YES`, which `Window::show` calls first, goes through
  `makeKeyAndOrderFront:` too). Harmless here, since the layout is idempotent.
- Not Linux: nativeapi wraps a `GtkWindow*` there, and GPUI does not use GTK,
  so the example has no native windows to work with.
