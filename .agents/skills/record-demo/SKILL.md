---
name: record-demo
description: Produce a polished demo video of a desktop app — launch it, play a scripted scenario with smooth synthetic mouse input, capture the screen with cursor and click highlights, and deliver an X/Twitter-ready MP4 (H.264, yuv420p, no audio, no keyboard input) — on macOS locally or on a remote Windows host. Use this whenever the user wants a demo video, screen recording, GIF-like clip, or "something to post" showing a feature or an example app, asks to re-record after a UI change, or asks to trim/clean/re-encode such a recording; also use its video.py for any find-the-cut-points, contact-sheet, or frames-to-MP4 job.
---

# record-demo

A demo is a `gui-test` scenario played slowly and nicely, with a recorder running.
Everything in `gui-test` (safety rules!) applies; this skill adds
recording, pacing, and post-production.

| | macOS | Windows |
| --- | --- | --- |
| recorder | `scripts/macos/recorder.py` (`Recorder`) | `scripts/windows/recorder.ps1` (`[ScreenRecorder]`) |
| capture method | `screencapture -v -C -k` → `.mov` → ffmpeg | GDI screen grabs → JPEG frames + `times.txt` |
| scenario template | any `gui-test` script wrapped in `Recorder` | `templates/record_template.ps1` |
| post | `Recorder.convert()`; `scripts/video.py` to trim | `remote.sh <host> pull frames`, then `scripts/video.py` |

The recorders and `video.py` know nothing about any particular app. **Scenarios are
project code, not part of this skill** — in this workspace they live in `tools/gui/`
(`*_demo.py`, `*_demo.ps1`); read those before writing a new one, and put
new ones there.

## macOS

```python
from recorder import Recorder          # sys.path: .agents/skills/record-demo/scripts/macos
recorder = Recorder('demo.mp4')
recorder.start()                       # SystemExit with a hint if permission is missing
try:
    play_scenarios()                   # gui-test harness calls
finally:
    recorder.stop()
recorder.convert()                     # → H.264, 60 fps, fits 1920×1200, no audio
```

A recording takes over the mouse for a minute or two, so **the user runs it, or
explicitly tells you to** — they are usually sitting at this Mac. Give the script a
countdown and an idle check before it starts. The terminal (or Claude app) needs
Accessibility and Screen Recording permission; without the latter `screencapture`
exits immediately and `Recorder` says so.

## Windows

```bash
R=.agents/skills/remote-hosts/scripts/remote.sh
$R <host> setup
$R <host> desktop <scenario.ps1> 400      # prints the scenario log when done; look for ERROR
$R <host> pull <scenario name>.frames ./frames
.agents/skills/record-demo/scripts/video.py encode-frames ./frames <scenario name>-windows.full.mp4
```

A project usually wraps these steps (here: `tools/gui/record_remote.sh <host> <scenario.ps1>`).
Have each scenario record into `$RemoteScratch\<scenario name>.frames` so takes of
different scenarios never mix.

- The apps must already be built there in debug (see `remote-hosts`).
- **The whole screen is in the picture.** Before recording, look at the desktop
  (`desktop_survey.ps1`): another app's window — especially a maximized one — becomes
  the backdrop of the video and shows whatever the user had open (code, chats, file
  names), besides blocking clicks. A take like that is a pipeline test, not a
  deliverable: ask the user to clear the desktop (do not close their apps yourself),
  and check a contact sheet for stray content before sending anything. Keep the
  previous good take until the new one is confirmed better.
- `recorder.ps1` grabs the primary screen on a background thread, draws the cursor and
  a yellow disc while the button is down, and JPEG-encodes on 3 writer threads. On
  the test laptop (2560×1600) that reaches ~21–25 fps; `encode-frames` keeps real
  timing from `times.txt` and resamples to 30 fps. Expect fast drags to look a little
  less smooth than on macOS. ~2400 frames ≈ 1 GB of JPEGs: pull, encode, then delete
  `frames\` remotely.

## Writing a scenario

What makes a scenario watchable:

- **Tell one story per app**: give the UI some visible state → show the feature →
  end on proof (the state survived, the window landed where it was dropped).
  45–60 s per app.
- **Pace for a viewer, not a test**: 400–700 ms eased approaches, drags in 2–3 legs of
  350–1100 ms with a short first leg, 1.2–1.5 s rest after each drop, 2.5 s hold on
  the final frame.
- **No keyboard input and no audio** (user requirement; also the safest).
- Re-probe after every gesture; views keep their identity, windows do not. Track
  "which window shows which view" by view name.
- Dry-run the scenario as a plain `gui-test` (no recorder) before spending a take on
  it; give scripts a way to run a single scenario and to leave the app open.
- One app at a time: quit it before launching the next, with a ~1.5 s gap that
  becomes the transition.

## Post-production with `scripts/video.py`

```bash
V=.agents/skills/record-demo/scripts/video.py
$V scenes full.mp4                       # big changes: app windows appearing / closing
#   scores depend on contrast with the backdrop: try --threshold 0.03 if nothing shows up
$V scenes full.mp4 --from 58 --to 66 --threshold 0.02   # zoom in when a change is small
$V freezes full.mp4                      # dead time
$V sheet full.mp4 check.jpg --at 3.9,4.2,61.9,62.25     # look at candidate cut points
$V cut full.mp4 demo.mp4 --keep 4.2-58.3 --keep 62.25-111.1
$V sheet demo.mp4 final.jpg --every 10   # and look at the result
$V info demo.mp4
```

Trim so that:

- it **starts on a fully rendered app**. A window is *visible* a few hundred ms before
  Flutter paints its first frame — cutting exactly at the scene change leaves blank
  white windows. Cut ~0.3 s after the change and confirm on a contact sheet. The same
  applies at the start of every later segment;
- launch/countdown time at the head and the idle tail after the last window closes are
  gone (the user asked for exactly this: "cut the first 6 s and the blank end");
- a short (<0.5 s) bare-desktop beat between examples stays as a transition.

Always **look** at the sheet (Read the JPEG) before delivering; numbers alone missed
the blank-window frames once.

## Delivery checklist

- `video.py info`: `h264` / `High`, **`yuv420p`** (not `yuvj420p` — JPEG-sourced video
  is full-range unless converted; `video.py` converts), ≤ 1920×1200, ≤ 60 fps, no
  audio stream. X also wants ≤ 140 s and ≤ 512 MB.
- One output directory, git-ignored, files named after the script that produced them:
  `<script name>-<os>.full.mp4` for the raw take and `<script name>-<os>.mp4` for the
  trimmed cut (in this workspace: `tools/gui/output/`; macOS scenarios default
  `--record` to it and `tools/gui/record_remote.sh` does the same for remote hosts).
  Never commit videos. Send the file to the user and say where it is, its length, and
  any caveat (e.g. capture frame rate).
- Report what the scenario log proved (state preserved, windows moved N times), since
  the video is also evidence that the feature works on that platform.
