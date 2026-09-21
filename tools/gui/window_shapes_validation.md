# Window shapes — validation (2026-09-20; Windows follow-up 2026-09-21)

Implementation: core `929a4bc`; Flutter `767f456`; Rust `a04d8b5`; C# `737200e`.
Windows repaint fix: core `053df26`; Flutter `d405dac`; Rust `de8c53f`;
C# `411cc99`. All commits are local; nothing was pushed.

## API and generated bindings

- `WindowShape`: copyable polygon builder (`AddPoint`, `Clear`, `GetPointCount`, `GetPointAt`).
- `Window::SetShape(std::shared_ptr<WindowShape>)`, `IsShaped() const`, `IsShapeSupported()`.
- Passing null removes the shape; applying copies its points. Coordinates are content-local
  logical pixels; callers reapply after resizing or changing display scale.
- The value object uses a C ABI handle, following `PositioningStrategy`; the object-model
  spec now records that exception. No new generator-skipped API.
- C ABI, Dart, Rust, and C# regenerated; raw Rust bindgen and Flutter ffigen refreshed.
  Flutter CocoaPods/SwiftPM and Rust link QuartzCore on macOS.
- `./codegen check`: 131 generated binding files current.

## Checks actually run

| Check | Result |
| --- | --- |
| macOS core CMake build | Passed |
| macOS CTest | 7/7 passed, including polygon validation and native AppKit mask tests |
| Windows MSVC core build + `window_shape_test` | Passed on configured Windows host |
| Flutter Windows debug build | Passed, Flutter 3.47.5 stable / Dart 3.13.4 |
| `flutter_window_shape_test_windows.ps1` | 33/33 passed on Windows 11 build 26200 at 125% scale, with real mouse input |
| Linux core build + `window_shape_test` | Passed on configured Linux host; no GUI input test |
| Rust `cargo check --workspace` | Passed |
| C# `dotnet build NativeAPI.slnx` | Passed, zero warnings/errors |
| Dart analysis of `packages/nativeapi` | Passed |
| Dart/Flutter analysis of `examples/shaped_window_example` | Passed |
| Flutter macOS debug build | Passed |
| `flutter_window_shape_smoke_macos.py` | 5/5 scenarios passed; circle/star/bubble, restore, resize/reapply |

The macOS Flutter smoke test calls the same action methods used by the UI through the debug
VM service. It reads the render tree, checks native status logs, captures the actual
preview window, and asserts centre/corner alpha values (1/0 when shaped, 1/1 after
restoring). Screenshots were also inspected visually. It sends no mouse or keyboard
input, so this does **not** verify dragging, button clicks, or click-through.

An additional whole-Flutter-repository `dart analyze` reported 73 issues in other
packages (including unresolved `screen_retriever_ffi` example imports and lint
configuration/deprecation issues). Those files were not changed. The affected nativeapi
package and new example passed their scoped analyses.

## Availability and limits

- macOS: content mask, requiring hidden title bar, fully transparent background, and
  no visual effect. Existing masks belonging to the embedder are preserved.
- Windows: native region clips rendering and input; DPI and client inset are applied.
- Linux: GDK visual/input regions only when the active backend supports both, typically
  X11. Wayland reports unsupported. The Flutter Linux runner was not built or visually
  tested; the Windows runner was built and GUI-tested in the follow-up below.
- Android, iOS, OpenHarmony: explicit unsupported stubs; not compiled in this run.
- Remote checks used archived sources and builds in scratch directories, leaving the
  remote checkouts untouched.

Pre-existing Windows maximize edits/tests in core, GUI/remote-host skill edits, and
untracked Linux GUI tools in the workspace were left intact and excluded from commits.

## Windows follow-up — 2026-09-21

The exact committed Flutter/core sources were archived into a separate scratch tree,
then `flutter build windows --debug` succeeded in the logged-on desktop session.
The follow-up found and fixed a Windows repaint defect after clearing a shape.
`SetWindowRgn` could leave the retained Flutter content invisible until the next
interaction. After a successful shape change, core now invalidates the entire native child-window hierarchy with `RedrawWindow`
and lets the normal WM_PAINT cycle run after pending framework updates. Immediate
synchronous repaint was insufficient; the queued repaint was verified visually before
any further interaction.

`flutter_window_shape_test_windows.ps1` passed all 33 checks:

- Circle, star, and bubble: the Win32 region exists, includes the centre, excludes the
  corner, and matches distinguishing points on the left and bottom contours.
