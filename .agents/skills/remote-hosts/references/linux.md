# Linux hosts

**Status: `setup`, `exec` and `desktop` verified on Ubuntu 24.04 (GNOME) on 2026-09-17.
On 2026-09-18 `flutter build linux --debug` in the SSH session and launching the bundle
from `desktop` both worked (menu_example), and a full GUI test with synthetic input ran
green against a C++ example (`tools/gui/core_window_drag_session_test_linux.py`).**
On 2026-09-24 the host lost its display for good mid-session (see "No display attached"
below) — check for that first when everything suddenly answers with empty geometry.
Verify each further step the first time and update this file with what you learn — the
Windows notes were all learned the hard way.

## Two places a script can run

**SSH session (`exec`, `run`)**: a plain login shell. No `DISPLAY`, so GUI programs
fail with "cannot open display". Fine for git, builds (`cmake`, `flutter build linux`),
logs.

**Logged-on desktop (`desktop`)**: `scripts/posix/desktop.sh` runs the script with the
environment of the user's graphical session, imported from
`systemctl --user show-environment` (GNOME puts `WAYLAND_DISPLAY`, `DISPLAY`,
`XAUTHORITY`, `XDG_SESSION_TYPE`, `XDG_CURRENT_DESKTOP` there). Fallbacks when that is
empty: `DISPLAY` = `HOST_DISPLAY` (default `:0`), `XAUTHORITY` from the `-auth` argument
of the Xorg/Xwayland process serving that display, then `~/.Xauthority`. The same user
must be logged on at the console. On a Wayland session GTK then picks its Wayland
backend (`GdkWaylandDisplay`), exactly as for an app started from the dock; force
`GDK_BACKEND=x11` in the script to test the Xwayland path instead.

Scripts start with:

```bash
. "$(dirname "$0")/env.sh"      # REMOTE_WORKSPACE, REMOTE_SCRATCH, PYTHON, PATH additions
```

## Wayland (the user's host runs GNOME 46 on Wayland — that is the target, not a problem to fix)

- **Check the session type, do not assume**: `loginctl show-session <id> -p Type` for the
  seat0 session (`who` shows `seat0 (login screen)` / `tty2` even while logged in).
- What a client cannot do on Wayland, by design: know its global window position, read
  the global pointer, see other apps' windows or stacking order. Core code already
  branches on this (`window_manager_linux.cpp`, `window_drag_session_linux.cpp`);
  `keyboard_monitor` and `shortcut_manager` are Xlib-based and only see Xwayland.
- What the test harness can use instead (probed 2026-09-17, desktop session, no prompts):
  - **Input**: `org.gnome.Mutter.RemoteDesktop` on the session bus — `CreateSession`
    succeeds for a direct (non-sandboxed) caller with no consent dialog. Relative pointer
    motion, buttons, axis and keys work on the session alone; absolute motion needs a
    `ScreenCast` stream attached to the session. This is what the `gui-test` Linux driver
    is built on (`scripts/linux/xinput.py`), and it is real input: it focuses and raises
    windows like a hand on the mouse. Creating the screen cast is two more D-Bus calls
    (`ScreenCast.CreateSession` with `remote-desktop-session-id`, then `RecordMonitor`)
    and nothing ever reads its PipeWire buffers; start the *remote desktop* session, not
    the cast, or it answers `Must be started from remote desktop session`.
  - **Not XTEST.** `XTestFakeMotionEvent`/`XTestFakeButtonEvent` through Xwayland look
    like they work — presses even arrive at the right X11 window — but the compositor
    never sees them: the real cursor does not move, no window takes the focus, and no
    Wayland client notices. Anything that reacts to activation silently does nothing.
    Cost a couple of hours on 2026-09-18; use RemoteDesktop.
  - **Capture**: `org.gnome.Mutter.ScreenCast` + PipeWire (`gst-launch-1.0` and `pw-cli`
    are installed; `ydotool`/`wtype` are not, and `/dev/uinput` is root-only). The easy
    routes are both closed (checked 2026-09-18): `gnome-screenshot` is not installed, and
    `org.gnome.Shell.Screenshot.Screenshot` answers `AccessDenied: Screenshot is not
    allowed` — GNOME 46 only lets its own UI call it. ScreenCast is the only way in.
  - **Window geometry / owner**: nothing out of the box for Wayland windows —
    `org.gnome.Shell.Eval` returns `(false, '')` (unsafe mode off) and
    `org.gnome.Shell.Introspect.GetWindows` answers `AccessDenied`. What works instead:
    run the app under `GDK_BACKEND=x11` and read Xlib (`_NET_CLIENT_LIST`,
    `_NET_FRAME_EXTENTS`, `XTranslateCoordinates`) — that is what the harness does.
    A Wayland-native app can still be asserted from the inside (`uiprobe.py` for
    Flutter works unchanged), but not measured from the outside.
  - **A Wayland client has no root coordinates.** GTK fills `x_root`/`y_root` of an
    event with the *surface-local* point, so code that looks global can be silently
    surface-relative. To find a Wayland window from outside, move the pointer to a known
    screen point and have the app report the surface point under it — the difference is
    the window's origin. That is also the only way to check that a window moved.
  - **Focus arrives late.** The window manager moves the focus a few hundred
    milliseconds after the button goes down. An app that reacts to a press through a
    focus change (`WindowDragSession` tear-off) needs the button held still that long
    before the drag moves — `drag(..., hold_ms=700)` in the harness.
