# tools/gui

Real-desktop GUI tests and demo-recording scenarios for the examples. They launch the
built example, drive it with synthetic mouse input, and check real window geometry and
on-screen state — things unit and widget tests cannot see.

The generic machinery (UI probe, input drivers, app harness, screen recorders, video
tools, Windows remote runner) lives in [`.agents/skills/`](../../.agents/skills); read
`gui-test/SKILL.md` there first — especially the safety rules. This directory only holds what is specific to our examples.

| Script | Example | Platform | Covers |
| --- | --- | --- | --- |
| `flutter_detachable_window_test.py` / `.ps1` | `detachable_window_example` | macOS / Windows | tear a panel off, exact content size, header stays under the cursor, dock into the other window, `State` preserved |
| `core_window_drag_session_test.py` / `.ps1` | core `window_drag_session_example` (C++) | macOS / Windows | dock by dragging onto another window, tear off anchored under the cursor, event output |
| `flutter_detachable_window_and_browser_tabs_demo.py` / `.ps1` | both Flutter examples | macOS / Windows | the demo video scenarios; also the only coverage of `browser_tabs_example` (reorder, tear off, merge, move by the strip; its log ends with the preserved page state, no PASS/FAIL checks) |

`common.py` points the macOS scripts at the skills' harness and at
`bindings/flutter/examples`.

## Running

Every script takes over the mouse. It refuses to start while the mouse is moving and
stops as soon as a press would land outside the example's own windows. No keyboard
input is ever sent.

```bash
# macOS (examples built with `flutter build macos --debug`, or pass --build)
tools/gui/flutter_detachable_window_test.py
tools/gui/core_window_drag_session_test.py --build   # builds the example into core/build
tools/gui/flutter_detachable_window_and_browser_tabs_demo.py --record   # --only detachable|tabs, --keep-open

# Windows, from the Mac (examples built there in debug; see the remote-hosts skill)
R=.agents/skills/remote-hosts/scripts/remote.sh
$R win setup                       # "win" = the host name in remote-hosts/hosts/win.env
$R win desktop tools/gui/flutter_detachable_window_test.ps1 150
$R win desktop tools/gui/core_window_drag_session_test.ps1 120
tools/gui/record_remote.sh win tools/gui/flutter_detachable_window_and_browser_tabs_demo.ps1   # play, pull frames, encode
```

Each test prints `PASS`/`FAIL` lines and exits with the number of failures. A `SKIP`
means the desktop did not allow a step (for example no bare desktop visible to click).

## Recordings

Videos go to `tools/gui/output/` (git-ignored), named after the script that made them:

| File | What |
| --- | --- |
| `<script name>-<os>.full.mp4` | the raw take (`--record` on macOS, `record_remote.sh` for a remote host) |
| `<script name>-<os>.mp4` | the trimmed, deliverable cut (made with the record-demo skill's `video.py cut`) |
| `<script name>-<only>-<os>.mp4` | a single scenario recorded with `--only` |
| `<script name>-<os>.log` | the scenario log of a remote take |

A Windows scenario records frames into `$RemoteScratch\<script name>.frames`;
`record_remote.sh` pulls them, encodes, and deletes them on both sides.

## Naming

`<binding>_<example>_test.<ext>` for tests and `<binding>_<what it shows>_demo.<ext>` for
recording scenarios, where `<example>` is the example's directory name without its
`_example` suffix (`flutter_…` for `bindings/flutter/examples`, `core_…` for
`core/examples`); a test exists once per platform it runs on: `.py` runs on macOS,
`.ps1` on Windows. Names must be unique: remote hosts receive them in one flat directory.

## Adding a test

Copy `.agents/skills/gui-test/templates/test_template.{py,ps1}` here and fill it in.
Keep the `.ps1` files ASCII.