- Each shape renders its Flutter label and accepts a real counter-button click.
- A click on the drag handle does not move the window; a drag moves it by the expected
  80 × 50 physical pixels.
- Resizing yields exactly 400 × 400 logical content pixels at 125% DPI and reapplies
  the polygon successfully.
- An excluded corner positioned over the main window's Restore button hit-tests to
  that underlying window. A guarded real mouse click passes through and activates the
  button. After clearing, the same corner belongs to the preview window again.
- The restored rectangle accepts another counter click; reapplying the shape succeeds,
  and the shared counter remains 4; no Flutter framework
  exception was logged. Captures were visually inspected, including the restored
  rectangle before any further click; text and controls now remain visible.

The first test attempt exposed a startup race in the test harness: the VM service URL
can appear before the main isolate/render views are ready. The test now stores the
launched process handle before probing, retries until two views exist (bounded to
60 seconds), and cleans up the process in `finally`. The successful run finished with
`Failures: 0`, and the application was closed afterward. It does not alter remote
checkouts or the user's other applications.

Re-run after building the snapshot documented at the top of the test script:

```sh
.agents/skills/remote-hosts/scripts/remote.sh win setup
.agents/skills/remote-hosts/scripts/remote.sh win desktop tools/gui/flutter_window_shape_test_windows.ps1 240
```

Other DPI values, multi-monitor DPI transitions, and the optional WinUI 3 backend were
not tested in this follow-up.

## Linux follow-up — 2026-09-21

Host: Ubuntu 24.04 / GNOME 46 Wayland session, with X11 applications running
through Xwayland. Flutter 3.47.5 stable / Dart 3.13.4. Sources were archived into
scratch trees; the host's checkouts were not changed. No synthetic input was sent.

Results:

- `flutter build linux --debug`: passed.
- Core `window_shape_test`: passed.
- Native X11 integration: **46 checks passed**. The test creates a real GTK window
  with client-side decorations and queries the X server with `XShapeGetRectangles`
  for both bounding and input regions. It covers triangle orientation, circle and
  star contours at 320 and 400 logical pixels, bubble tail, invalid replacement,
  builder mutation, independent wrappers, clearing, and restored corner regions.
- Flutter Wayland: **10 checks passed**. Two views render; circle/star/bubble labels
  and the unsupported status appear in the render tree; resizing produces a
  400 × 400 preview; clearing reports unsupported; the process stays alive without
  Flutter framework exceptions. Existing GLib signal warnings remain in startup logs.
- Flutter X11: **not passed**. Both views start and core reports
  `circle: native shape active (128 vertices); isShaped=true`, but the process
  subsequently exits with X11 `BadAccess`, GLX request 149 / minor 26. This matches
  the existing Flutter multi-window/Xwayland limitation recorded in the remote-host
  Linux notes. The smoke test deliberately returns nonzero for this failure.

Two core defects were reproduced and fixed:

1. Linux stored title-bar style only in an individual C++ wrapper. Flutter's
   `nativeWindow` getter creates a new wrapper, so `SetShape` incorrectly rejected
   a window whose title bar had already been hidden. The style is now shared via
   native GObject data. A fresh-wrapper regression test failed before the fix.
2. GDK submits bounding shapes during paint updates. Shrinking a shape need not
   expose new pixels, so no repaint was guaranteed; X11 kept the previous visual
   contour while the input region had already changed. Explicitly invalidating
   after set/clear makes GDK submit the pending visual shape. Five server-region
   checks failed without this invalidation and pass with it. The diagnosis was
   checked against GTK 3's [GDK update implementation](https://github.com/GNOME/gtk/blob/3.24.41/gdk/gdkwindow.c).

The VM-service smoke test waits for startup painting to settle before invoking
state methods. Wrapped status paragraphs are checked in the raw render tree,
since the portable UI probe only extracts single-line text nodes.

Reproduction (after `remote.sh linux setup`): archive core into
`$REMOTE_SCRATCH/shape-core-linux`, Flutter into `shape-flutter-linux`, and the
same core snapshot into `shape-flutter-linux/packages/cnativeapi/cxx_impl`.
Build the Flutter example with `flutter build linux --debug`, then:

```sh
R=.agents/skills/remote-hosts/scripts/remote.sh
$R linux push tools/gui/core_window_shape_test_linux.cpp tools/gui/core_window_input_shape_test_linux.cpp
$R linux run tools/gui/build_window_shapes_linux.sh
$R linux desktop tools/gui/core_window_shape_test_linux.sh 80
$R linux desktop tools/gui/flutter_window_shape_test_linux.py 150
```

