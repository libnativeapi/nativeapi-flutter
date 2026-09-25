# GUI test (Windows) of core's view_example (C++): a sign-in form of native controls
# (Label, TextField, Button) laid out by a Column and a Row. Checks the layout the example
# prints, clicks the real buttons and asserts on the status lines, then resizes the window
# and checks the re-flow. The Windows counterpart of core_view_test.py.
# Build first (desktop session):
#   cmake -S $RemoteWorkspace\core -B $RemoteScratch\core-build -G "Visual Studio 17 2022" -A x64
#   cmake --build $RemoteScratch\core-build --config Debug --target view_example
# Run (remote-hosts skill):  remote.sh <host> setup; remote.sh <host> desktop tools/gui/core_view_test.ps1 120
# $env:VIEW_EXAMPLE overrides the executable. No keyboard input. ASCII only.
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\env.ps1"; . "$PSScriptRoot\winput.ps1"; . "$PSScriptRoot\guiapp.ps1"
Start-Result "$RemoteScratch\core_view_test.result.txt"

# The harness only hands back a console app's output when it exits; this test reads the
# layout lines while the app runs, so it collects them itself.
Add-Type -TypeDefinition @"
using System.Collections.Concurrent;
using System.Diagnostics;
public static class ViewTestSink {
  public static ConcurrentQueue<string> Lines = new ConcurrentQueue<string>();
  public static void Attach(Process p) {
    p.OutputDataReceived += (s, e) => { if (e.Data != null) Lines.Enqueue(e.Data); };
    p.BeginOutputReadLine();
  }
}
"@

$Content = @(360, 220); $Padding = 16; $Spacing = 8

function Get-Lines { @([ViewTestSink]::Lines.ToArray()) }

# {label -> @(x, y, w, h)} from the LAST "[view] layout" block (logical points, root-relative).
function Get-Layout {
  $out = @{}
  foreach ($l in Get-Lines) {
    if ($l -match '^\[view\] layout (\w+) (\S+) (\S+) (\S+) (\S+)') {
      if ($Matches[1] -eq "root") { $out = @{} }
      $out[$Matches[1]] = @([double]$Matches[2], [double]$Matches[3], [double]$Matches[4], [double]$Matches[5])
    }
  }
  $out
}

# Callers wrap it in @(): PowerShell unrolls a one-element array into a plain string.
function Get-Statuses { @(Get-Lines | ? { $_ -like "``[view``] status: *" } | % { $_.Substring(15) }) }

function Near([string]$What, [double]$Actual, [double]$Expected, [double]$Tolerance = 2) {
  Check $What ([math]::Abs($Actual - $Expected) -le $Tolerance) "$Actual vs $Expected"
}

# Screen centre (physical) of a control, from its root-relative logical frame. The scale
# comes from the client area against the root's logical width, not from the window's DPI:
# the example has no DPI manifest, so Windows reports 96 dpi and stretches the window.
function Get-ControlCenter($Win, $Layout, [string]$Name) {
  $f = $Layout[$Name]
  $scale = $Win.ClientW / $Layout["root"][2]
  @([int]($Win.ClientX + ($f[0] + $f[2] / 2) * $scale), [int]($Win.ClientY + ($f[1] + $f[3] / 2) * $scale))
}

# Clicks a control after lifting the window over whatever else is on the desktop.
function Invoke-ControlClick($App, [string]$Name, $Layout) {
  $w = Get-Win $App "Sign in"
  if (-not $w) { throw "the 'Sign in' window is gone" }
  if (-not $Layout.ContainsKey($Name) -or -not $Layout.ContainsKey("root")) { throw "no layout for $Name" }
  [WInput]::Raise($w.Hwnd)
  Pause 0.3
  $point = Get-ControlCenter $w $Layout $Name
  Say "click $Name at $($point -join ',') (client $($w.ClientX),$($w.ClientY) $($w.ClientW)x$($w.ClientH))"
  Invoke-Click $App $point
}

