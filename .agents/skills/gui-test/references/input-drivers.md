# Input drivers

The harness (`guiapp.py` / `guiapp.ps1`) wraps these; use them directly for ad-hoc
poking, diagnostics, or apps the harness does not fit. The safety rules in `SKILL.md`
apply to every call.

| | macOS | Windows | Linux (GNOME) |
| --- | --- | --- | --- |
| driver | `scripts/macos/input` (wrapper; compiles `input.m` on first use) | `scripts/windows/winput.ps1` (dot-source; `Add-Type` C#) | `scripts/linux/xinput.py` (`X11` to look, `RemoteDesktop` to act; ctypes + D-Bus, no build) |
| coordinates | screen **points**, top-left origin | **physical pixels** (the process is made per-monitor DPI aware) | screen **pixels**, top-left origin |
| needs | Accessibility permission for the terminal/app that runs it | to run in the logged-on desktop session (see `remote-hosts`) | to run in the logged-on desktop session; GNOME grants the remote desktop session without a prompt |

## macOS

```bash
I=scripts/macos/input
$I windows <pid>            # title<TAB>x y w h   (AX; frame includes the title bar)
$I owner <x> <y> [menus]    # pid of the frontmost layer-0 window at the point (0 = none);
                            #   menus: pop-up menu windows count too
$I menus <pid>              # the app's open menus: a line per menu window (flag M) and per item:
                            #   depth<TAB>title<TAB>x y w h<TAB>flags (e enabled, s submenu, - separator)<TAB>mark
$I setframe <pid> <x> <y> <w> <h>   # move and resize the app's first window
$I visible <x> <y>          # visible frame (no menu bar, no Dock) of the screen at the point
$I activate <pid> [soft]    # bring the app and its windows forward (AX-assisted); soft: only make it active
$I raise <pid>              # raise its windows without activating (not above the active app's windows)
$I front                    # pid of the frontmost app
$I pos                      # cursor position
$I idle [ms]                # exit 1 if the cursor moved during ms (default 1500)
$I move <x> <y> <ms>        # eased move
$I click <x> <y>
$I rclick <x> <y>           # secondary button
$I dblclick <x> <y>         # click state 1 then 2, as a real double click
$I drag <x> <y> [<x> <y> <ms>]…   # press at the first point, glide through each leg, release
$I scroll <x> <y> <lines>
```

- Events are posted at `kCGHIDEventTap`, so the app sees a real drag, including the
  system's own title-bar window dragging.
- Without Accessibility permission the calls succeed silently and nothing moves;
  `windows` returns nothing. Grant it to the terminal (or the Claude app) in System
  Settings › Privacy & Security › Accessibility and restart it.
- Open context menus are not among the application's AX children; `menus` finds the
  app's windows on the pop-up menu level and hit-tests inside them. Menu windows sit
  above layer 0, so a plain `owner` looks through them — use `owner … menus` (the
  harness's `click_menu_item` does) before pressing on a menu.
- A freshly launched app is not frontmost; `activate` it, or the first click only
  raises the window.

## Windows

```powershell
. "$PSScriptRoot\winput.ps1"
Assert-Idle
$w = Get-AppWindows $proc.Id      # Hwnd, Title, Left/Top/Right/Bottom, ClientX/Y/W/H, Scale
Assert-Owner $proc.Id $x $y
[WInput]::Glide($x, $y, 600)      # eased move
[WInput]::Click($x, $y)
[WInput]::DoubleClick($x, $y)
[WInput]::RightClick($x, $y)
[WInput]::Drag([int[]]@($x0, $y0,  $x1, $y1, 400,  $x2, $y2, 900))   # x0,y0 then x,y,ms legs
[WInput]::Wheel(3)                # at the current cursor position; positive scrolls down
[WInput]::Move($hwnd, $x, $y)     # reposition a window without input
[WInput]::SetBounds($hwnd, $x, $y, $w, $h)
[WInput]::ClassOf($hwnd)          # window class name
[WInput]::Raise($hwnd)            # top of the z-order without activating
Click-Desktop $x $y               # click the wallpaper, to blur the app
```

- `ClientX/Y` is the client area's screen origin; multiply Flutter logical
  coordinates by `Scale` (dpi / 96).
- `SetCursorPos` alone does not generate mouse-move messages; the driver follows each
  step with a zero relative `SendInput` move so the app (and drag sessions polling
  `GetAsyncKeyState`) see a real gesture. Keep that if you extend it.
- **A background-launched process cannot take the foreground.** Click an uncovered
  part of its own window (title bar) to activate it; `Raise` only fixes z-order.
- **Something may cover your window.** Other apps' always-on-top or centred windows
  (a download manager parked mid-screen, a maximized Git client), and full-screen
  click-through overlays (NVIDIA GeForce Overlay: layered + transparent). When
  `Assert-Owner` fails or a click does nothing, run
  `scripts/windows/desktop_survey.ps1 -X <x> -Y <y>` to see the stack at that point,
  then move the app's windows to a free area with `[WInput]::Move` or ask the user to
  close the offender — do not click other apps away yourself.
- `Find-DesktopPoint` returns a spot where the bare desktop shows, or `$null` when a
  maximized window covers everything — then a scenario that needs to blur the app
  should be skipped and reported, not forced.
- Console programs (C++ examples) open a console window that covers the screen when
  started from a hidden script. Start them with `ProcessStartInfo.CreateNoWindow = $true`
  and `RedirectStandardOutput` instead of `Start-Process`.
- Open menus: `Get-OpenMenus` (guiapp.ps1) reads them through UI Automation — Win32
  popup menus are `#32768` windows, WinUI 3 flyouts `PopupWindowSiteBridge` windows —
  one per level, a submenu included. Both belong to the app's process, so `Assert-Owner`
  holds on them.
- Keep `.ps1` files ASCII: Windows PowerShell 5.1 reads BOM-less files in the system
  codepage.

## Linux (GNOME on Wayland)

```python
import sys; sys.path.insert(0, 'scripts/linux')
from xinput import X11, RemoteDesktop, BTN_LEFT, idle_ms

x = X11()                          # looking, through Xlib
x.screen_size()                    # (width, height)
x.windows(pid=None, stacking=False)  # managed X11 toplevels: xid, pid, title, frame, content
x.window_at(x, y)                  # top-most X11 window covering the point, or None
x.active_window()                  # _NET_ACTIVE_WINDOW
x.cardinals(xid, '_NET_WM_STATE')  # any 32-bit property, e.g. to test _NET_WM_STATE_FOCUSED
x.pointer()                        # (x, y, button mask) as the X server has it
x.activate(xid)                    # _NET_ACTIVE_WINDOW request (the compositor may ignore it)

rd = RemoteDesktop()               # acting, through org.gnome.Mutter.RemoteDesktop
rd.motion(x, y)                    # absolute, in screen pixels
rd.button(BTN_LEFT, True)          # BTN_LEFT/RIGHT/MIDDLE are evdev codes (0x110…)
rd.wheel(steps)                    # discrete wheel steps, positive scrolls down
rd.stop()                          # end the session (the harness does it in quit())

idle_ms()                          # ms since the last real user input (GNOME idle monitor)
```

- **Use RemoteDesktop, not XTEST.** `XTestFakeMotionEvent`/`XTestFakeButtonEvent`
  through Xwayland reach X11 clients — presses land on the right window — but the
  compositor never sees them: the real cursor stays put, no window takes the focus, and
  Wayland clients notice nothing.
- Creating the session is `RemoteDesktop.CreateSession`, then
  `ScreenCast.CreateSession` with `remote-desktop-session-id` and `RecordMonitor` (whose
  stream absolute motion is addressed to) — nothing reads its PipeWire buffers unless you ask
  for them: the session exposes `stream`, `node` and `size`, so a `record-demo` recorder can
  read the same stream instead of opening a second one. Then `Start` on the *remote desktop*
  session; starting the cast itself answers `Must be started from remote desktop session`.
- **No monitor attached** (`/sys/class/drm/*/status` all `disconnected`, DisplayConfig reports
  no monitors): `_connector()` has nothing to return, so the session records a Mutter
  **virtual monitor** instead and sets `virtual = True`, `size = (1280, 720)`. Absolute motion
  still works, but Mutter paints no pointer into a virtual stream (cursor-mode 0 and 1 both
  leave frames cursorless) and it is not a `wl_output`, so a real client cannot place a window
  on it. See `remote-hosts/references/linux.md`.
- **Only X11 windows can be seen**, so the app under test runs with `GDK_BACKEND=x11`.
  Frames include the window manager's decorations (`_NET_FRAME_EXTENTS`), contents come
  from `XTranslateCoordinates`.
- `x.pointer()` is only current while the pointer is over an X surface — which makes it
  the test for "is the point I am about to press really on that window, with nothing
  Wayland-native on top".
- There is no equivalent of `Click-Desktop`: to blur, click a window of your own
  (`GuiApp.blur()` parks one in a corner for that).