Logs/results stay in scratch as `shape-core-linux-results.log`,
`shape-flutter-wayland.log`, `shape-flutter-x11.log`, and
`shape-flutter-linux-results.json`. Test processes are closed afterward.
Real mouse click-through/dragging, native Xorg sessions, and other scale factors
were not tested in this follow-up. X11 input-region assertions prove the installed
server region, not delivery of a real click.

## Wayland implementation — 2026-09-21

Wayland is now supported by the Flutter demo through renderer clipping plus a
native input region. `Window::SetShape` retains its native visual-clipping contract;
new `SetInputShape`, `IsInputShaped`, and `IsInputShapeSupported` APIs expose
independent Linux input shaping. Other platforms currently return false for this
independent operation, retaining their existing `SetShape` implementations.
C ABI, Dart (including ffigen), Rust (including bindgen), and C# were regenerated.

The Linux implementation shares the existing even-odd polygon rasterizer. Input
regions are registered with GTK so its CSD layout updates preserve them, and
surface-local child offsets account for Wayland's invisible decoration margins.
The Flutter demo shares one polygon between its `ClipPath` and the native input
region. It reapplies after window metrics changes and clears both sides when
restoring a rectangle.

Validation on the same Ubuntu 24.04 / GNOME 46 host:

- Native Wayland: 10 API/state checks plus **12 committed-protocol assertions**.
  Centre/top inclusion and corner exclusion are verified in the actual
  `wl_surface.set_input_region` + `commit` trace, including CSD layout updates,
  restored default input, and a resized polygon after removing the shadow.
- Native X11: all **46 existing region checks** still pass.
- Flutter Linux debug build: passed.
- Flutter Wayland: **18 checks passed** for two rendered views, three presets,
  reported native input state, a native parent keeping the preview above the controller,
  polygon commits on the surface titled Shape preview,
  400 × 400 resize, restoration, reapplication, and no framework exceptions.
  The smoke test defaults to Wayland; `--x11` also attempts the known failing
  Flutter multi-window/Xwayland configuration.
- Flutter raster tests: passed for transparent corners, opaque centres, distinct
  circle/star/bubble contours at 320 and 400 pixels, bubble tail, and clip invalidation.
- macOS core build and CTest: 7/7 passed. Scoped Dart analysis, Rust workspace check,
  C# solution build, and `./codegen check` passed; no new skipped APIs.

This run injects no mouse input. Protocol assertions verify the regions submitted
to the compositor; real mouse click-through and dragging remain manual checks.
Windows/mobile builds were not rerun for the new unsupported-platform stubs.

Build the additional fixture and run it alongside the existing tests:

```sh
R=.agents/skills/remote-hosts/scripts/remote.sh
$R linux push tools/gui/core_window_shape_test_linux.cpp tools/gui/core_window_input_shape_test_linux.cpp
$R linux run tools/gui/build_window_shapes_linux.sh
$R linux desktop tools/gui/core_window_input_shape_test_linux.py 60
$R linux desktop tools/gui/flutter_window_shape_test_linux.py 150
```

The native fixture trace is `shape-input-wayland.log` in scratch. The Flutter
smoke test captures circle, star, bubble, and restored rectangle screens as
`shape-wayland-<name>.png` in scratch.

The final star capture was visually inspected: the complete silhouette, gradient,
label, counter button, and drag handle render correctly, with the exterior showing
both the desktop and underlying controller window. The transient parent keeps the
preview above that controller. Wayland still controls initial placement; use the
preview's drag handle to move it away from the controls. A fresh Wayland demo was
launched after testing and left running for manual use.

## Shape morph animation — 2026-09-21

The Flutter example now morphs between circle, star, bubble, and rectangle in
450 ms with cubic ease-in/out. Shared perimeter landmarks preserve every original
vertex at the endpoints. A new selection starts from the currently applied
polygon, rather than jumping to the previous preset's endpoint. The same current
vertices are used for native shape/input updates and the Wayland clip. Reduced
motion skips the transition; resizing cancels it and reapplies the selected shape;
closing stops the ticker. The native window wrapper is retained across frames.

- Dart analysis passed; three geometry/raster tests passed. Tests cover endpoint
  equivalence with the original polygons, intermediate bounds/centre visibility
  across all shape/rectangle pairs at both sizes, and retargeting's starting polygon.
- Linux debug build passed. Wayland smoke test: **21 checks passed**, including at
  least three distinct committed input contours during star, bubble, and rectangle
  transitions, plus existing size/restoration/reapplication checks.
- No synthetic input was sent. The new animation was not GUI-tested on macOS or
  Windows; the example continues to use their existing native clipping APIs.

