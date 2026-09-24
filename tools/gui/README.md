# tools/gui

Real-desktop GUI tests and demo-recording scenarios for the examples. They launch the
built example, drive it with synthetic mouse input, and check real window geometry and
on-screen state — things unit and widget tests cannot see.

The generic machinery (UI probe, input drivers, app harness, screen recorders, remote
runner) lives in [`.agents/skills/`](../../.agents/skills); read
`gui-test/SKILL.md` there first — especially the safety rules. This directory only holds what is specific to our examples.

| Script | Example | Platform | Covers |
| --- | --- | --- | --- |
| `core_window_shadow_layout_test_linux.cpp` | core shadow | Linux Wayland / X11 | No-input regression: stable shadow geometry, contour pixels inside transparent content, input pass-through, disable and decoration restoration |
| `flutter_window_shape_smoke_macos.py` / `flutter_window_shape_test_windows.ps1` | `shaped_window_example` | macOS / Windows | macOS: no-input shape and pixel-alpha smoke test; Windows: native regions, real button clicks/drag, resize, clear/reapply, click-through to the underlying app window |
| `flutter_detachable_window_test.py` / `.ps1` | `detachable_window_example` | macOS / Windows | tear a panel off, exact content size, header stays under the cursor, dock into the other window, `State` preserved |
| `flutter_window_drag_areas_test.py` / `.ps1` | `window_drag_areas_example` | macOS / Windows | `DragToMoveArea`: window follows the mouse, a click does not move it, double click maximizes and restores; `DragToResizeArea`: all eight handles, the other edges stay anchored, minimum size, `enableResizeEdges`, clicks pass through the middle |
| `flutter_menu_test.py` / `.ps1` | `menu_example` | macOS / Windows (WinUI 3 and Native backends) | context menu opens at the click point; placement Top End (also after the menu changed); item types and states (checkbox, radio group, disabled, submenu, special characters); click / open / close / submenu events; dismissing fires no click; label change, added item and detached submenu show on the next open; absolute and cursor positioning |
| `flutter_floating_toolbar_test.py` / `.ps1` / `_linux.py` | `floating_toolbar_example` | macOS / Windows / Linux (inside only) | `Window.setParentWindow` with two Flutter windows: the toolbar window starts centred above the main one, follows a move and re-centres after a resize (through Accessibility, `--no-input` stops here); follows a real drag of the title bar; a press in the toolbar counts up in the main window; detached it stays put, attached it comes back; hidden it is not brought back by moving its parent. Windows runs the same steps (moves through `SetWindowPos`). Linux: multi-window Flutter only runs as a Wayland client, which cannot be measured or pressed from outside, so the twin only checks from the inside that both views render, `setParentWindow` succeeded, the toolbar view has the size it was given (it was 52 px short while core un-decorated the window instead of hiding its header bar) and the app keeps running |
| `flutter_window_events_test.py` | `window_example` | macOS | `WindowManager.addListener` really is called: focused on activation, moved and resized when the frame changes (through Accessibility, one click only), payloads equal to the frame the OS reports |
| `core_window_drag_session_test.py` / `.ps1` / `_linux.py` | core `window_drag_session_example` (C++) | macOS / Windows / Linux | dock by dragging onto another window, tear off anchored under the cursor, event output; the Linux twin also checks that the panel follows the cursor while carried |
| `core_window_visual_effect_test.py` / `.ps1` | core `window_visual_effect_example` (C++) | macOS / Windows | `Window::SetVisualEffect`: the example walks a window through every effect over a plain red window and the test samples the screen after each step - the materials that blend with the windows behind come out reddish, no effect does not, `SetVisualEffect` agrees with `IsVisualEffectSupported`, `GetVisualEffect` is the effect in force, and a background color set while an effect was active is what shows once the effect is removed. No input on macOS; on Windows one click on the example's title bar, because the system backdrops are only drawn for the active window |
| `flutter_visual_effect_test.py` / `.ps1` | `visual_effect_example` | macOS / Windows | the same through a Flutter window: started with `VISUAL_EFFECT_AUTOPLAY=1` the example shows the red backdrop and walks through the effects itself; where Flutter paints nothing the material shows the red behind, and with the effect removed the Flutter view has its opaque backing again. No input on macOS, the one activating click on Windows |
| `flutter_menu_theme_test.ps1` | `menu_example` | Windows (WinUI 3 and Native backends) | switches Dark / Light / System through Flutter, checks native appearance results and actual menu background colors; accepts `-Exe`, `-KeepOpen` and `-NativeOnly` |
| `core_menu_lifetime_test.ps1` | core `tests/menu_lifetime_test.cpp` | Windows | issue 54: a `Menu` destroyed from a listener that runs inside the window procedure does not kill the process, and a menu created after every other menu was destroyed still gets its events. No input, but it needs a desktop session |
| `core_menu_backend_test.ps1` | core `tests/menu_click_test.cpp` | Windows | native menu backend: a top-level and a submenu item click reach the listener *before* `Menu::Open()` returns and fire exactly once; dismissing without picking fires none. The test binary owns the assertions, the script owns the mouse |
| `core_drag_drop_test.py` / `.ps1` | core `drag_drop_example` (C++) | macOS / Windows | `DragSource` → `DropTarget` across two windows: enter / move / drop events, dropped file path and text, drop position in content coordinates, source reports `copy`; a drag released where nothing accepts it reports exit and `none` |
| `flutter_drag_drop_test.py` / `.ps1` | `drag_drop_example` | macOS / Windows | `DragOutArea` → `DropRegion` in one window: a file and a text drop arrive, the source sees `copy`, the highlight clears, a second drag works after the first |
| `flutter_tray_icon_test.py` / `.ps1` / `_linux.py` | `tray_icon_example` | macOS / Windows (WinUI 3 and Native menu backends) / Linux | animated tray icons: frames really are rendered and pushed (counter, 30 and 60 fps, no dropped frames, Pause / Step / Resume, 3x resolution), a live widget captured into frames, the Download scene driving the title, three icons animating at once; title / tooltip / visibility / trigger / bounds read back from the native getters; the menu opened from code shows its items and states, an item click arrives, `closeContextMenu` closes it; "Window to icon" puts the window below the icon on macOS and above it on Windows, centred on it; the example's own checklist has no unexpected failures. Windows tray icons have no title, so the title checks become one no-op check there. On Linux the icon is a StatusNotifierItem: no bounds and no menu opened from code, so the test checks the example does not offer them; the frame pipeline is asserted at 10 fps (what 30 fps gives on the host is printed), and the icons are counted where the shell counts them: `RegisteredStatusNotifierItems` lists one, then three, then one again after two are removed. Not covered: clicks on the tray icon itself — the input driver refuses the menu-bar layer, those stay manual items of the example's Checklist tab |
| `flutter_launch_at_startup_test.py` | `launch_at_startup`'s own example, in a leanflutter checkout (`$LEANFLUTTER_DIR`, default `~/Projects/leanflutter`; see `common.py`) | macOS | the 0.5.x compatible API on nativeapi: Enable registers an `SMAppService` login item, `isEnabled` reads it back, Disable removes it, and `setup(args:)` neither throws nor leaves an entry behind. Always leaves the login item off, including on a failure. Written but not yet run — the display was asleep; the same sequence was verified headlessly instead |
| `flutter_detachable_window_and_browser_tabs_demo.py` / `.ps1` | both Flutter examples | macOS / Windows | the demo video scenarios; also the only coverage of `browser_tabs_example` (reorder, tear off, merge, move by the strip; its log ends with the preserved page state, no PASS/FAIL checks) |
| `flutter_floating_toolbar_demo.py` / `.ps1` | `floating_toolbar_example` | macOS / Windows | the floating toolbar demo video: the pill drives the main window (colours, Stamp), follows it when it is dragged by the title bar and resized from its corner, stays behind when detached and snaps back when attached, is hidden and shown again; ends on the counter and the log. `DEMO_DRY_RUN=1` on the Windows host plays it without recording; without `--record` the macOS script does the same |
| `flutter_tray_icon_demo.py` | `tray_icon_example` | macOS | the tray demo video: the example moves its window next to its tray icon ("Window to icon") so the real icon and the magnified preview are in one picture; gallery, widget capture, 10 → 60 fps, Pause / Step, scenes, three icons at once, menu opened and closed from code, checklist |
| `flutter_window_shape_demo.py` / `.ps1` / `_linux.py` | `shaped_window_example` | macOS / Windows / Linux | the shape demo video: every one of the twelve gallery silhouettes once, left to right / top to bottom, then the five contour-shadow presets (None, Soft, Float, Sharp, Glow); ends held on the last silhouette with its shadow. The recorder starts after the app is up and arranged, so the take opens on the app. `DEMO_DRY_RUN=1` (or `-DryRun`) on Windows, and no `--record` on macOS, play it without recording; `--only shapes|shadow` runs one scene. Linux: the app must be a **Wayland client** (the GNOME/Xwayland path dies with a multi-window GLX `BadAccess`), so the windows cannot be measured through Xlib — the scenario locates them in a captured frame instead, drives the pointer from the probe's rects, and prints `RECORD_FRAMES <dir>` for the wrapper to pull and encode |

