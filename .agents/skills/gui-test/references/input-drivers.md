# Input drivers

The harness (`guiapp.py` / `guiapp.ps1`) wraps these; use them directly for ad-hoc
poking, diagnostics, or apps the harness does not fit. The safety rules in `SKILL.md`
apply to every call.

| | macOS | Windows |
| --- | --- | --- |
| driver | `scripts/macos/input` (wrapper; compiles `input.m` on first use) | `scripts/windows/winput.ps1` (dot-source; `Add-Type` C#) |
| coordinates | screen **points**, top-left origin | **physical pixels** (the process is made per-monitor DPI aware) |
| needs | Accessibility permission for the terminal/app that runs it | to run in the logged-on desktop session (see `remote-hosts`) |

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
