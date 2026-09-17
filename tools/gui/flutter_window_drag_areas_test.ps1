# GUI test (Windows) of window_drag_areas_example: DragToMoveArea moves the window and toggles
# maximization on a double click; DragToResizeArea resizes from all eight handles, keeps the
# other edges anchored, respects the minimum size and the enabled-edge list, and lets the
# pointer through in the middle. Built on the gui-test skill; takes over the mouse for ~90 s.
# Run (remote-hosts skill):  remote.sh <host> setup; remote.sh <host> desktop tools/gui/flutter_window_drag_areas_test.ps1 200
# ASCII only.
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\env.ps1"; . "$PSScriptRoot\winput.ps1"; . "$PSScriptRoot\guiapp.ps1"
Start-Result "$RemoteScratch\flutter_window_drag_areas_test.result.txt"

$Bar = "Drag here to move"
# kResizeEdgeInset + kResizeEdgeSize / 2 of the example: the middle of a handle band, in
# logical px from the window edge.
$Band = 16 + 12 / 2
$MinWidth = 480  # window.minimumSize of the example
# The pan starts a few pixels after the press, so a window follows the mouse by slightly
# less than the gesture is long (logical px).
$Slop = 8

# name, where (fractions of the view), mouse travel (logical px), frame edges that follow the
# mouse. Edges travel outwards with an off-axis component that must be ignored; corners travel
# back inwards, so the window ends as big as it started.
$Handles = @(
  @("left", 0, 0.5, -60, 25, "l"), @("right", 1, 0.5, 60, -25, "r"),
  @("top", 0.5, 0, 25, -40, "t"), @("bottom", 0.5, 1, -25, 40, "b"),
  @("topLeft", 0, 0, 30, 20, "lt"), @("topRight", 1, 0, -30, 20, "rt"),
  @("bottomLeft", 0, 1, 30, -20, "lb"), @("bottomRight", 1, 1, -30, -20, "rb"))

# The window and its view as they are now; never reuse them across a gesture.
function Look($app) {
  $win = Get-Win $app "*Drag areas"
  if (-not $win) { throw "the example's window is gone" }
  @{ Win = $win; View = Find-View (Get-Views $app) $Bar
     Edges = @{ l = $win.Left; t = $win.Top; r = $win.Right; b = $win.Bottom } }
}
function Get-HandlePoint($look, [double]$fx, [double]$fy) {
  $w = $look.View.size[0]; $h = $look.View.size[1]
  ConvertTo-Screen $look.Win @(($Band + $fx * ($w - 2 * $Band)), ($Band + $fy * ($h - 2 * $Band)))
}
# Two legs: a short one past the drag threshold, then the rest. Travel is in logical px.
function Invoke-DragBy($app, $look, $start, [double]$dx, [double]$dy) {
  $s = $look.Win.Scale
  Invoke-Drag $app $start @(@(($start[0] + $dx * $s / 4), ($start[1] + $dy * $s / 4), 350), @(($start[0] + $dx * $s), ($start[1] + $dy * $s), 700))
  Pause 1.2
}
function Check-Near([string]$what, [double]$actual, [double]$expected, [double]$tolerance) {
  Check $what ([math]::Abs($actual - $expected) -le $tolerance) "got $actual, expected $expected +-$tolerance"
}
function Check-SameFrame([string]$what, $before, $after) {
  $moved = @("l", "t", "r", "b" | ? { $after.Edges[$_] -ne $before.Edges[$_] } | % { "$_ $($before.Edges[$_]) -> $($after.Edges[$_])" })
  Check $what ($moved.Count -eq 0) ($moved -join ", ")
}
# The "Size: W x H" text follows the client area (logical px).
function Check-ShowsSize([string]$what, $look) {
  $text = @(Get-ViewTexts @($look.View) "^Size: ") | Select-Object -First 1
  $ok = $text -match "^Size: (\d+) x (\d+)$" -and
    ([math]::Abs([int]$Matches[1] - $look.Win.ClientW / $look.Win.Scale) -le 1) -and
    ([math]::Abs([int]$Matches[2] - $look.Win.ClientH / $look.Win.Scale) -le 1)
  Check $what $ok "'$text', client $($look.Win.ClientW)x$($look.Win.ClientH) at scale $($look.Win.Scale)"
}

