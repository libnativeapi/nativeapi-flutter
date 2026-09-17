---
name: gui-test
description: End-to-end test a desktop app (Flutter desktop apps and plain native executables such as C++ examples) by launching the real app, driving it with guarded synthetic mouse input — eased moves, clicks, multi-leg drags, wheel, on macOS (CGEvent) and Windows (SendInput) — and asserting on real window geometry and on-screen state, locally on macOS and remotely on Windows. Use this whenever a change touches window behaviour that unit/widget tests cannot see — dragging, tear-off and docking, title bars, hit testing, z-order, focus, multi-window, DPI — or when the user asks "does it actually work", "test it for real", "verify on Windows/macOS", or reports a bug that only shows with a real mouse. Also read it before posting ANY synthetic input or querying which app owns a screen point, even outside a test: it carries the safety rules that keep a script from clicking on the user's other apps. Prefer it over declaring a windowing change done after only compiling it.
---

# gui-test

Widget tests prove the Dart logic; they cannot prove that the OS moved a window,
that a drag survived its source window disappearing, or that a hit test looked
through an overlay. For those, run the real app and look at the real desktop.

Related skills: `flutter-ui-probe` — what the app shows and where (texts → rects, per
window); `remote-hosts` — running any of this on another machine (the Windows laptop, …).

## Safety rules — read before sending any input

Synthetic input goes wherever the cursor is, into whatever window is there. A wrong
coordinate is a click in the user's editor, browser, or menu bar. This has happened:
a drag once ran with empty coordinates and pressed near the menu bar. So:

1. **Check the machine is idle first** (`assert_idle()` / `Assert-Idle`): if the cursor
   moves on its own, a person is using the machine — stop, do not fight them for the
   mouse. When the user is actively working on the same machine, ask before running,
   or have them run the script themselves.
2. **Check the owner of every press point** (the harness does it in every `click`/`drag`/`scroll`; raw: `input owner x y` / `Assert-Owner pid x y`)
   and abort if the pixel does not belong to the app under test. Do this right before
   the press, after the approach move — windows move.
3. **Never press outside the app's own windows.** The one exception is
   `Click-Desktop` on Windows, which verifies the target really is the desktop
   (`Progman`/`WorkerW`) — useful to take focus away.
4. **Validate arguments before calling the driver.** Empty or non-numeric
   coordinates must be an error in your script, not `0 0`.
5. **No keyboard input.** Keys go to whatever has focus, which you cannot verify as
   cheaply as a pixel's owner. If a scenario needs text, pre-fill it in the app.
6. Always release: drags end with a mouse-up even on failure paths (both drivers'
   `drag` do; do not compose your own press/release across separate calls).

## The harness

One per OS, same shape, built on the input drivers in the same `scripts/` directory
(`input` + `input.m`; `winput.ps1`, `desktop_survey.ps1` — reference:
[references/input-drivers.md](references/input-drivers.md)):

| | macOS | Windows |
| --- | --- | --- |
| harness | `scripts/macos/guiapp.py` (`GuiApp`, `Checks`) | `scripts/windows/guiapp.ps1` (`Start-GuiApp`, `Start-ConsoleApp`, `Invoke-Drag`, `Check`, …) |
| template | `templates/test_template.py` | `templates/test_template.ps1` |
| run | directly | `remote.sh <host> setup` then `remote.sh <host> desktop <test.ps1> <timeout>` (`remote-hosts` skill) |

The harness knows nothing about any particular app. **Tests are project code, not part
of this skill**: copy a template next to the project's other GUI tests (in this
workspace: `tools/gui/`, which also holds finished tests worth reading as examples),
fill in the TODOs, and keep app-specific knowledge — titles, texts, expected sizes —
there.

## The loop

1. **Build** the example in debug (`flutter build macos|windows --debug`; C++ examples
   via CMake). Debug is required for the UI probe.
2. **Idle check**, then **launch** with stdout to a log and wait for the windows *and*
   the VM service (`app.launch(min_windows=n)` / `Start-GuiApp … -MinViews n`). Native
   executables without a Dart VM: `launch(flutter=False)` / `Start-ConsoleApp`.
3. **Look**: window frames from the OS, views from the probe. Identify a window's view
   by a text only it shows, not by index.
4. **Act**: one gesture (`click`, multi-leg `drag`, `scroll`), owner-checked.
5. **Settle** 1–1.5 s, then **look again** — never reuse coordinates from before the
   gesture.
6. **Assert** (below), collecting PASS/FAIL so one failure does not hide the rest.
7. **Quit the app in `finally`**, and print/keep the app log.

On a machine the user is sitting at, say what is about to happen (“this will take
over the mouse for ~20 s”) and let them start it, or wait for a clear go-ahead.

