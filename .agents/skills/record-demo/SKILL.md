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

| | macOS | Windows |
| --- | --- | --- |
| recorder | `scripts/macos/recorder.py` (`Recorder`) | `scripts/windows/recorder.ps1` (`Start-Recording` / `Stop-Recording`) |
| capture | `screencapture -v -C -k` → `.mov` → ffmpeg → `.mp4` | GDI screen grabs → JPEG frames → ffmpeg **on the host** → `.mp4` |
| needs | ffmpeg (or `avconvert`), Screen Recording permission | ffmpeg on the Windows host (see below) |
| template | any `gui-test` script wrapped in `Recorder` | `templates/record_template.ps1` |
| run | the scenario script itself | `scripts/record_remote.sh` from the Mac |

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
  you mean to show — check that submodules such as the Flutter binding's `cxx_impl` are
  actually checked out at the recorded commit (`git submodule update`), not just
  pointed at it.
- **The whole screen is in the picture.** Before recording, look at the desktop
  (`desktop_survey.ps1`): another app's window — especially a maximized one — becomes
  the backdrop of the video and shows whatever the user had open, besides blocking
  clicks. Ask the user to clear it (do not close their apps yourself unless they ask).
- Only one job at a time may use a host's desktop: the `desktop` verb shares one
  scheduled task and `job.*` files per host. When another session also drives the same
  machines, agree on turns first.

## Writing a scenario

What makes a scenario watchable:

- **Tell one story per app**: give the UI some visible state → show the feature →
  end on proof (the state survived, the window landed where it was dropped).
  45–60 s per app.
- **Pace for a viewer, not a test**: 400–700 ms eased approaches, drags in 2–3 legs of
  350–1100 ms with a short first leg, 1.2–1.5 s rest after each drop, 2.5 s hold on
  the final frame.
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
