# Linux hosts

**Status: designed, not yet run against a real Linux host.** `desktop.sh` was exercised
locally only (log capture, timeout, exit code). Verify each step the first time and
update this file with what you learn — the Windows notes were all learned the hard way.

## Two places a script can run

**SSH session (`exec`, `run`)**: a plain login shell. No `DISPLAY`, so GUI programs
fail with "cannot open display". Fine for git, builds (`cmake`, `flutter build linux`),
logs.

**Logged-on desktop (`desktop`)**: `scripts/posix/desktop.sh` runs the script with the
environment of the user's graphical session: `DISPLAY` (`HOST_DISPLAY`, default `:0`),
`XAUTHORITY` (`~/.Xauthority` if present), `XDG_RUNTIME_DIR`, and the session D-Bus
address. The same user must be logged on at the console.

Scripts start with:

```bash
. "$(dirname "$0")/env.sh"      # REMOTE_WORKSPACE, REMOTE_SCRATCH, PYTHON, PATH additions
```

## Expected traps

- **Wayland**: an SSH-launched process cannot join a Wayland session by setting
  `DISPLAY`, global cursor position is unavailable to clients, and synthetic input
  needs a portal. Log the test user into an **X11 session** ("GNOME on Xorg"); core's
  `WindowDragSession` is X11-only for the same reason.
- Display managers keep `XAUTHORITY` elsewhere (GDM: `/run/user/<uid>/gdm/Xauthority`).
  If `desktop` says "Authorization required", find it with
  `ps e -u $USER | tr ' ' '\n' | grep ^XAUTHORITY= | sort -u` and export it in the script.
- There is no Linux input driver in `gui-test` yet. `xdotool` (X11) is the natural
  base for one with the same vocabulary (`windows`, `owner`, `move`, `click`, `drag`,
  `scroll`, `idle`); `uiprobe.py` works unchanged.
- GTK needs `libgtk-3-dev` etc. for building core; Flutter needs `clang`, `ninja`,
  `pkg-config`.