## Contour shadows — 2026-09-21

The demo now enables a contour shadow by default and exposes a **Contour shadow**
switch. macOS uses AppKit; Windows uses a nonactivating, click-through layered
helper; Linux renders the blur in a transparent 32 px margin with an independent
input region. The silhouette and shadow follow the same morph animation.

- Flutter geometry/raster tests: 4 passed, including soft exterior shadow pixels
  and a transparent outer margin for all three shapes. Scoped Dart analysis passed.
- Windows debug build and 22 no-input runtime assertions passed (three silhouettes,
  helper styles/z-order/bounds, move/hide/show, toggle, clear/reapply, resize,
  controls and no layout exceptions). Screenshot confirmed the star's soft shadow.
  Test: `flutter_window_shadow_test_windows.py <running-demo-stdout.log>` through
  the desktop session. The check leaves the example running.
- Linux/Wayland debug build and 25 no-input checks passed, including committed
  intermediate input polygons, the shadow switch and exclusion of the shadow
  margin from rectangular input. The example was then relaunched and left running.
- macOS debug build and VM-service smoke checks passed for circle/star/bubble,
  shadow toggle, rectangle, resize and reapply. Window captures contained soft
  black exterior pixels with shadow enabled, and zero such pixels with it off.
  The example was left running.

These checks do not inject clicks into another application through the shadow,
benchmark frame times, or claim an X11 Flutter runtime pass (the known GLX engine
failure remains). Windows hit-through is checked through its layered/transparent
window styles; Wayland input exclusion is checked from compositor protocol commits.

## Core custom shadows — 2026-09-21

`SetCustomShadow` / `GetCustomShadow` copy a `WindowShadow` configuration (color,
blur radius and offset). Null resets the default; `hasShadow` keeps configuration
while toggling visibility. Custom shadows require a hidden title bar. All custom
blur rendering is in core; Flutter no longer paints a shadow or reserves padding.
System-decorated windows retain platform behavior, and X11 hard visual regions can
still clip exterior shadows. The example uses renderer clipping plus input shapes
on Linux.

- Core macOS build and 7 CTest tests passed; the follow-up helper-window filtering
  regression also passed. Configuration copying, independent getter ownership,
  reset, visibility preservation and helper exclusion are covered.
- Codegen check passed (68 C ABI and 135 binding files), with no newly skipped APIs.
  Dart analysis, Rust workspace check and C# build passed. Flutter's 3 contour and
  transition tests passed.
- macOS debug example rebuilt and relaunched. The initial VM smoke covered
  circle/star/bubble, toggle, restoration, resize and reapplication. After the helper
  filtering fix, native regression passed and a capture contained 48,457 soft
  exterior pixels. Repeating direct VM invocations interrupted Flutter mid-frame
  (`setState during build`); the final VM smoke was not a clean pass. The example
  was restarted to leave a fresh instance. No physical-input test was performed.
- Windows debug example rebuilt and relaunched; 24 native/VM assertions passed,
  including persistent rectangular shadows and visibility/position synchronization.
- Linux backend syntax check passed with GTK 3.24.52. The native GTK renderer test
  ran on macOS's Quartz GTK backend: default/custom soft pixels, disabled zero
  pixels, and preserved 320×320 content after margin changes passed. This is not a
  Linux/Wayland runtime pass. The Linux host briefly accepted SSH commands, but
  source transfer subsequently stalled/timed out; the new Linux build and restart
  remain unverified. The updated Linux test expects core shadows and 400×400 content.

No synthetic mouse or keyboard input was sent. Mobile implementations return
unsupported. Platform scaling/rasterization may differ at individual edge pixels.

## Square restoration and resize clipping — 2026-09-21

- macOS shaped windows use a borderless frame, retained when clearing the polygon.
  Normal title-bar style restores the original decoration flags. Focus overrides
  preserve AppKit's KVO runtime class instead of replacing it. Native regression
  covers geometry, focus toggles, unaffected windows and normal-style restoration.
- The macOS Flutter example rebuilt and ran with a 320×320 preview; restoring the
  rectangle produced four opaque square content corners in its captured image.
- Windows example rebuilt and ran: 26 checks passed, including 1 ms sampling of
  `GetWindowRgn` during both growth and shrinkage. All sampled regions remained
  complex; the resize path no longer calls `setShape(null)`/`setInputShape(null)`.
- No synthetic input was sent; runtime actions used the debug VM service. Linux
  was not rerun for this correction. The prior shadow parameter controls are kept.