`common.py` points the macOS scripts at the skills' harness and at the Flutter examples
(`examples/flutter_*`; the scripts name them without the prefix). The Linux scripts import `guiapp` straight from the flat
kit the `remote-hosts` skill pushes, and find the example through `$REMOTE_SCRATCH`.

## Running

Every script takes over the mouse. It refuses to start while the mouse is moving and
stops as soon as a press would land outside the example's own windows. No keyboard
input is ever sent.

```bash
# macOS (examples built with `flutter build macos --debug`, or pass --build)
tools/gui/flutter_detachable_window_test.py
tools/gui/flutter_window_drag_areas_test.py
tools/gui/flutter_menu_test.py
tools/gui/flutter_window_events_test.py
tools/gui/flutter_floating_toolbar_test.py          # --no-input: only the part that needs no mouse
tools/gui/core_window_drag_session_test.py --build   # builds the example into core/build
tools/gui/core_drag_drop_test.py --build
tools/gui/flutter_drag_drop_test.py
tools/gui/flutter_tray_icon_test.py
tools/gui/flutter_launch_at_startup_test.py
tools/gui/core_window_visual_effect_test.py --build   # no input
tools/gui/flutter_visual_effect_test.py               # no input
tools/gui/flutter_detachable_window_and_browser_tabs_demo.py --record   # --only detachable|tabs, --keep-open
tools/gui/flutter_tray_icon_demo.py --record
tools/gui/flutter_floating_toolbar_demo.py --record
tools/gui/flutter_window_shape_demo.py --record

# Windows, from the Mac (examples built there in debug; see the remote-hosts skill)
R=.agents/skills/remote-hosts/scripts/remote.sh
$R win setup                       # "win" = the host name in remote-hosts/hosts/win.env
$R win desktop tools/gui/flutter_detachable_window_test.ps1 150
$R win desktop tools/gui/flutter_window_drag_areas_test.ps1 200
$R win desktop tools/gui/flutter_menu_test.ps1 400
$R win desktop tools/gui/core_window_drag_session_test.ps1 120
$R win desktop tools/gui/core_drag_drop_test.ps1 120
$R win desktop tools/gui/flutter_drag_drop_test.ps1 150
$R win desktop tools/gui/flutter_tray_icon_test.ps1 400
$R win desktop tools/gui/flutter_floating_toolbar_test.ps1 240
$R win desktop tools/gui/core_window_visual_effect_test.ps1 120
$R win desktop tools/gui/flutter_visual_effect_test.ps1 150
.agents/skills/record-demo/scripts/record_remote.sh win tools/gui/flutter_detachable_window_and_browser_tabs_demo.ps1 tools/gui/output
.agents/skills/record-demo/scripts/record_remote.sh win tools/gui/flutter_floating_toolbar_demo.ps1 tools/gui/output
.agents/skills/record-demo/scripts/record_remote.sh win tools/gui/flutter_window_shape_demo.ps1 tools/gui/output

# Linux, from the Mac (GNOME; "linux" = the host name in remote-hosts/hosts/linux.env)
R=.agents/skills/remote-hosts/scripts/remote.sh
$R linux setup
$R linux run tools/gui/build_core_example_linux.sh window_drag_session_example
$R linux desktop tools/gui/core_window_drag_session_test_linux.py 180
$R linux desktop tools/gui/flutter_floating_toolbar_test_linux.py 120   # no input; Wayland client
$R linux desktop tools/gui/flutter_tray_icon_test_linux.py 300   # example built in the host's checkout
$R linux desktop tools/gui/flutter_window_shape_demo_linux.py 240   # dry run: no recorder
.agents/skills/record-demo/scripts/record_remote_linux.sh linux \
    tools/gui/flutter_window_shape_demo_linux.py tools/gui/output   # the take
```