- The rootless Xwayland on `:0` is still there for X11 clients; its cookie is
  `/run/user/<uid>/.mutter-Xwaylandauth.XXXXXX` (new suffix per login — never hard-code
  it). Missing cookie → "Authorization required, but no authorization protocol specified".

### No display attached (checked 2026-09-24)

The NUC's monitor disappeared at ~23:35 and never came back. Everything that needs a
monitor then fails in a way that looks like a code bug, so check this **first**:

```sh
grep -H . /sys/class/drm/*/status        # both HDMI-A-* here: "disconnected"
gdbus call --session -d org.gnome.Mutter.DisplayConfig \
  -o /org/gnome/Mutter/DisplayConfig -m org.gnome.Mutter.DisplayConfig.GetCurrentState
#   → monitors [], logical monitors []   (serial keeps changing; renderer 'native')
```

- With no output there is **no ScreenCast source** (`RecordMonitor` has no connector, and
  `RecordVirtual` is not a substitute for a real one), **no `wl_output`** for a client to
  place a window on, and the `RemoteDesktop` reference stream cannot be created from a
  connector. `xinput.RemoteDesktop` therefore records the empty monitor list in
  `_monitors()` and falls back to a **virtual monitor** (`self.virtual = True`,
  `self.size = (1280, 720)`); absolute motion still works there, and Mutter paints no
  pointer into a virtual stream at all — cursor-mode 0 and 1 both leave the frames
  cursorless (measured: frames with the pointer at (300,300) vs (900,500) differ only in
  the top bar clock). GDK in that session logs
  `gdk_monitor_get_scale_factor: assertion 'GDK_IS_MONITOR (monitor)' failed`, the app's
  windows never appear in the stream, and the app itself warns
  `Timed out waiting for OpenGL frame of size 480x651 (have 480x680)`.
- Real input does not bring the output back: `NotifyPointerMotionRelative` plus button
  presses for 20 s left DisplayConfig empty. There is no passwordless sudo here, so
  `echo detect > /sys/class/drm/card1-HDMI-A-1/status` (the kernel's force-HPD-reprobe) is
  not available either.
- `gnome-shell --headless --wayland --virtual-monitor 1280x960 --wayland-display <name>`
  *does* give a real `wl_output` (`Added virtual monitor Meta-0`, `monitors [('Meta-0',
  1280, 960)]`, `logical [(0, 0, 1.0)]`) — the pattern `issue55-headless.sh` in the scratch
  dir uses, and it needs a private `XDG_RUNTIME_DIR` **and** `dbus-run-session` (two
  compositors cannot own `org.gnome.Mutter.ScreenCast` on one bus), with
  `PIPEWIRE_RUNTIME_DIR` left pointing at the user's PipeWire daemon. But clients do not
  come up in it: `Gdk.Display.get_default()` never returned (killed by a 90 s timeout with
  no output) and `RemoteDesktop.CreateSession`/`Start` hung for minutes, on an idle
  machine (load 0.01). A stale `--wayland-display issue55` shell was still running from
  that earlier session; kill your own leftovers by pid, not with `pkill -f`.
- A monitor that drops HPD is the usual cause: the kernel sees the cable go away, GDM
  keeps the session (loginctl says `active`, not locked), and nothing in software can
  bring it back. **The only fix is at the machine.** So: a truthful "the host has no
  display attached" is the right report, and the take has to wait.

## Other traps

- **Flutter's experimental multi-window does not run under Xwayland** (checked
  2026-09-18, Flutter 3.48.0-1.0.pre-805): the app dies as the second window appears with
  `BadAccess … request_code 149 (GLX) minor_code 26`, in every renderer configuration
  (Impeller, Skia, `LIBGL_ALWAYS_SOFTWARE`, `GDK_GL=egl|gles`, software rendering). A
  single-window Flutter app under `GDK_BACKEND=x11` is fine. Since the app can only be
  *measured* from outside under X11, multi-window Flutter examples currently cannot be
  GUI-tested here at all — only launched as Wayland clients and read through
  `uiprobe.py`.
- `remote.sh <host> desktop <script> <timeout>` passes no arguments through to the
  script: a test that takes options needs them baked in or read from the environment.
- On an X11 session ("Ubuntu on Xorg") GDM's cookie is `/run/user/<uid>/gdm/Xauthority`;
  `~/.Xauthority` usually does not exist. `xdotool` would be the input driver there.
- GTK needs `libgtk-3-dev` etc. for building core; Flutter needs `clang`, `ninja`,
  `pkg-config`.