Assert-Idle
$exe = if ($env:VIEW_EXAMPLE) { $env:VIEW_EXAMPLE } else { "$RemoteScratch\core-build\examples\view_example\Debug\view_example.exe" }
if (-not (Test-Path $exe)) { throw "$exe is missing; build it first" }
$psi = New-Object System.Diagnostics.ProcessStartInfo $exe
$psi.UseShellExecute = $false; $psi.CreateNoWindow = $true; $psi.RedirectStandardOutput = $true
$proc = [System.Diagnostics.Process]::Start($psi)
[ViewTestSink]::Attach($proc)
$app = @{ Proc = $proc; Log = $null; Stdout = $null }
Pause 3
try {
  $win = Get-Win $app "Sign in"
  if (-not $win) { throw "no 'Sign in' window: $((Get-Wins $app | % { $_.Title }) -join ', ')" }
  [WInput]::Move($win.Hwnd, 120, 120)
  Pause 0.5
  # Settle: nudge the width and back, so the example prints the layout again once the
  # window has laid itself out. With WinUI 3 the first print comes before the XAML
  # island has loaded its controls, when they still measure 0 wide.
  $win = Get-Win $app "Sign in"
  $ww = $win.Right - $win.Left; $wh = $win.Bottom - $win.Top
  [WInput]::SetBounds($win.Hwnd, $win.Left, $win.Top, $ww + 1, $wh)
  Pause 0.5
  [WInput]::SetBounds($win.Hwnd, $win.Left, $win.Top, $ww, $wh)
  Pause 0.8
  $win = Get-Win $app "Sign in"
  # Activate by clicking the root's top padding: the default spot on the caption assumes
  # the reported 96 dpi, but the stretched window's caption buttons are 1.5x wider there
  # and that click would land on Minimize.
  Invoke-Activate $app $win 4

  $layout = Get-Layout
  $names = @("root", "heading", "name", "password", "status", "actions", "clear", "sign_in")
  Check "layout printed for every control" (@($names | ? { -not $layout.ContainsKey($_) }).Count -eq 0) (($layout.Keys | Sort-Object) -join ", ")
  Near "root is the content area (w)" $layout["root"][2] $Content[0]
  Near "root is the content area (h)" $layout["root"][3] $Content[1]
  Near "client area has the root's aspect" ($win.ClientH / $win.ClientW) ($Content[1] / $Content[0]) 0.01
  Near "heading starts at the padding" $layout["heading"][1] $Padding
  Near "heading spans the padded width" $layout["heading"][2] ($Content[0] - 2 * $Padding)
  $h = $layout["heading"]; $n = $layout["name"]
  Near "name follows the heading" $n[1] ($h[1] + $h[3] + $Spacing)
  Near "password follows name" $layout["password"][1] ($n[1] + $n[3] + $Spacing)
  Check "a text field has a height" ($n[3] -gt 10) "$($n[3])"
  Near "actions row is 32 high (preferred size)" $layout["actions"][3] 32
  $s = $layout["sign_in"]; $c = $layout["clear"]
  Near "sign in hugs the trailing edge" ($s[0] + $s[2]) ($Content[0] - $Padding)
  Near "clear sits before sign in, spaced" ($c[0] + $c[2] + $Spacing) $s[0]
  Check "buttons have an intrinsic width" (($s[2] -gt 40) -and ($s[2] -lt 140)) "$($s[2])"

  # Act: "Sign in" with an empty username is refused and focuses the username field.
  Invoke-ControlClick $app "sign_in" $layout
  Pause 1.0
  $st = @(Get-Statuses)
  Check "empty sign-in is refused" ($st.Count -gt 0 -and $st[-1] -eq "A username is required.") ($st -join " | ")
  Check "the refused sign-in focused the username field" (@(Get-Lines | ? { $_ -eq "[view] focused: name" }).Count -gt 0)

  # "Clear" resets the status.
  Invoke-ControlClick $app "clear" (Get-Layout)
  Pause 1.0
  $st = @(Get-Statuses)
  Check "clear resets the status" ($st.Count -gt 0 -and $st[-1] -eq "Enter your credentials.") ($st -join " | ")

  # Resize: the Column and the Row re-flow to the new width.
  $win = Get-Win $app "Sign in"
  $px = $win.ClientW / $Content[0]
  $w = $win.Right - $win.Left; $hh = $win.Bottom - $win.Top
  [WInput]::SetBounds($win.Hwnd, $win.Left, $win.Top, $w + [int](120 * $px), $hh + [int](60 * $px))
  Pause 1.0
  $after = Get-Layout
  Near "root grew with the window (w)" $after["root"][2] ($Content[0] + 120)
  Near "root grew with the window (h)" $after["root"][3] ($Content[1] + 60)
  Near "heading re-stretched" $after["heading"][2] ($Content[0] + 120 - 2 * $Padding)
  $s2 = $after["sign_in"]
  Near "sign in followed the trailing edge" ($s2[0] + $s2[2]) ($Content[0] + 120 - $Padding)
  Near "button width unchanged by the resize" $s2[2] $s[2]

  # Look again: the button is still where the layout says after the re-flow.
  Invoke-ControlClick $app "sign_in" $after
  Pause 1.0
  $st = @(Get-Statuses)
  Check "sign in still answers after the re-flow" ($st.Count -ge 3 -and $st[-1] -eq "A username is required.") ($st -join " | ")
} catch {
  Check "ran to the end" $false "$_"
} finally {
  Stop-Process -Id $proc.Id -ErrorAction SilentlyContinue
  Pause 1
}
Get-Lines | ? { $_ -notlike "``[view``] layout *" } | % { Say "app: $_" }
Say "$script:Failures failure(s)"
exit $script:Failures
