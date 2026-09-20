# visual_effect_example

A Flutter window whose background is a translucent material, set with
`Window.setVisualEffect`.

- One chip per `VisualEffect`. The ones `Window.isVisualEffectSupported` rules
  out here are greyed out: Mica needs Windows 11 22H2, Linux has none at all.
- The material only shows where the app paints nothing, so the example uses
  `WidgetsApp` and no `Scaffold`, paints a background of its own only while
  there is no effect, and leaves the window below the panel bare. A
  `MaterialApp` works too once its scaffold background is transparent.
- The controls keep a panel of their own: a material takes its colour from
  whatever happens to be behind the window, so text laid straight on it is
  readable over a pale desktop and lost over a dark one.
- The material runs to the top edge of the window. On macOS that takes
  `setContentUnderTitleBar(true)`, which makes the title bar a transparent
  overlay with the window buttons still on it; on Windows 11 the system backdrop
  covers the caption by itself, and on Windows 10 nothing can make it.
- "Show backdrop" puts a plain red window behind this one, which makes it
  obvious which materials blur the windows behind (Blur, Acrylic, Hud, Popover,
  Menu) and which only take their tint from the desktop picture (Mica).

```bash
flutter run -d macos   # or windows, linux
```

The real-desktop test of this example lives in the workspace repository:
`tools/gui/flutter_visual_effect_test.py` (macOS) and `.ps1` (Windows). It starts the example with
`VISUAL_EFFECT_AUTOPLAY=1`, which makes it show the backdrop and walk through the
effects by itself.
