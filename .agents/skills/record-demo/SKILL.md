---
name: record-demo
description: Record a demo video of a desktop app — launch it, play a scripted scenario with smooth synthetic mouse input, and capture the screen (cursor and click highlights included) straight to an X/Twitter-ready MP4 (H.264, yuv420p, no audio, no keyboard input) — on macOS locally or on a remote Windows host, where the MP4 is encoded on the host and copied back. Use this whenever the user wants a demo video, screen recording, or "something to post" showing a feature or an example app, or asks to re-record after a UI change.
---

# record-demo

A demo is a `gui-test` scenario played slowly and nicely, with a recorder running.
Everything in `gui-test` (safety rules!) applies; this skill adds the recorders and the
pacing.

**It only records.** The output is the take as captured, encoded once to MP4 on the
machine that recorded it, named `<scenario script name>-<os>.mp4`. No trimming, no
re-encoding, no raw/cut pairs — if the user wants a cut, that is a separate request.

| | macOS | Windows | Linux (GNOME/Wayland) |
| --- | --- | --- | --- |
| recorder | `scripts/macos/recorder.py` (`Recorder`) | `scripts/windows/recorder.ps1` (`Start-Recording` / `Stop-Recording`) | `scripts/linux/recorder.py` (`Recorder`, `grab`) |
| capture | `screencapture -v -C -k` → `.mov` → ffmpeg → `.mp4` | GDI screen grabs → JPEG frames → ffmpeg **on the host** → `.mp4` | Mutter ScreenCast → PipeWire → `jpegenc` → JPEG frames → ffmpeg **on the Mac** → `.mp4` |
| needs | ffmpeg (or `avconvert`), Screen Recording permission | ffmpeg on the Windows host (see below) | PyGObject and `gst-launch-1.0` with `pipewiresrc`/`jpegenc` on the host, ffmpeg on the Mac |
| template | any `gui-test` script wrapped in `Recorder` | `templates/record_template.ps1` | any `gui-test` script wrapped in `Recorder` |
| run | the scenario script itself | `scripts/record_remote.sh` from the Mac | `scripts/record_remote_linux.sh` from the Mac |

The recorders know nothing about any particular app. **Scenarios are project code, not
part of this skill** — in this workspace they live in `tools/gui/` (`*_demo.py`,
`*_demo.ps1`); read those before writing a new one, and put new ones there. Videos go to
one git-ignored directory (here `tools/gui/output/`); a new take overwrites the old one.

## macOS

```python
from recorder import Recorder          # sys.path: .agents/skills/record-demo/scripts/macos
recorder = Recorder('output/<script>-macos.mp4')
recorder.start()                       # SystemExit with a hint if permission is missing
try:
    play_scenarios()                   # gui-test harness calls
finally:
    recorder.stop()
recorder.convert()                     # → H.264, 60 fps, fits 1920×1200, no audio
```

- A recording takes over the mouse for a minute or two, so **the user runs it, or
  explicitly tells you to** — they are usually sitting at this Mac. Give the script a
  countdown and an idle check before it starts.
- The process that runs it needs **Screen Recording** (and Accessibility for the
  input) in System Settings › Privacy & Security. Without it `screencapture` exits at
  once and `Recorder` says so; `screencapture -x /tmp/t.png` is a quick check. Only the
  user can grant it, and the app has to be restarted afterwards.
- **The whole main display is in the picture** — every window the user has open
  becomes the backdrop. Before recording, tell the user to hide what should not be
  seen; afterwards look at a few frames (`ffmpeg -ss <t> -i x.mp4 -frames:v 1 f.jpg`,
  then Read it) and warn them if private content (other projects, chats, paths) is
  visible.

## Windows

```powershell
# in the scenario (runs on the host's desktop session)
. "$PSScriptRoot\recorder.ps1"
$name = [IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
Start-Recording "$RemoteScratch\$name-windows.mp4"
try { ...scenario... } finally { Say "saved $(Stop-Recording)" }
```

```bash
# from the Mac: play, record and encode on the host, copy the MP4 into <output dir>
.agents/skills/record-demo/scripts/record_remote.sh <host> <scenario.ps1> <output dir>
```

It runs the `remote-hosts` steps (`setup`, `desktop`, `pull`, then removes the MP4 from
the host), keeps the scenario log next to the video, and fails when the log shows no
saved video or an `ERROR`.

- `Stop-Recording` encodes with the frames' real timing (the grabber reaches ~21–25 fps
  on a 2560×1600 laptop; the MP4 is resampled to 30 fps), fits 1920×1200, then deletes
  the frames. Encoding ~2 minutes of frames takes about a minute; allow for it in the
  `desktop` timeout.
- **ffmpeg on the host.** `Get-Ffmpeg` looks on PATH and in
  `%LOCALAPPDATA%\Programs\ffmpeg\bin`, scoop, winget and chocolatey locations. To
  install it on a host that has none: download the official Windows build
  (`github.com/GyanD/codexffmpeg` releases, `ffmpeg-<ver>-essentials_build.zip`) — on
  the Mac if the host cannot reach GitHub —, check its sha256 against the release's
  asset digest, `remote.sh <host> push` it, and extract it on the host to
  `%LOCALAPPDATA%\Programs\ffmpeg` (add `bin` to the user PATH). Package managers are
  optional: the test laptop's scoop was broken (self-update fails, the 7zip dependency
  would not install), and winget asks to accept agreements.
- The apps must already be built there in debug (see `remote-hosts`), from the checkout
  you mean to show — check that the `core` submodule is
  actually checked out at the recorded commit (`git submodule update`), not just
  pointed at it.
