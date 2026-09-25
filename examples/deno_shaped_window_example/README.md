# deno_shaped_window_example

Twelve silhouettes clipped by nativeapi — circle, star, speech bubble, heart, flower,
hexagon, squircle, blob, burst, droplet, diamond and shield — the `deno desktop`
counterpart of `flutter_shaped_window_example`, with the same outlines
(`shapes.ts` is a port of its `shape_geometry.dart`).

- **Window shapes** holds the gallery and the controls. **Shape preview** is a
  transparent, frameless window clipped to the selected polygon with
  `Window.setShape` (on Linux, where the renderer clips, the page clips with CSS and
  nativeapi sets a matching `setInputShape` region).
- Shape changes, **Restore rectangle** and **Toggle size** (320 ↔ 400) morph over
  450 ms: every contour is resampled at shared perimeter landmarks, and each frame
  sends the interpolated polygon to the window. During a size morph the window keeps
  the larger size and only the polygon and page layout animate.
- **Shadow**: presets None / Soft / Float / Sharp / Glow fade over 220 ms; **Adjust…**
  shows the colour and the opacity, blur and offset sliders. The shadow follows the
  contour (`Window.setCustomShadow`).
- Drag the preview by **⠿ DRAG ME**; **Tap** is a counter that survives every change.

`WindowShape` and `WindowShadow` are plain data, so the binding calls them on the JS
thread even under `deno desktop`, where every other call hops to the UI thread: a morph
frame adds over a thousand points.

## Known issues (macOS)

- The preview window does not receive mouse input: macOS hit-tests a non-opaque window
  by the alpha of its own pixels, and a web view draws in another process, so the whole
  window counts as transparent and clicks fall through to whatever is behind it. **⠿
  DRAG ME** and **Tap** do not work yet; everything driven from the controls window
  does.

## Running

```bash
npm install     # at the repository root: builds the nativeapi addon
cd examples/deno_shaped_window_example
deno task dev
```

Requires Deno 2.9+ (`deno desktop`). macOS is the platform this was checked on.
