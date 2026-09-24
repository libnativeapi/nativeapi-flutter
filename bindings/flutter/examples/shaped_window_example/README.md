# Shaped windows

Twelve silhouettes rendered by Flutter and clipped by nativeapi: circle, star, speech
bubble, heart, flower, hexagon, squircle, organic blob, burst badge, droplet, rounded diamond and shield.
On macOS and Windows, native clipping removes pixels outside the polygon.
On Linux (X11 and Wayland), a Flutter `ClipPath` paints the exterior transparent
and nativeapi sets a matching pointer/touch input region. A soft contour shadow
extends outside the shape without receiving clicks.

```sh
flutter run -d macos
# Also: flutter run -d windows / linux
```

Uses the experimental multi-window API on Flutter stable 3.47.5, enabled in `main`.
As with the other multi-window examples, Flutter main may have renamed these APIs.

The playground combines a colorful silhouette gallery with the compact option rows
and system light/dark palette of `tray_icon_example`. Each of the twelve shapes has
its own fixed gradient, shared by its gallery thumbnail and live window, with
light spots and a dotted texture. Selecting a shape also selects its colors.
The 480 × 680 control window uses a
compact 48 px header and a non-scrolling 4-column × 3-row gallery. Polygon corners
use sampled quadratic arcs, shared by native clipping, input regions and shadows. Shadow presets are None, Soft,
Float, Sharp and Glow; Adjust opens the full sliders in place of the gallery,
and Done returns without changing the selected shape or color. It uses `package:flutter/widgets.dart` only,
with no Material components or icon font. Shadow sliders support dragging, arrow
keys and Home/End.

Choose a silhouette, use the counter, or drag the handle in the preview. **Restore
rectangle** restores rectangular content. On Linux the input region still excludes
the transparent shadow margin; on macOS/Windows the native clip is removed. **Toggle size** rebuilds the polygon for the
new size. Closing the main window closes both windows.

```dart
final shape = WindowShape.create()!;
shape.addPoint(const Offset(0, 0));
shape.addPoint(const Offset(200, 0));
shape.addPoint(const Offset(100, 200));
window.titleBarStyle = TitleBarStyle.hidden;
window.backgroundColor = const Color(0x00000000);
final applied = window.setShape(shape);
shape.dispose(); // The window already copied the points.
// Later:
window.setShape(null);
```

Coordinates are content-local logical pixels. Polygons close automatically and
use even-odd filling. Approximate curves with segments. The point limit is 4096;
coordinates must be finite and between 0 and 16384. Reapply after resizing or a
display scale change. The rectangular window bounds do not change.

| Platform | Implementation |
| --- | --- |
| macOS | Content-layer mask; hidden title bar, fully transparent background, no visual effect required. AppKit controls alpha-based mouse hit testing. |
| Windows | Native window region clips drawing and mouse input; a nonactivating, click-through layered window renders the blurred contour behind it. Coordinates account for the content inset and DPI. |
| Linux / X11 | Flutter clipping + core shadow + GDK input region through `setInputShape`. |
| Linux / Wayland | Flutter clipping + `setInputShape`; `setShape` remains unsupported because it promises native visual clipping. |
| Android / iOS / OpenHarmony | Unsupported; returns false. |

The example reports failure visibly and leaves the preview rectangular. A supported
backend does not guarantee every window can accept a shape: check `setShape`'s return
value. On macOS a pre-existing content mask owned by the embedding app is preserved.

For a renderer-managed shape (Wayland), use `Window.isInputShapeSupported()` and
`window.setInputShape(shape)`, with a transparent window background and hidden
title bar. Clip your content with the same polygon and even-odd fill rule. Clearing
with `window.setInputShape(null)` restores default input handling; also remove your
visual clip. `isInputShaped` reports the applied input polygon separately from
`isShaped`. On Linux, `setShape` also replaces the input region, so clearing either
API resets input handling. The example selects renderer clipping whenever independent input shapes are supported.
Core reserves a fixed Linux shadow gutter for the supported blur/offset range,
so adjusting the shadow never changes content placement or surface size. Only
the actual shadow area is rasterized. Flutter content size and input vertices
stay in content-local coordinates.
Core paints the portion inside the content rectangle through a pass-through GTK
overlay, so native GL content windows do not hide irregular contour shadows.

