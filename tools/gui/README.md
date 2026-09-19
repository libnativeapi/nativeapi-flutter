# tools/gui

Real-desktop GUI tests and demo-recording scenarios for the examples. They launch the
built example, drive it with synthetic mouse input, and check real window geometry and
on-screen state — things unit and widget tests cannot see.

The generic machinery (UI probe, input drivers, app harness, screen recorders, remote
runner) lives in [`.agents/skills/`](../../.agents/skills); read
`gui-test/SKILL.md` there first — especially the safety rules. This directory only holds what is specific to our examples.

| Script | Example | Platform | Covers |
| --- | --- | --- | --- |
| `flutter_detachable_window_test.py` / `.ps1` | `detachable_window_example` | macOS / Windows | tear a panel off, exact content size, header stays under the cursor, dock into the other window, `State` preserved |
| `flutter_window_drag_areas_test.py` / `.ps1` | `window_drag_areas_example` | macOS / Windows | `DragToMoveArea`: window follows the mouse, a click does not move it, double click maximizes and restores; `DragToResizeArea`: all eight handles, the other edges stay anchored, minimum size, `enableResizeEdges`, clicks pass through the middle |
| `flutter_menu_test.py` / `.ps1` | `menu_example` | macOS / Windows (WinUI 3 and Native backends) | context menu opens at the click point; placement Top End (also after the menu changed); item types and states (checkbox, radio group, disabled, submenu, special characters); click / open / close / submenu events; dismissing fires no click; label change, added item and detached submenu show on the next open; absolute and cursor positioning |
| `flutter_window_events_test.py` | `window_example` | macOS | `WindowManager.addListener` really is called: focused on activation, moved and resized when the frame changes (through Accessibility, one click only), payloads equal to the frame the OS reports |
| `core_window_drag_session_test.py` / `.ps1` / `_linux.py` | core `window_drag_session_example` (C++) | macOS / Windows / Linux | dock by dragging onto another window, tear off anchored under the cursor, event output; the Linux twin also checks that the panel follows the cursor while carried |
| `core_menu_backend_test.ps1` | core `tests/menu_click_test.cpp` | Windows | native menu backend: a top-level and a submenu item click reach the listener *before* `Menu::Open()` returns and fire exactly once; dismissing without picking fires none. The test binary owns the assertions, the script owns the mouse |
| `core_drag_drop_test.py` / `.ps1` | core `drag_drop_example` (C++) | macOS / Windows | `DragSource` → `DropTarget` across two windows: enter / move / drop events, dropped file path and text, drop position in content coordinates, source reports `copy`; a drag released where nothing accepts it reports exit and `none` |
| `flutter_drag_drop_test.py` / `.ps1` | `drag_drop_example` | macOS / Windows | `DragOutArea` → `DropRegion` in one window: a file and a text drop arrive, the source sees `copy`, the highlight clears, a second drag works after the first |
| `flutter_tray_icon_test.py` | `tray_icon_example` | macOS | animated tray icons: frames really are rendered and pushed (counter, 30 and 60 fps, no dropped frames, Pause / Step / Resume, 3x resolution), a live widget captured into frames, the Download scene driving the title, three icons animating at once; title / tooltip / visibility / trigger / bounds read back from the native getters; the menu opened from code shows its items and states, an item click arrives, `closeContextMenu` closes it; the example's own checklist has no unexpected failures. Not covered: clicks on the tray icon itself — the input driver refuses the menu-bar layer, those stay manual items of the example's Checklist tab |
| `flutter_detachable_window_and_browser_tabs_demo.py` / `.ps1` | both Flutter examples | macOS / Windows | the demo video scenarios; also the only coverage of `browser_tabs_example` (reorder, tear off, merge, move by the strip; its log ends with the preserved page state, no PASS/FAIL checks) |
| `flutter_tray_icon_demo.py` | `tray_icon_example` | macOS | the tray demo video: the window sits under the menu bar so the real icon and the magnified preview are in one picture; gallery, widget capture, 10 → 60 fps, Pause / Step, scenes, three icons at once, menu opened and closed from code, checklist |

`common.py` points the macOS scripts at the skills' harness and at
`bindings/flutter/examples`. The Linux scripts import `guiapp` straight from the flat
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
tools/gui/core_window_drag_session_test.py --build   # builds the example into core/build
tools/gui/core_drag_drop_test.py --build
tools/gui/flutter_drag_drop_test.py
tools/gui/flutter_tray_icon_test.py
tools/gui/flutter_detachable_window_and_browser_tabs_demo.py --record   # --only detachable|tabs, --keep-open
tools/gui/flutter_tray_icon_demo.py --record

# Windows, from the Mac (examples built there in debug; see the remote-hosts skill)
R=.agents/skills/remote-hosts/scripts/remote.sh
$R win setup                       # "win" = the host name in remote-hosts/hosts/win.env
$R win desktop tools/gui/flutter_detachable_window_test.ps1 150
$R win desktop tools/gui/flutter_window_drag_areas_test.ps1 200
$R win desktop tools/gui/flutter_menu_test.ps1 400
$R win desktop tools/gui/core_window_drag_session_test.ps1 120
$R win desktop tools/gui/core_drag_drop_test.ps1 120
$R win desktop tools/gui/flutter_drag_drop_test.ps1 150
.agents/skills/record-demo/scripts/record_remote.sh win tools/gui/flutter_detachable_window_and_browser_tabs_demo.ps1 tools/gui/output

# Linux, from the Mac (GNOME; "linux" = the host name in remote-hosts/hosts/linux.env)
R=.agents/skills/remote-hosts/scripts/remote.sh
$R linux setup
$R linux run tools/gui/build_core_example_linux.sh window_drag_session_example
$R linux desktop tools/gui/core_window_drag_session_test_linux.py 180
```

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
recording scenarios, where `<example>` is the example's directory name without its
`_example` suffix (`flutter_…` for `bindings/flutter/examples`, `core_…` for
`core/examples`); a test exists once per platform it runs on: `.py` runs on macOS,
`.ps1` on Windows, `…_linux.py` on Linux (both are Python, and names must be unique:
remote hosts receive them in one flat directory).

## Adding a test

Copy `.agents/skills/gui-test/templates/test_template.{py,ps1}` here and fill it in.
Keep the `.ps1` files ASCII.