The shape demo runs against a debug build of the example in the host's scratch dir
(`$REMOTE_SCRATCH/shape-flutter-linux/examples/flutter_shaped_window_example`, or `SHAPE_EXAMPLE_DIR`);
put one there with `git archive <sha> pubspec.yaml bindings/dart examples/flutter_shaped_window_example | ssh <host> "mkdir -p ... && tar -x -C ..."` (the example resolves through the root pub workspace, so all three paths are needed)
when the host cannot reach its own remote, then `--build`. A host with **no monitor attached**
cannot record it at all — see the Linux section of `record-demo/SKILL.md` and
`remote-hosts/references/linux.md#no-display-attached`.

The Linux scripts build and run out of the host's scratch directory, from a snapshot of
`core/` rather than the host's checkout — that keeps a test run independent of whatever
is being edited there. `build_core_example_linux.sh` expects the snapshot in
`$REMOTE_SCRATCH/core-src`; create it with
`git -C core archive HEAD | ssh <host> "mkdir -p ~/tmp/claude/core-src && tar -x -C ~/tmp/claude/core-src"`.

Each test prints `PASS`/`FAIL` lines and exits with the number of failures. A `SKIP`
means the desktop did not allow a step (for example no bare desktop visible to click).

## Recordings

Videos go to `tools/gui/output/` (git-ignored), named after the script that made them,
as recorded — nothing is trimmed or re-encoded afterwards. A new take overwrites the
previous one.

| File | What |
| --- | --- |
| `<script name>-<os>.mp4` | the recording (`--record` on macOS, the record-demo skill's `record_remote.sh` for a remote host) |
| `<script name>-<only>-<os>.mp4` | a single scenario recorded with `--only` (macOS) |
| `<script name>-<os>.log` | the scenario log of a remote take |

A Windows host encodes the MP4 itself (ffmpeg must be installed there);
`record_remote.sh` copies it to the output directory and removes it from the host.

## Naming

`<binding>_<example>_test.<ext>` for tests and `<binding>_<what it shows>_demo.<ext>` for
recording scenarios, where `<binding>_<example>` is the example's directory name under
`examples/` without its `_example` suffix (`examples/flutter_menu_example` →
`flutter_menu_test`), and `core_<example>` for the C++ examples in `core/examples`; a test exists once per platform it runs on: `.py` runs on macOS,
`.ps1` on Windows, `…_linux.py` on Linux (both are Python, and names must be unique:
remote hosts receive them in one flat directory).

## Adding a test

Copy `.agents/skills/gui-test/templates/test_template.{py,ps1}` here and fill it in.
Keep the `.ps1` files ASCII.
