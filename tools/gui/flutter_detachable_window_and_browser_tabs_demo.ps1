# Plays the detachable window and browser tabs examples while recording the screen (Windows).
# Run from the Mac:
#   .agents/skills/record-demo/scripts/record_remote.sh <host> tools/gui/flutter_detachable_window_and_browser_tabs_demo.ps1 tools/gui/output
#   -> tools/gui/output/flutter_detachable_window_and_browser_tabs_demo-windows.mp4
# The MP4 is encoded on the Windows host as $RemoteScratch\<this script's name>-windows.mp4.
# No keyboard input, no audio. ASCII only.
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\env.ps1"; . "$PSScriptRoot\winput.ps1"; . "$PSScriptRoot\guiapp.ps1"; . "$PSScriptRoot\recorder.ps1"
$name = [IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
Start-Result "$RemoteScratch\$name.result.txt"

# Short names for the scenario scripts below.
function Probe($app) { Get-Views $app }
function Has($view, $text) { Test-ViewText $view $text }
function Center($view, $text, [switch]$Strip) { if ($Strip) { Get-TextCenter $view $text -MaxY 40 } else { Get-TextCenter $view $text } }
function ToScreen($win, $pt) { ConvertTo-Screen $win $pt }
function Launch($name) { Start-GuiApp (Get-FlutterExe "$RemoteWorkspace\bindings\flutter\examples\$name") -MinViews 2 }
function Wins($app) { Get-Wins $app }
function Glide($pt, [int]$ms = 600) { Move-Cursor $pt $ms }
function Click($app, $pt, [int]$ms = 450) { Invoke-Click $app $pt $ms }
function DragPath($app, $start, [object[]]$legs) { Invoke-Drag $app $start $legs }
function Quit($app) { Stop-GuiApp $app | Out-Null }

function Detachable {
  $app = Launch "detachable_window_example"
  try {
    $views = Probe $app
    $va = $views | ? { Has $_ "Window A" }; $vb = $views | ? { Has $_ "Window B" }
    $wins = Wins $app
    $wa = $wins | ? { $_.Title -like "*Window A" }; $wb = $wins | ? { $_.Title -like "*Window B" }
    # Bring both windows to the front.
    foreach ($w in @($wa, $wb)) { Invoke-Activate $app $w }
    Pause 0.8

    # Some state worth keeping.
    $plus = ToScreen $wa (Center $va "+1")
    1..3 | % { Click $app $plus 350; Pause 0.25 }
    $layer = ToScreen $wa (Center $va "Layer 1")
    Invoke-Wheel $app $layer 3
    Pause 0.5
    $lap = ToScreen $wa (Center $va "Lap")
    1..2 | % { Click $app $lap 400; Pause 0.5 }
    Pause 0.8

    # Tear the Inspector off and drop it over the workspace.
    $s = ToScreen $wa (Center $va "Inspector")
    DragPath $app $s @(@(($s[0] + 60), ($s[1] + 40), 350), @(($wa.ClientX + 470 * $wa.Scale), ($wa.ClientY + 160 * $wa.Scale), 900))
    Pause 1.2

    # Dock it into Window B's wide sidebar.
    $views = Probe $app
    $vb = $views | ? { Has $_ "Window B" }
    $vf = $views | ? { -not (Has $_ "Window A") -and -not (Has $_ "Window B") } | Select-Object -First 1
    $wi = Wins $app | ? { $_.Title -eq "Inspector" }
    $s = ToScreen $wi (Center $vf "Inspector")
    $t = ToScreen $wb (Center $vb "Wide sidebar")
    DragPath $app $s @(@(($s[0] + 250), ($s[1] + 60), 700), @($t[0], $t[1], 900))
    Pause 1.5

    # Stopwatch: Window A's bottom panel to Window B's top strip.
    $views = Probe $app
    $va = $views | ? { Has $_ "Window A" }; $vb = $views | ? { Has $_ "Window B" }
    $s = ToScreen $wa (Center $va "Stopwatch")
    $t = ToScreen $wb (Center $vb "Top strip")
    DragPath $app $s @(@(($s[0] + 40), ($s[1] - 80), 400), @($t[0], $t[1], 1100))
    Pause 1.5

    # And back, swapping places.
    $views = Probe $app
    $va = $views | ? { Has $_ "Window A" }; $vb = $views | ? { Has $_ "Window B" }
    $s = ToScreen $wb (Center $vb "Inspector")
    $t = ToScreen $wa (Center $va "Bottom panel")
    DragPath $app $s @(@(($s[0] - 120), ($s[1] + 60), 500), @($t[0], $t[1], 1100))
    Pause 1.3
    $views = Probe $app
    $va = $views | ? { Has $_ "Window A" }; $vb = $views | ? { Has $_ "Window B" }
    $s = ToScreen $wb (Center $vb "Stopwatch")
    $t = ToScreen $wa (Center $va "Sidebar")
    DragPath $app $s @(@(($s[0] - 200), ($s[1] + 120), 500), @($t[0], $t[1], 1100))
    Pause 2

    $views = Probe $app
    $va = $views | ? { Has $_ "Window A" }
    Glide (ToScreen $wa (Center $va "Inspector")) 700
    Pause 2.5
    Say ("detachable done: " + (($views | % { $_.texts | % { $_[0] } | ? { $_ -match "^(State #|Clicks|Inspector:|Stopwatch:)" } }) -join " | "))
  } finally { Quit $app }
}

function Tabs {
  $app = Launch "browser_tabs_example"
  try {
    $views = Probe $app
    $v1 = $views | ? { Has $_ "Tab 4" }; $v2 = $views | ? { Has $_ "Tab 5" }
    $wins = Wins $app | Sort-Object ClientY
    $known = @{}; $known[$v1.name] = $wins[0].Hwnd; $known[$v2.name] = $wins[1].Hwnd
    function W($view) { Wins $app | ? { $_.Hwnd -eq $known[$view.name] } }
    function Refresh {
      $vs = Probe $app
      foreach ($v in $vs) {
        if (-not $known.ContainsKey($v.name)) {
          $new = Wins $app | ? { $known.Values -notcontains $_.Hwnd } | Select-Object -First 1
          if ($new) { $known[$v.name] = $new.Hwnd }
        }
      }
      return $vs
    }
    function V($vs, $old) { $vs | ? { $_.name -eq $old.name } }
    # Bring both to the front by clicking the strip background (top 6 px).
    foreach ($w in @((W $v2), (W $v1))) { Invoke-Activate $app $w -ClientY 3 }
    Pause 0.8

    # Tab 4 gets some state.
    Click $app (ToScreen (W $v1) (Center $v1 "Tab 4" -Strip))
    Pause 0.6
    $vs = Refresh; $v1 = V $vs $v1
    $like = $null
    foreach ($t in $v1.texts) { if ($t[0] -like "Like*") { $r = $t[1]; $like = @(($r[0] + $r[2] / 2), ($r[1] + $r[3] / 2)) } }
    $like = ToScreen (W $v1) $like
    1..3 | % { Click $app $like 350; Pause 0.25 }
    Pause 0.8

    # Reorder Tab 1 past its neighbours.
    $s = ToScreen (W $v1) (Center $v1 "Tab 1" -Strip)
    DragPath $app $s @(,@(($s[0] + 330 * (W $v1).Scale), ($s[1] + 2), 1400))
    Pause 1

    # Tear Tab 4 off.
    $vs = Refresh; $v1 = V $vs $v1
    $w1 = W $v1
    $s = ToScreen $w1 (Center $v1 "Tab 4" -Strip)
    DragPath $app $s @(@(($s[0] - 40), ($s[1] + 120 * $w1.Scale), 500), @(($s[0] - 160 * $w1.Scale), ($s[1] + 330 * $w1.Scale), 800))
    Pause 1.4

    # Merge it into the other window, between its tabs.
    $vs = Refresh; $v2 = V $vs $v2
    $vt = $vs | ? { $_.name -ne $v1.name -and $_.name -ne $v2.name } | Select-Object -First 1
    $s = ToScreen (W $vt) (Center $vt "Tab 4" -Strip)
    $w2 = W $v2
    $t5 = ToScreen $w2 (Center $v2 "Tab 5" -Strip)
    DragPath $app $s @(@(($s[0] + 200), ($s[1] - 150), 700), @(($t5[0] + 60 * $w2.Scale), $t5[1], 900), @(($t5[0] + 150 * $w2.Scale), $t5[1], 700))
    Pause 1.4

    # Tab 6 straight from that window into the first one.
    $vs = Refresh; $v1 = V $vs $v1; $v2 = V $vs $v2
    $w1 = W $v1; $w2 = W $v2
    $s = ToScreen $w2 (Center $v2 "Tab 6" -Strip)
    $t1 = ToScreen $w1 (Center $v1 "Tab 2" -Strip)
    DragPath $app $s @(@($s[0], ($s[1] + 180 * $w2.Scale), 600), @(($t1[0] + 80), ($t1[1] + 60 * $w1.Scale), 1000), @(($t1[0] + 40), $t1[1], 500))
    Pause 1.4

    # Move a window by the empty part of its strip.
    $w2 = W $v2
    $g = @(($w2.ClientX + $w2.ClientW - [int](60 * $w2.Scale)), ($w2.ClientY + [int](3 * $w2.Scale)))
    DragPath $app $g @(,@(($g[0] - 60), ($g[1] + 50), 800))
    Pause 1

    # Tab 4 kept its likes.
    $vs = Refresh; $v2 = V $vs $v2
    Click $app (ToScreen (W $v2) (Center $v2 "Tab 4" -Strip))
    Pause 2.5
    Say ("tabs done: " + (($vs | % { $_.texts | % { $_[0] } | ? { $_ -match "^(Page state|Like)" } }) -join " | "))
  } finally { Quit $app }
}

try {
  Assert-Idle
  Start-Recording "$RemoteScratch\$name-windows.mp4"
  Say "recording"
  try {
    Pause 1.5
    Detachable
    Pause 1
    Tabs
    Pause 1
  } finally {
    Say "saved $(Stop-Recording)"
  }
} catch {
  Say "ERROR: $_"
}