## What to assert

Assert on things the OS or the render tree report, in numbers:

- **Window set**: titles before/after (a tear-off adds a window; docking removes it).
- **Geometry**: content size of a floating window equals the slot it left (logical
  px; on Windows `ClientW / Scale`); the grabbed point is still under the cursor
  after the drop (`to_screen(center of header) ≈ drop point`, ±2–3 px); a window did
  **not** move when it should not have (e.g. after switching title-bar style).
- **Where content lives**: the text is now in *that* view (`view_b.has('…')`).
- **State preservation**: counters, timers, scroll positions survive reparenting. It
  helps when the app shows an instance label ("State #1") — a rebuilt widget would show
  `#2` or a reset counter.
- **App output**: for native examples assert on the event lines they print
  (`app.output()` / the lines `Stop-GuiApp` returns).
- **Negative paths**: release right after the press (a click must not start a drag or
  make a window jump), drop outside every target, drag back to the origin slot.

Screenshots are for *you* to understand a failure, not for assertions.

## Platform notes that cost time before

**macOS**

- The content view sits at the bottom of the AX frame; `to_screen` accounts for the
  title bar by using `frame height − view height`. With a hidden title bar the
  difference is 0 and it still holds.
- The system itself drags a window pressed in its title-bar band — even over opaque
  content when the title bar is hidden. If a drag moves the *whole window* instead of
  the widget, that is this (fixed in core by `movable = NO` while hidden), not your
  script.
- The app must be activated before the first click counts (`launch` does it). A plain
  `NSRunningApplication activate` from a background tool is often ignored (cooperative
  activation, macOS 14+); the driver's `activate` also sets `AXFrontmost` and raises
  the windows through Accessibility, which works.
- To make the next press a *focus change* (apps that react to focus), use
  `app.blur()`: it activates the Dock process, which has no windows. Activating Finder
  instead brings a Finder window forward, over the app. If the
  very first owner check fails with another app's pid, that app kept the front —
  usually because the user is working in it. Do not retry in a loop; ask.

**Windows**

- Foreground, covering windows, click-through overlays, console windows: see the
  Windows section of [references/input-drivers.md](references/input-drivers.md).
  `Invoke-Activate` already lifts and activates a window; when a press is refused or
  ignored, run `desktop_survey.ps1 -X <x> -Y <y>` to see what is stacked there.
- Physical vs logical pixels: probe coordinates × `Scale`; window rects are already
  physical. Mixing them up produces errors proportional to the distance from the
  client origin — a telltale sign.
- A lone pan recognizer wins the gesture arena on pointer-up, so a plain click fires
  `onPanStart` *after* the button is released. A native drag session started there
  must not move anything (core handles it; keep a click-only negative test).
- PowerShell 5.1's `ConvertFrom-Json` emits a JSON array as one object; piping it
  straight into `Where-Object` filters nothing. `Get-Views` already unrolls it — do the
  same (assign first) if you parse JSON yourself.
- `$home`, `$host`, `$input`, `$args`, `$pid` are reserved: pick other variable names.
- Title matching: use wildcards around non-ASCII (`"*Settings"`), the `.ps1` must stay
  ASCII.

**Both**

- A cold debug start can take 10+ s; poll, do not sleep blindly.
- If a gesture is "not recognised", suspect speed and shape before logic: add a short
  first leg, lengthen durations, make sure the approach move ended on the target.
- When something only fails on the test machine, survey the desktop
  (`desktop_survey.ps1`, `input owner`) before debugging the app: more than once the
  culprit was another program's window.

## Making motion look human (and work)

- Approach with an eased `move`/`Glide` (400–700 ms) before pressing: hover states
  settle, and recordings look natural.
- Drag in at least two legs: a short first leg (40–80 px, 350–500 ms) to get past the
  app's drag threshold / pop-out distance, then the long leg to the target. One
  instantaneous jump is often not recognised as a drag at all.
- Pause 1–1.5 s after a drop before probing again: windows are created, destroyed,
  and laid out asynchronously.

## Debugging a failing scenario

- Re-run up to the failing step and stop with the app open (`app.keep_open = True`;
  on Windows skip `Stop-GuiApp`) and probe by hand: `uiprobe.py <log> --texts`.
- Add temporary `debugPrint`/`std::cout` lines in the example; they land in the app
  log the harness already keeps. Remove them, and on Windows restore the remote
  checkout, when done.
- Fix the root cause in `core/` or the example, not by lengthening pauses until it
  passes.

## Reporting

State per platform what was actually run and observed — e.g. "Windows: 23 checks
passed (tear-off, merge, state preserved, content size exact); macOS: harness smoke
test only, no input sent; Linux: compiled only, not run". Never report a platform as verified because the code was
written for it.