- **The whole screen is in the picture.** Before recording, look at the desktop
  (`desktop_survey.ps1`): another app's window — especially a maximized one — becomes
  the backdrop of the video and shows whatever the user had open, besides blocking
  clicks. Ask the user to clear it (do not close their apps yourself unless they ask).
- Only one job at a time may use a host's desktop: the `desktop` verb shares one
  scheduled task and `job.*` files per host. When another session also drives the same
  machines, agree on turns first.

## Linux (GNOME/Wayland)

```python
import sys; sys.path.insert(0, '.agents/skills/record-demo/scripts/linux')
from recorder import Recorder, grab

frame = grab('/tmp/look.png')     # one PNG of the monitor, for locating windows
rec = Recorder('$REMOTE_SCRATCH/<name>-linux.mp4')   # frames land in <output>.frames/
rec.start()                       # returns once the stream really is producing frames
try:
    ...                           # play the scenario
finally:
    rec.stop(); rec.report()      # prints RECORD_FRAMES <dir> — the wrapper reads that line
```

```bash
# from the Mac: play on the host, pull the frames, encode here, copy the MP4 into <output dir>
.agents/skills/record-demo/scripts/record_remote_linux.sh <host> <scenario.py> <output dir>
```

There is no screen-capture shortcut on GNOME 46 to fall back on: `gnome-screenshot` is not
installed, `org.gnome.Shell.Screenshot` answers `AccessDenied`, and XTEST/Xlib see no Wayland
window. Capture goes through `org.gnome.Mutter.ScreenCast` → PipeWire, and **the pointer is
only in the picture if the stream is a real monitor recorded with `cursor-mode: 1`** (Mutter
composites the cursor in; the frames have it — check one before publishing).

- **The host encodes nothing.** A minimal Linux host has no ffmpeg and its GStreamer may have
  no H.264 encoder at all (`x264enc`, `avenc_h264`, `openh264enc`, `vaapih264*` were all
  missing on ours). So the recorder writes one JPEG per frame plus their real write times —
  the source is live, so the gaps between files are the gaps between frames — and the wrapper
  pulls the frames to the Mac and encodes them there (`recorder.encode`, a variable-framerate
  concat list, H.264 High, yuv420p, no audio, resampled to 30 fps, fitted to 1920×1200).
  Frames are scaled down to fit 1920×1200 **at capture time**: the stream is the whole monitor
  (2560×1440 here) and there is no point shipping pixels the MP4 will drop.
- Throughput is what the host's CPU manages: ~21 fps for raw 1440p, ~28 fps when `videoscale`
  fits 1080p first, on a 2-core Celeron. Mutter produces frames on damage, so a still picture
  costs nothing and only motion costs frames — which is exactly where a demo needs them.
- **A host with no monitor attached cannot be recorded.** If both outputs are disconnected
  (`/sys/class/drm/*/status` says `disconnected`), DisplayConfig reports no monitors at all:
  there is nothing to RecordMonitor, no `wl_output` for the app to place a window on, and
  `ScreenCast.RecordVirtual` is *not* a way out — a virtual monitor is not a `wl_output`
  (GDK logs `gdk_monitor_get_scale_factor: assertion 'GDK_IS_MONITOR (monitor)' failed`, the
  app's windows never appear on it) and Mutter paints no pointer into a virtual stream, in
  cursor-mode 0 or 1. Check `/sys/class/drm/*/status` and DisplayConfig before spending a take,
  and report the blocker instead of shipping a cursor-less video.
- The scenario's safety rule is `gui-test`'s, but there is no Xlib owner check to lean on for
  a Wayland client: refuse any press that the captured frame does not place inside the app's
  own located window, keep generous margins, and prefer driving the pointer only where a
  probe can prove the click arrived.

## Writing a scenario

What makes a scenario watchable:

- **Tell one story per app**: give the UI some visible state → show the feature →
  end on proof (the state survived, the window landed where it was dropped).
  45–60 s per app.
- **Pace for a viewer, but brisk** — the user found a relaxed pace (400–700 ms
  approaches, 350–1100 ms drag legs, 1.2–1.5 s rests) too slow. Aim for about half
  that: 200–350 ms approaches, drags in 2–3 legs of 150–550 ms with a short first leg,
  ~0.7 s after each drop (enough for new windows to appear before the next probe),
  1.2 s hold on the final frame. Keep one speed factor in the scenario (`--pace` /
  `$Pace`) that scales every motion and pause, with floors for the pauses that wait
  for windows, so the tempo can be tuned in one place.
- **Keep dead time out at the source**, since nothing is trimmed later: start the
  recorder right before the first app launches, and stop it right after the last one
  quits.
- **No keyboard input and no audio** (user requirement; also the safest).
- Re-probe after every gesture; views keep their identity, windows do not. Track
  "which window shows which view" by view name.
- Dry-run the scenario as a plain `gui-test` (no recorder) before spending a take on
  it; give scripts a way to run a single scenario and to leave the app open.
- Have the scenario log its proof (e.g. the state texts at the end) — the log is how
  you tell a good take from a bad one without watching it.
- One app at a time: quit it before launching the next, with a ~1.5 s gap that
  becomes the transition.

## Delivery

- Check the file: `ffprobe -v error -show_entries stream=codec_name,pix_fmt,width,height,r_frame_rate:format=duration x.mp4`
  → `h264`, `yuv420p`, ≤ 1920×1200, ≤ 60 fps, no audio stream (X also wants ≤ 140 s and
  ≤ 512 MB).
- Look at a handful of frames spread over the take (Read the JPEGs): the apps are
  rendered, nothing private is in the background, the scenario did what the log says.
- Send the file to the user, say where it is and how long it is, and report what the
  scenario log proved (state preserved, windows moved N times) — the video is also
  evidence that the feature works on that platform. Never commit videos.
