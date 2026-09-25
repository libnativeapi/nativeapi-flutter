# gpui_visual_effect_example

A [GPUI](https://www.gpui.rs) window whose background is a translucent material,
set with nativeapi's `Window::set_visual_effect` — the GPUI counterpart of
`flutter_visual_effect_example`, built on the Rust binding.

## Running

```bash
cd examples/gpui_visual_effect_example
cargo run
VISUAL_EFFECT_AUTOPLAY=1 cargo run   # show the backdrop and walk through the effects
```

This crate is its own cargo workspace, not a member of the root one: GPUI is a
large dependency with its own platform requirements, and the root workspace's CI
builds every member. It enables GPUI's `runtime_shaders` feature, so building on
macOS does not need Xcode's Metal toolchain.

## Using it

- One chip per `VisualEffect`, named as in the Flutter example (`none`, `blur`,
  `acrylic`, `mica`, `micaAlt`, `hud`, `popover`, `menu`). The ones
  `Window::is_visual_effect_supported` rules out here are greyed out and do
  nothing: Mica needs Windows 11 22H2.
- The material only shows where the app paints nothing: the window paints a
  background of its own only while there is no effect, and leaves the window
  below the panel bare. The controls keep a panel of their own, because a
  material takes its colour from whatever is behind the window.
- The material runs to the top edge of the window. On macOS that takes
  `set_content_under_title_bar(true)`, which makes the title bar a transparent
  overlay with the window buttons still on it; the panel starts 46 px down, clear
  of them. On Windows 11 the system backdrop covers the caption by itself.
- **Show backdrop** puts a plain red nativeapi window behind this one
  (`set_parent_window` keeps it below), which makes it obvious which materials
  blur the windows behind (blur, acrylic, hud, popover, menu) and which only take
  their tint from the desktop picture (mica).
- `VISUAL_EFFECT_AUTOPLAY=1` does what the Flutter example does with it: after
  4 s it shows the backdrop, then applies every effect and finally `none`, 2.5 s
  apart, printing `STEP backdrop shown` and `STEP <effect> applied|refused` on
  stdout — the same protocol `tools/gui/flutter_visual_effect_test.py` reads.

## How it works

| API | Role |
| --- | --- |
| `WindowOptions::window_background = Transparent` | GPUI's Metal layer is not opaque and clears to transparent, so whatever GPUI leaves unpainted shows the window's background. |
| `Window::set_visual_effect` / `visual_effect` / `is_visual_effect_supported` | The material, and which chips are available. |
| `Window::set_content_under_title_bar` | Lets the material (and GPUI's content) run under the macOS title bar. |
| `Window::new`, `set_background_color`, `set_parent_window` | The red backdrop window, kept below this one. |
| `nativeapi_gpui::WindowExt::native_window` | The nativeapi `Window` behind the GPUI window (the `NSWindow*` / `HWND`). |

On macOS nativeapi puts an `NSVisualEffectView` at the bottom of the window's
content view. GPUI draws into a view of its own that is a *subview* of that
content view, so the effect ends up behind GPUI's layer, which is exactly what is
wanted — no GPUI-specific handling was needed.

### Calling nativeapi from GPUI

Two nativeapi calls here make AppKit call back into GPUI synchronously: taking
the title bar in resizes GPUI's view, and showing the backdrop / focusing this
window changes its activation. GPUI's platform callbacks reach the app through
an `AsyncApp`, which fails while the app is already borrowed — i.e. inside a click
handler, a `Context::update`, or the `open_window` build closure. The callback is
then dropped: after a title bar change GPUI keeps laying the window out at its old
size, leaving a band at the bottom unpainted (seen and fixed while writing the
title bar example). So those calls run in a `cx.spawn` task, between `update`s,
with the native window held in an `Rc`. `set_visual_effect` only adds a subview
and is called straight from the click handler.

## Platform notes

- macOS and Windows.
- Not Linux: nativeapi wraps a `GtkWindow*` there, and GPUI does not use GTK, so
  the example has no native window to work with.
- Verified on macOS (26) by screenshots during an autoplay run: every effect is
  applied, the see-through ones come out red over the backdrop where GPUI paints
  nothing while GPUI's panel draws on top unchanged, and with `none` again the
  window is opaque.
- Windows has not been built or run. One interaction to expect there: GPUI makes
  a `Transparent` window see-through with the undocumented accent policy
  (`SetWindowCompositionAttribute`, `ACCENT_ENABLE_TRANSPARENTGRADIENT`), and
  nativeapi's `set_visual_effect` writes the same accent policy — for the effect,
  and when the effect is removed. Whichever writes last wins, so after `none`
  the window may no longer be transparent where GPUI paints nothing (harmless
  here, since the example paints its own background then), and on Windows 10 the
  acrylic/blur accent replaces GPUI's.
