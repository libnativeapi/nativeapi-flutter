# Plays floating_toolbar_example while recording the screen (Windows): a second Flutter
# window - transparent, frameless, owned by the main one - that floats above the main
# window. The Windows twin of flutter_floating_toolbar_demo.py; same story: the pill
# drives the main window, follows it when it is dragged and resized, stays behind when
# detached, is hidden and shown again.
# Run from the Mac:
#   .agents/skills/record-demo/scripts/record_remote.sh <host> tools/gui/flutter_floating_toolbar_demo.ps1 tools/gui/output
#   -> tools/gui/output/flutter_floating_toolbar_demo-windows.mp4
# Set $env:DEMO_DRY_RUN=1 on the host (or $DryRun below) to play it without recording.
# The example is looked for in debug under $RemoteScratch\toolbar-flutter (a snapshot
# build), then in the host's checkout. No keyboard input, no audio. ASCII only.
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\env.ps1"; . "$PSScriptRoot\winput.ps1"; . "$PSScriptRoot\guiapp.ps1"; . "$PSScriptRoot\recorder.ps1"
$name = [IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
Start-Result "$RemoteScratch\$name.result.txt"
$DryRun = [bool]$env:DEMO_DRY_RUN

# Speed of the whole scenario: motions and pauses are scaled by it; pauses that let
# windows appear keep a floor.
$Pace = 0.5
function Scaled([int]$ms, [int]$min = 120) { [int][math]::Max($min, $ms * $Pace) }
function Beat([double]$s) { Pause ([math]::Max($s * $Pace, $(if ($s -ge 1) { 0.7 } else { 0.2 }))) }

$example = "floating_toolbar_example"
$dirs = @("$RemoteScratch\toolbar-flutter\examples\flutter_$example", "$RemoteWorkspace\examples\flutter_$example")
$dir = $dirs | ? { Test-Path (Get-FlutterExe $_) } | Select-Object -First 1
if (-not $dir) { throw "$example is not built in any of: $($dirs -join ', ')" }

function Main($app) { Get-Win $app "Floating toolbar" }
function Bar($app) { Get-Win $app "Toolbar" }

function Press($app, [string]$TitleLike, [string]$Text, [double]$Hold = 0.8) {
  $win = Get-Win $app $TitleLike
  $view = Find-View (Get-Views $app) $Text
  if (-not $win -or -not $view) { throw "cannot find '$Text' in '$TitleLike'" }
  Invoke-Click $app (ConvertTo-Screen $win (Get-TextCenter $view $Text)) (Scaled 450)
  Beat $Hold
}

# The colour circles carry no text: they sit left of the Stamp button, 38 logical px
# apart (28 wide, 5 of padding each side), 10 before the button, whose label starts
# 38 px in (12 padding, 18 icon, 8 gap).
function Swatch($app, [int]$Index, [double]$Hold = 0.9) {
  $view = Find-View (Get-Views $app) "Stamp"
  $rect = ($view.texts | ? { $_[0] -eq "Stamp" } | Select-Object -First 1)[1]
  $buttonLeft = $rect[0] - 38
  $cx = $buttonLeft - 10 - 38 * (4 - $Index) + 19
  Invoke-Click $app (ConvertTo-Screen (Bar $app) @($cx, ($rect[1] + $rect[3] / 2))) (Scaled 450)
  Beat $Hold
}

function DragPath($app, $start, [object[]]$legs) {
  $paced = @()
  foreach ($l in $legs) { $paced += ,@([int]$l[0], [int]$l[1], (Scaled $l[2] 150)) }
  Invoke-Drag $app $start $paced (Scaled 500)
}

# Drags the main window by its title bar along the offsets (dx, dy, ms).
function DragMain($app, [object[]]$offsets) {
  $m = Main $app
  $grab = @([int](($m.Left + $m.Right) / 2 - 60 * $m.Scale), ($m.Top + [int](16 * $m.Scale)))
  $legs = @()
  foreach ($o in $offsets) { $legs += ,@(($grab[0] + $o[0]), ($grab[1] + $o[1]), $o[2]) }
  DragPath $app $grab $legs
  Beat 1.0
}

# Resizes the main window from its bottom right corner by (dx, dy).
function ResizeMain($app, [int]$dx, [int]$dy) {
  $m = Main $app
  # The visible corner: the window rectangle also holds an invisible resize border.
  $corner = @(($m.ClientX + $m.ClientW + 2), ($m.ClientY + $m.ClientH + 2))
  $sx = [math]::Sign($dx); $sy = [math]::Sign($dy)
  DragPath $app $corner @(@(($corner[0] + 40 * $sx), ($corner[1] + 20 * $sy), 350), @(($corner[0] + $dx), ($corner[1] + $dy), 800))
  Beat 1.0
}

function Play {
  Get-Process $example -ErrorAction SilentlyContinue | Stop-Process -Force
  $app = Start-GuiApp (Get-FlutterExe $dir) -MinViews 2
  try {
    # A known starting point, with room above for the pill and around for the drags.
    [WInput]::SetBounds((Main $app).Hwnd, 520, 360, [int](736 * (Main $app).Scale), [int](600 * (Main $app).Scale))
    Pause 0.8
    [WInput]::Raise((Main $app).Hwnd); [WInput]::Raise((Bar $app).Hwnd)
    Beat 1.2

    # 1. The pill drives the main window: two windows, one isolate.
    foreach ($i in @(1, 2, 3, 0)) { Swatch $app $i }
    1..3 | % { Press $app "Toolbar" "Stamp" 0.5 }
    Beat 1.0

    # 2. The main window moves: the pill comes along.
    DragMain $app @(@(60, 30, 350), @(420, 200, 900))
    DragMain $app @(@(-60, -20, 350), @(-460, -120, 900))

    # 3. It is resized from its corner: the pill stays centred.
    ResizeMain $app 300 110
    ResizeMain $app -300 -110

    # 4. Detached it stays behind; attached it snaps back.
    Press $app "Floating toolbar" "Detach toolbar"
    DragMain $app @(@(60, 30, 350), @(360, 160, 800))
    Press $app "Floating toolbar" "Attach toolbar" 1.4

    # 5. Hidden, and not brought back by moving its parent; shown again.
    Press $app "Floating toolbar" "Hide toolbar"
    DragMain $app @(@(-60, -30, 350), @(-360, -160, 800))
    Press $app "Floating toolbar" "Show toolbar" 1.4

    # End on the proof: the counter and the log in the main window.
    Swatch $app 2
    Press $app "Toolbar" "Stamp" 0.5
    Beat 2.4
    $m = Main $app; $b = Bar $app
    Say ("proof: " + ((Get-ViewTexts (Get-Views $app) "^Stamps") -join " | ") + "; main $($m.Left),$($m.Top); toolbar $($b.Left),$($b.Top)")
  } finally { Stop-GuiApp $app | Out-Null }
}

try {
  Assert-Idle
  if (-not $DryRun) { Start-Recording "$RemoteScratch\$name-windows.mp4"; Say "recording" }
  try {
    Pause 1.0
    Play
    Pause 1.0
  } finally {
    if (-not $DryRun) { Say "saved $(Stop-Recording)" }
  }
} catch {
  Say "ERROR: $_"
}
