# Demo video of shaped_window_example on Windows: a Flutter window whose native contour
# is a polygon, so the desktop shows through around the silhouette. The story is the two
# things the feature is about: click every one of the twelve gallery cards once
# (left to right, top to bottom), then walk the five contour-shadow presets
# (None, Soft, Float, Sharp, Glow). It ends on the last silhouette with its shadow.
#
# Run from the Mac (records, encodes on the host, copies the MP4 back):
#   .agents/skills/record-demo/scripts/record_remote.sh win tools/gui/flutter_window_shape_demo.ps1 tools/gui/output
#   -> tools/gui/output/flutter_window_shape_demo-windows.mp4
#
# Cheap iteration without recording: pass -DryRun, or set $env:DEMO_DRY_RUN=1 on the host
# (the `desktop` verb cannot pass switches). -KeepOpen / $env:DEMO_KEEP_OPEN leaves the
# example running for debugging. One $Pace factor scales every motion and pause.
# No keyboard input, no audio. ASCII only.
param([switch]$DryRun, [switch]$KeepOpen)
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\env.ps1"; . "$PSScriptRoot\winput.ps1"; . "$PSScriptRoot\guiapp.ps1"; . "$PSScriptRoot\recorder.ps1"
$name = [IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
Start-Result "$RemoteScratch\$name.result.txt"
$Dry = [bool]($DryRun -or [bool]$env:DEMO_DRY_RUN)
$Keep = [bool]($KeepOpen -or [bool]$env:DEMO_KEEP_OPEN)

# Speed of the whole take: motions and pauses are scaled by it; pauses that let something
# appear keep a floor. 0.5 gives 300 ms approaches and 0.7-1.1 s holds.
$Pace = 0.5
function Scaled([int]$ms, [int]$min = 120) { [int][math]::Max($min, $ms * $Pace) }
function Beat([double]$s) { Pause ([math]::Max($s * $Pace, $(if ($s -ge 1) { 0.7 } else { 0.2 }))) }

$example = "shaped_window_example"
$shapes = @('circle', 'star', 'bubble', 'heart', 'flower', 'hexagon',
            'squircle', 'blob', 'burst', 'droplet', 'diamond', 'shield')
$presets = @('None', 'Soft', 'Float', 'Sharp', 'Glow')
$dirs = @("$RemoteWorkspace\examples\flutter_$example")
$dir = $dirs | ? { Test-Path (Get-FlutterExe $_) } | Select-Object -First 1
if (-not $dir) { throw "$example is not built in any of: $($dirs -join ', ')" }

function ControlWin($app) { Get-Win $app 'Window shapes' }
function PreviewWin($app) { Get-Win $app 'Shape preview' }
# The 480x680 control window is the only view that shows this heading; the preview view
# carries the drag handle and the big shape name instead.
function ControlView($app) { Find-View (Get-Views $app) 'SHAPE PLAYGROUND' }

# The square view whose big label is the shape name: the shaped preview.
function PreviewView($views, [string]$Shape) {
  $views | ? { (Test-ViewText $_ $Shape) -and $_.size -and ([math]::Abs($_.size[0] - $_.size[1]) -lt 1) } |
    Select-Object -First 1
}

# A preset name is on screen twice: as the SHADOW header readout (above) and on the chip
# (below). The chip is the lower of the two, and it is the one that reacts to a click.
function ChipCenter($View, [string]$Text) {
  $hits = @($View.texts | ? { $_[0] -eq $Text } | Sort-Object { $_[1][1] })
  if (-not $hits) { throw "'$Text' not found in the control view" }
  $r = $hits[-1][1]
  @(($r[0] + $r[2] / 2), ($r[1] + $r[3] / 2))
}

# The readout in the SHADOW header row is the topmost preset-name text in the view.
function ShadowReadout($View) {
  $names = @('None', 'Soft', 'Float', 'Sharp', 'Glow', 'Custom')
  $hits = @($View.texts | ? { $names -contains $_[0] } | Sort-Object { $_[1][1] })
  if (-not $hits) { return $null }
  $hits[0][0]
}

function ClickCard($app, [string]$Text) {
  $w = ControlWin $app; $v = ControlView $app
  if (-not $w -or -not $v) { throw "the control window or view is gone before '$Text'" }
  Invoke-Click $app (ConvertTo-Screen $w (Get-TextCenter $v $Text)) (Scaled 600)
  Beat 1.4
}

function ClickChip($app, [string]$Text) {
  $w = ControlWin $app; $v = ControlView $app
  if (-not $w -or -not $v) { throw "the control window or view is gone before '$Text'" }
  Invoke-Click $app (ConvertTo-Screen $w (ChipCenter $v $Text)) (Scaled 600)
  Beat 1.8
}

# Both windows fully on screen and clear of each other, with room around the preview for
# the contour shadow (blur and offset are logical px, so they grow with the DPI scale).
# The example's own sizes are right, so this only moves them.
function Arrange($app) {
  $screen = [WInput]::Screen()
  $m = ControlWin $app
  if (-not $m) { throw 'the control window is missing' }
  [WInput]::Move($m.Hwnd, [int]($screen[0] * 0.19), [int]($screen[1] * 0.12))
  Pause 0.4
  $m = ControlWin $app
  $p = PreviewWin $app
  if (-not $p) { throw 'the preview window is missing' }
  $x = [math]::Min($m.Right + 120, $screen[0] - ($p.Right - $p.Left) - 40)
  [WInput]::Move($p.Hwnd, [int]$x, [int]($screen[1] * 0.23))
  Pause 0.4
  $m = ControlWin $app; $p = PreviewWin $app
  [WInput]::Raise($p.Hwnd)
  [WInput]::Raise($m.Hwnd)
  Pause 0.6
  $m = ControlWin $app; $p = PreviewWin $app
  Say ("screen {0}x{1}; control {2},{3} - {4},{5} client {6}x{7} scale {8}; preview {9},{10} - {11},{12} client {13}x{14}" -f `
    $screen[0], $screen[1], $m.Left, $m.Top, $m.Right, $m.Bottom, $m.ClientW, $m.ClientH, $m.Scale, `
    $p.Left, $p.Top, $p.Right, $p.Bottom, $p.ClientW, $p.ClientH)
  Check 'the preview is clear of the control window' ($m.Right -le $p.Left) `
    "control right $($m.Right), preview left $($p.Left)"
  Check 'the preview keeps room for its shadow' (($p.Right + 70) -le $screen[0]) `
    "preview right $($p.Right), screen $($screen[0])"
}

function Play($app) {
  # 1. Every silhouette in the gallery, left to right and top to bottom: the polygon the
  # native clip follows morphs over 450 ms and both the preview label and the status line
  # follow it.
  $seen = 0
  foreach ($shape in $shapes) {
    ClickCard $app $shape
    $views = Get-Views $app
    $pv = PreviewView $views $shape
    $status = @(Get-ViewTexts $views 'native shape active|Flutter clip') | Select-Object -First 1
    Check "card '$shape' renders in the shaped preview" ($null -ne $pv) "status '$status'"
    $seen++
  }
  Say "gallery: $seen of $($shapes.Count) cards clicked, in order"

  # 2. None, Soft, Float, Sharp, Glow: the contour shadow follows the same polygon,
  # outside the shape, without taking clicks.
  $done = @()
  foreach ($preset in $presets) {
    ClickChip $app $preset
    $tv = ControlView $app
    $readout = ShadowReadout $tv
    if ($done.Count -eq 0) {
      Say ("preset texts in the control view: " + ((@($tv.texts | ? { $presets -contains $_[0] } |
        % { "$($_[0])@y$([int]$_[1][1])" })) -join ', '))
    }
    Check "chip '$preset' selected in the SHADOW row" ($readout -eq $preset) "readout '$readout'"
    $done += $preset
  }
  Say "shadow: $($done.Count) of $($presets.Count) presets clicked, in order"

  # Hold the final frame: shield + Glow, with the proof in the log.
  Beat 2.6
  $views = Get-Views $app
  $pv = PreviewView $views 'shield'
  $counter = @(Get-ViewTexts $views '^Tap') | Select-Object -First 1
  Say "proof: final shape '$(if ($pv) { 'shield' } else { 'NOT SHIELD' })', final preset '$((ShadowReadout (ControlView $app)))', preview counter '$counter'"
  foreach ($line in @(Get-Content $app.Log -ErrorAction SilentlyContinue |
      ? { $_ -and $_.Contains('[shape]') } | Select-Object -Last 3)) {
    Say "  app: $line"
  }
}

try {
  Assert-Idle
  Get-Process $example -ErrorAction SilentlyContinue | Stop-Process -Force
  # The launch and the arrangement are not part of the story, so the recorder starts after
  # both: no dead desktop at the head of the take.
  $app = Start-GuiApp (Get-FlutterExe $dir)
  try {
    # The service announces its URL before the main isolate and its views exist, so a
    # probe can fail while the app is still coming up: poll, do not trust one look.
    $deadline = (Get-Date).AddSeconds(60)
    do {
      try { $ready = @(Get-Views $app 2>$null).Count -ge 2 } catch { $ready = $false }
      if (-not $ready) { Pause 0.5 }
    } until ($ready -or (Get-Date) -gt $deadline)
    if (-not $ready) { throw 'Flutter did not expose two views within 60 seconds' }
    Arrange $app
    Pause 1.0
    if (-not $Dry) { Start-Recording "$RemoteScratch\$name-windows.mp4"; Say "recording" }
    try {
      Play $app
    } finally {
      if (-not $Dry) { Say "saved $(Stop-Recording)" }
    }
  } finally {
    if ($app) {
      if ($Keep) { Say "left running: pid $($app.Proc.Id), log $($app.Log)" }
      else { Stop-GuiApp $app | Out-Null; Say "app log: $($app.Log)" }
    }
  }
} catch {
  Say "ERROR: $_"
}
Say "Failures: $script:Failures"
if ($Dry) { Say "dry run: nothing was recorded" }
exit $script:Failures