Wayland launch:

```sh
GDK_BACKEND=wayland flutter run -d linux
```

The tested GNOME/Xwayland configuration has a Flutter experimental multi-window
GLX `BadAccess` failure; use Wayland to run this Flutter demo there.

Shape changes and **Restore rectangle** morph over 450 ms with cubic easing.
The polygons share perimeter landmarks, preserving the circle, star tips, and
bubble tail at rest. Each animation frame supplies the same vertices to native
shaping and the Wayland Flutter clip. Clicking another preset mid-transition
retargets from the current outline. System reduced-motion settings skip the
transition. **Toggle size** animates between 320 and 400 logical pixels over 450 ms
using the same easing and clock as the contour. The native clip is replaced without clearing
it first. Clicking again reverses toward the other size from the current frame;
changing shape during a resize retargets both together. Rectangular previews stay
rectangular, the counter and shadow settings are retained, and reduced-motion
settings apply the final size immediately.
On macOS, restoring a rectangle keeps square corners rather than AppKit frame rounding.
During a desktop size transition, the backing surface stays large enough for both
endpoints while the native contour and Flutter content layout animate each frame.
On Linux, each Flutter clip is submitted before its matching native contour;
pending animation ticks are coalesced until that frame is submitted.
The native bounds are tightened at completion. On macOS, the runner sends those endpoint
resizes asynchronously and rebases the native mask in the same transaction,
avoiding AppKit/Flutter raster waits on every animation frame and stale mask
coordinates at the endpoint. On macOS and Windows, core renders custom shadows in the background and coalesces pending updates;
the contour, input region, and layout stay responsive while shadow pixels catch up.

**Contour shadow** toggles the shadow without changing the clickable silhouette.
It is enabled by default and follows the same animated polygon.
Choose a shadow color and adjust **Opacity** (0–100%), **Blur radius** (0–64 px),
**Horizontal** and **Vertical** offset (−64–64 px) to update the preview live.
**Reset shadow parameters** restores black, 30% opacity, radius 18 and offset (0, 6).
Changing parameters while the shadow is hidden preserves the disabled state;
turn it back on to see the result. The controls scroll on smaller windows.


All three desktop implementations render custom shadows in core using the same
three-pass blur, color and offset definition. Flutter only clips the Linux content;
it does not paint shadows or reserve padding.

```dart
final shadow = WindowShadow.create()!;
shadow.color = const Color(0x4D000000);
shadow.setBlurRadius(18);
shadow.setOffset(const Offset(0, 6));
final applied = window.setCustomShadow(shadow);
shadow.dispose(); // Core copied the configuration.
window.hasShadow = false; // Keeps the custom configuration.
window.hasShadow = true;
final copy = window.customShadow; // Independently owned copy, or null.
copy?.dispose();
window.setCustomShadow(null); // Restores the platform's default shadow.
```

Custom shadows require a hidden title bar. Blur radius accepts 0–64 logical pixels;
each offset coordinate accepts −64–64. Check the setters' return values. macOS and
Windows use a noninteractive native shadow window; Linux reserves a transparent
GTK gutter excluded from input. The shadow follows contour changes and remains
available after restoring rectangular content.

System-decorated windows retain their platform shadow behavior. Linux native X11
visual regions can clip exterior shadows; use renderer clipping with `setInputShape`
as this example does. Default shadows may differ by platform; use the same custom
configuration for consistent styling.

### macOS renderer compatibility

This example sets `FLTEnableImpeller=false` in its macOS `Info.plist` to use
GPU-backed Skia Metal. The current experimental multi-window Impeller backend
can crash in `impeller::Canvas::SetupRenderPass` during a native size change,
with a texture/descriptor size mismatch. A frame delay does not guarantee GPU
completion and does not fix that race. This is an example-local workaround;
core's custom-shadow API and the Windows/Linux renderers are unchanged.