Assert-Idle
$app = Start-GuiApp (Get-FlutterExe "$RemoteWorkspace\bindings\flutter\examples\window_drag_areas_example") -MinViews 1
try {
  $now = Look $app
  Invoke-Activate $app $now.Win -ClientY 110  # no title bar: an empty strip below the move area
  $now = Look $app
  $s = $now.Win.Scale
  Check-Near "content width is 720" ($now.Win.ClientW / $s) 720 1
  Check-Near "content height is 480" ($now.Win.ClientH / $s) 480 1

  # 1. The middle of the resize area lets the pointer through to the child.
  $plus = ConvertTo-Screen $now.Win (Get-TextCenter $now.View "+1")
  1..2 | % { Invoke-Click $app $plus 350; Pause 0.4 }
  $clicks = @(Get-ViewTexts (Get-Views $app) "^Clicks")
  Check "clicks reach the child through the resize area" ($clicks -contains "Clicks: 2") ($clicks -join " | ")

  # 2. Every handle resizes its own edge(s) and nothing else.
  foreach ($h in $Handles) {
    $name = $h[0]; $travel = @{ l = $h[3]; r = $h[3]; t = $h[4]; b = $h[4] }
    $before = Look $app
    Invoke-DragBy $app $before (Get-HandlePoint $before $h[1] $h[2]) $h[3] $h[4]
    $after = Look $app
    foreach ($e in "l", "t", "r", "b") {
      if ($h[5].Contains($e)) {
        Check-Near "${name}: $e edge follows the mouse" $after.Edges[$e] ($before.Edges[$e] + $travel[$e] * $s) ($Slop * $s)
      } else {  # not an inch, whatever the mouse did off-axis
        Check-Near "${name}: $e edge stays put" $after.Edges[$e] $before.Edges[$e] 1
      }
    }
    Check-ShowsSize "${name}: Flutter relaid out at the new size" $after
  }

  # 3. The minimum size stops the resize, and the anchored edge still does not move.
  $before = Look $app
  $width = ($before.Win.Right - $before.Win.Left) / $s
  Invoke-DragBy $app $before (Get-HandlePoint $before 1 0.5) (-($width - $MinWidth + 150)) 0
  $after = Look $app
  Check-Near "right: stops at the minimum width" (($after.Win.Right - $after.Win.Left) / $s) $MinWidth 2
  Check-Near "right: left edge anchored at the minimum" $after.Edges.l $before.Edges.l 1
  $before = $after
  Invoke-DragBy $app $before (Get-HandlePoint $before 1 0.5) 240 0
  $after = Look $app
  Check-Near "right: grows back from the minimum" $after.Edges.r ($before.Edges.r + 240 * $s) ($Slop * $s)

  # 4. enableResizeEdges: a disabled handle is gone, an enabled one still works.
  Invoke-Click $app (ConvertTo-Screen $after.Win (Get-TextCenter $after.View "Edges: all")) 400
  Pause 0.6
  $before = Look $app
  Check "edge list switched" (Test-ViewText $before.View "Edges: right and bottom")
  Invoke-DragBy $app $before (Get-HandlePoint $before 0 0.5) (-60) 0
  $after = Look $app
  Check-SameFrame "left (disabled): nothing happens" $before $after
  $before = $after
  Invoke-DragBy $app $before (Get-HandlePoint $before 1 1) 40 30
  $after = Look $app
  Check-Near "bottomRight (still enabled): r edge" $after.Edges.r ($before.Edges.r + 40 * $s) ($Slop * $s)
  Check-Near "bottomRight (still enabled): b edge" $after.Edges.b ($before.Edges.b + 30 * $s) ($Slop * $s)
  Check-Near "bottomRight (still enabled): l edge stays put" $after.Edges.l $before.Edges.l 1
  Check-Near "bottomRight (still enabled): t edge stays put" $after.Edges.t $before.Edges.t 1

  # 5. DragToMoveArea: the window follows the mouse, its size untouched.
  $before = Look $app
  $start = ConvertTo-Screen $before.Win (Get-TextCenter $before.View $Bar)
  Invoke-DragBy $app $before $start 120 (-80)
  $after = Look $app
  Check-Near "move: follows the mouse horizontally" $after.Edges.l ($before.Edges.l + 120 * $s) ($Slop * $s)
  Check-Near "move: follows the mouse vertically" $after.Edges.t ($before.Edges.t - 80 * $s) ($Slop * $s)
  Check "move: size unchanged" ((($after.Edges.r - $after.Edges.l) -eq ($before.Edges.r - $before.Edges.l)) -and (($after.Edges.b - $after.Edges.t) -eq ($before.Edges.b - $before.Edges.t)))
  $grabbed = ConvertTo-Screen $after.Win (Get-TextCenter $after.View $Bar)
  Check-Near "move: the grabbed point is still under the cursor (x)" $grabbed[0] ($start[0] + 120 * $s) ($Slop * $s)
  Check-Near "move: the grabbed point is still under the cursor (y)" $grabbed[1] ($start[1] - 80 * $s) ($Slop * $s)

  # 6. A plain click must not start a drag: move away afterwards without a button. (A pan
  # recognizer can fire onPanStart after the button is up; a move loop entered then would
  # glue the window to the cursor.)
  $before = Look $app
  $point = ConvertTo-Screen $before.Win (Get-TextCenter $before.View $Bar)
  Invoke-Click $app $point
  Pause 0.8  # past the double-tap window, so the next test starts from scratch
  Move-Cursor @(($point[0] + 140 * $s), ($point[1] + 90 * $s)) 600
  Pause 0.8
  $after = Look $app
  Check-SameFrame "click: window does not move or stick to the cursor" $before $after
  if ((@("l", "t", "r", "b") | ? { $after.Edges[$_] -ne $before.Edges[$_] }).Count -gt 0) {
    # Let go of a stuck move loop before going on: a click inside the window ends it.
    Invoke-Click $app (ConvertTo-Screen $after.Win (Get-TextCenter $after.View "Clicks: 2"))
    Pause 0.8
  }

  # 7. A double click maximizes; another one restores the frame it had.
  $before = Look $app
  Invoke-DoubleClick $app (ConvertTo-Screen $before.Win (Get-TextCenter $before.View $Bar))
  Pause 1.5
  $zoomed = Look $app
  Check "double click: maximized" ((($zoomed.Edges.r - $zoomed.Edges.l) -gt ($before.Edges.r - $before.Edges.l)) -and (($zoomed.Edges.b - $zoomed.Edges.t) -gt ($before.Edges.b - $before.Edges.t))) "$($before.Win.Left),$($before.Win.Top),$($before.Win.Right),$($before.Win.Bottom) -> $($zoomed.Win.Left),$($zoomed.Win.Top),$($zoomed.Win.Right),$($zoomed.Win.Bottom)"
  Check-ShowsSize "double click: Flutter relaid out at the new size" $zoomed
  Invoke-DoubleClick $app (ConvertTo-Screen $zoomed.Win (Get-TextCenter $zoomed.View $Bar))
  Pause 1.5
  $after = Look $app
  Check-SameFrame "double click again: restored" $before $after

  $clicks = @(Get-ViewTexts (Get-Views $app) "^Clicks")
  Check "state untouched by all of it" ($clicks -contains "Clicks: 2") ($clicks -join " | ")
} catch {
  Check "ran to the end" $false "$_"
} finally {
  Stop-GuiApp $app | Out-Null
}
Say "$script:Failures failure(s)"
exit $script:Failures
