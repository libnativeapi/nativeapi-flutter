# gpui_shaped_window_example

Twelve silhouettes for a window — circle, star, speech bubble, heart, flower,
hexagon, squircle, organic blob, burst badge, droplet, rounded diamond and
shield — drawn by [GPUI](https://www.gpui.rs), clipped by nativeapi and given a
contour shadow. The GPUI counterpart of `flutter_shaped_window_example`, built
on the Rust binding.

## Running

```bash
cd examples/gpui_shaped_window_example
cargo run
```

This crate is its own cargo workspace, not a member of the root one: GPUI is a
large dependency with its own platform requirements, and the root workspace's CI
builds every member. It enables GPUI's `runtime_shaders` feature, so building on
macOS does not need Xcode's Metal toolchain.

## Using it

Two windows, as in the Flutter example: the 480 × 680 control window ("Outside
the box.") and a 320 × 320 shaped preview beside it.

- Pick a silhouette in the 4 × 3 gallery. Each shape has its own fixed
  gradient, light spots and dotted texture, shared by its thumbnail and the
  preview. The preview morphs to the new outline over 450 ms; clicking another
  shape mid-morph retargets from the current frame.
- **Apply shape** re-applies the selected silhouette; **Restore rectangle**
  morphs back to square content and removes the native clip.
- **Toggle size** animates the preview between 320 and 400 px, together with
  its contour.
- Shadow presets **None**, **Soft**, **Float**, **Sharp** and **Glow** fade to
  their parameters over 220 ms. **Adjust…** swaps the gallery for the full
  controls: on/off, five colours, opacity (0–100 %), blur radius (0–64 px),
  horizontal and vertical offset (−64–64 px) and a reset to black, 30 %, 18 px,
  (0, 6). Sliders take a press or drag, and arrow keys / Home / End once
  focused. **Done** returns to the gallery.
- Drag the **DRAG ME** handle to move the preview; **Tap** counts clicks.
  Outside the silhouette, clicks go to whatever is behind it.
- Closing the control window quits.

## How it works

GPUI opens the preview with no title bar and a transparent background and
paints the content square; nativeapi does the rest:

| API | Role |
| --- | --- |
| `Window::set_title_bar_style(Hidden)` / `set_background_color(transparent)` | What `set_shape` and `set_custom_shadow` require, besides GPUI's own `titlebar: None` and `WindowBackgroundAppearance::Transparent`. |
| `WindowShape` + `Window::set_shape` | The polygon (content-local logical points, even-odd), re-applied on every animation frame; `set_shape(None)` restores the rectangle. |
| `WindowShadow` + `Window::set_custom_shadow` / `set_has_shadow` | The contour shadow, which follows the polygon and receives no clicks. |
| `Window::set_content_bounds` | The size animation, keeping the top-left corner in place. |
| `Window::start_dragging` | Moves the preview from the drag handle. |
| `Window::with_native_window` | Wraps the `NSWindow*` / `HWND` behind a GPUI window (`src/native.rs`). |

`src/geometry.rs` is a faithful port of the Flutter example's
`shape_geometry.dart`: the same polygons, the sampled quadratic corner arcs and
the shared perimeter landmarks that make every contour (and the rectangle)
morph into every other one. `src/playground.rs` holds the state and all native
calls; `src/views.rs` renders both windows from it.

A few things are done differently from Flutter:

- **Painting.** GPUI cannot clip to a path, so the preview paints its full
  square and relies on the native clip; the gallery thumbnails are rasterized
  once (even-odd, 4 × 4 supersampled) into images. GPUI gradients take two
  stops, so the three-stop diagonal gradient is a quad plus a triangle meeting
  on the middle colour.
- **Native calls outside GPUI updates.** Moving, resizing or showing a window
  calls back into GPUI synchronously; inside an entity update GPUI cannot take
  those callbacks and would miss the new size. Configuration, resizes and
  `show` therefore run from a task between updates; the animations are
  timer-driven tasks (16 ms ticks) rather than animation controllers.
- **Resizing.** As in the Flutter example, the window grows once to the larger
  endpoint, the content and contour animate inside it, and the bounds are
  tightened at the end. No macOS runner channel or Impeller workaround is
  needed.
- **Not ported:** the reduced-motion setting (GPUI does not expose it — changes
  always animate), the chips' press-scale feedback, letter spacing on captions
  (not in GPUI 0.2.2's text style) and the sliders' accessibility actions.

## Platform notes

- macOS and Windows. On macOS the clip is a content-layer mask and AppKit's
  alpha hit testing lets clicks outside it through; on Windows it is a window
  region, with a layered window behind it for the shadow.
- Not Linux: nativeapi wraps a `GtkWindow*` there, and GPUI does not use GTK,
  so the example has no native window to shape (the Flutter example's
  renderer-clipping plus `set_input_shape` path is not ported). The status line
  says so.
