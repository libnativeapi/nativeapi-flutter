# Linux hosts

**Status: `setup`, `exec` and `desktop` verified on Ubuntu 24.04 (GNOME) on 2026-09-17;
no build or GUI test has run there yet.** Verify each further step the first time and
update this file with what you learn — the Windows notes were all learned the hard way.

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
    `ScreenCast` stream attached to the session. This is the natural base for a
    `gui-test` Linux driver with the usual vocabulary (`move`, `click`, `drag`,
    `scroll`, `idle`).
  - **Capture**: `org.gnome.Mutter.ScreenCast` + PipeWire (`gst-launch-1.0` and `pw-cli`
    are installed; `ydotool`/`wtype` are not, and `/dev/uinput` is root-only).
  - **Window geometry / owner**: nothing out of the box — `org.gnome.Shell.Eval` returns
    `(false, '')` (unsafe mode off). Needs a small GNOME Shell extension exposing
    `global.get_window_actors()` over D-Bus, or asserting from inside the app
    (`uiprobe.py` for Flutter works unchanged).
- The rootless Xwayland on `:0` is still there for X11 clients; its cookie is
  `/run/user/<uid>/.mutter-Xwaylandauth.XXXXXX` (new suffix per login — never hard-code
  it). Missing cookie → "Authorization required, but no authorization protocol specified".

## Other traps

- On an X11 session ("Ubuntu on Xorg") GDM's cookie is `/run/user/<uid>/gdm/Xauthority`;
  `~/.Xauthority` usually does not exist. `xdotool` would be the input driver there.
- GTK needs `libgtk-3-dev` etc. for building core; Flutter needs `clang`, `ninja`,
  `pkg-config`.
