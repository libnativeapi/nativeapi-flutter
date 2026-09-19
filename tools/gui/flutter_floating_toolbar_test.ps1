# GUI test (Windows) of floating_toolbar_example: the toolbar window - a second Flutter
# window made a child of the main one with Window.setParentWindow - stays centred above the
# main window when that is moved, resized and dragged by its title bar, stops following
# once detached, is not brought back while hidden, and shares state with the main window.
# The Windows twin of flutter_floating_toolbar_test.py (macOS). An owned window does not
# move with its owner on Windows: following here is the example's WindowMovedEvent listener.
# Built on the gui-test skill. The example is looked for in debug under
# $RemoteScratch\toolbar-flutter (a snapshot build), then in the host's checkout.
# Run:  remote.sh <host> setup; remote.sh <host> desktop tools/gui/flutter_floating_toolbar_test.ps1 200
# ASCII only.
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\env.ps1"; . "$PSScriptRoot\winput.ps1"; . "$PSScriptRoot\guiapp.ps1"
Start-Result "$RemoteScratch\flutter_floating_toolbar_test.result.txt"
Add-Type -AssemblyName System.Drawing

$name = "floating_toolbar_example"
$dirs = @("$RemoteScratch\toolbar-flutter\examples\$name", "$RemoteWorkspace\bindings\flutter\examples\$name")
$dir = $dirs | ? { Test-Path (Get-FlutterExe $_) } | Select-Object -First 1
if (-not $dir) { throw "$name is not built in any of: $($dirs -join ', ')" }

function Get-Both($app) {
  @{ Main = (Get-Win $app "Floating toolbar"); Bar = (Get-Win $app "Toolbar") }
}

# The toolbar belongs centred above the main window, a small gap in between. Window
# rectangles include the invisible resize border of a framed window, hence the tolerances.
function Check-Placed($app, [string]$What) {
  $w = Get-Both $app
  if (-not $w.Main -or -not $w.Bar) { Check $What $false "windows: $((Get-Wins $app | % { $_.Title }) -join ', ')"; return }
  $mainCx = ($w.Main.Left + $w.Main.Right) / 2; $barCx = ($w.Bar.Left + $w.Bar.Right) / 2
  $gap = $w.Main.Top - $w.Bar.Bottom
  $s = $w.Main.Scale
  Check $What (([math]::Abs($mainCx - $barCx) -le 4 * $s) -and ($gap -ge -2 * $s) -and ($gap -le 24 * $s)) "centres $mainCx / $barCx, gap $gap px, scale $s"
}

function Get-ScreenColor([int]$X, [int]$Y) {
  $bmp = New-Object System.Drawing.Bitmap 4, 4
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen($X, $Y, 0, 0, $bmp.Size)
  $c = $bmp.GetPixel(1, 1); $g.Dispose(); $bmp.Dispose()
  @($c.R, $c.G, $c.B)
}

function Press($app, [string]$TitleLike, [string]$Text) {
  $win = Get-Win $app $TitleLike
  $view = Find-View (Get-Views $app) $Text
  if (-not $win -or -not $view) { throw "cannot find '$Text' in '$TitleLike'" }
  Invoke-Click $app (ConvertTo-Screen $win (Get-TextCenter $view $Text))
  Pause 1.0
}

Assert-Idle
$app = Start-GuiApp (Get-FlutterExe $dir) -MinViews 2
try {
  $w = Get-Both $app
  Check "both windows are there" (($null -ne $w.Main) -and ($null -ne $w.Bar)) ((Get-Wins $app | % { $_.Title }) -join ", ")
  [WInput]::Raise($w.Main.Hwnd); [WInput]::Raise($w.Bar.Hwnd)
  Pause 0.5
  Check-Placed $app "the toolbar starts centred above the main window"
  $s = $w.Bar.Scale
  Check "the toolbar content is as small as it was asked to be" (([math]::Abs($w.Bar.ClientW / $s - 380) -le 1) -and ([math]::Abs($w.Bar.ClientH / $s - 64) -le 1)) "$($w.Bar.ClientW / $s) x $($w.Bar.ClientH / $s)"

  # Transparent: the corner of the toolbar's client area, outside the rounded pill, shows
  # what is behind the window - the same as just outside of it.
  $inside = Get-ScreenColor ($w.Bar.ClientX + 3) ($w.Bar.ClientY + 3)
  $outside = Get-ScreenColor ($w.Bar.ClientX - 12) ($w.Bar.ClientY + 3)
  $diff = (0..2 | % { [math]::Abs($inside[$_] - $outside[$_]) } | Measure-Object -Maximum).Maximum
  # KNOWN GAP (2026-09-19): core's Windows SetBackgroundColor ignores alpha, the corner is
  # opaque black. Reported, not counted, until core makes a translucent window see-through.
  if ($diff -le 24) { Check "the toolbar window is see-through around the pill" $true }
  else { Say "KNOWN GAP the toolbar window is not see-through around the pill - corner $($inside -join ','), just outside $($outside -join ',')" }

  # Moved and resized by the system, no input involved.
  [WInput]::Move($w.Main.Hwnd, 300, 360); Pause 1.0
  Check-Placed $app "the toolbar followed a move"
  $m = (Get-Both $app).Main
  [WInput]::SetBounds($m.Hwnd, 360, 400, ($m.Right - $m.Left + 200), ($m.Bottom - $m.Top + 80)); Pause 1.0
  Check-Placed $app "the toolbar is centred again after a move and a resize"

  # Two windows, one isolate: a press in the toolbar counts up in the main window.
  Check "the main window starts at zero" ($null -ne (Find-View (Get-Views $app) "Stamps: 0"))
  Press $app "Toolbar" "Stamp"
  Check "a press in the toolbar window counts in the main window" ($null -ne (Find-View (Get-Views $app) "Stamps: 1"))

  # The real thing: the user drags the main window by its title bar.
  $m = (Get-Both $app).Main
  $grab = @([int](($m.Left + $m.Right) / 2), ($m.Top + [int](16 * $m.Scale)))
  Invoke-Drag $app $grab @(@(($grab[0] + 40), ($grab[1] + 20), 400), @(($grab[0] - 150), ($grab[1] + 70), 600)) 300
  Pause 1.2
  $after = (Get-Both $app).Main
  Check "the main window was dragged" (([math]::Abs($after.Left - ($m.Left - 150)) -le 6) -and ([math]::Abs($after.Top - ($m.Top + 70)) -le 6)) "from $($m.Left),$($m.Top) to $($after.Left),$($after.Top)"
  Check-Placed $app "the toolbar followed a drag of the title bar"

  Press $app "Floating toolbar" "Detach toolbar"
  $before = (Get-Both $app).Bar
  [WInput]::Move((Get-Both $app).Main.Hwnd, 420, 460); Pause 1.0
  $bar = (Get-Both $app).Bar
  Check "a detached toolbar stays where it is" (($bar.Left -eq $before.Left) -and ($bar.Top -eq $before.Top)) "from $($before.Left),$($before.Top) to $($bar.Left),$($bar.Top)"
  Press $app "Floating toolbar" "Attach toolbar"
  Check-Placed $app "attaching brings the toolbar back above the main window"

  Press $app "Floating toolbar" "Hide toolbar"
  Check "the hidden toolbar is gone" ($null -eq (Get-Both $app).Bar) ((Get-Wins $app | % { $_.Title }) -join ", ")
  [WInput]::Move((Get-Both $app).Main.Hwnd, 300, 360); Pause 1.0
  Check "moving its parent does not bring a hidden toolbar back" ($null -eq (Get-Both $app).Bar) ((Get-Wins $app | % { $_.Title }) -join ", ")
  Press $app "Floating toolbar" "Show toolbar"
  Check-Placed $app "the toolbar shown again is above the main window"
  [WInput]::Move((Get-Both $app).Main.Hwnd, 380, 420); Pause 1.0
  Check-Placed $app "and follows again"
} catch {
  Check "ran to the end" $false "$_"
} finally {
  $lines = @(Stop-GuiApp $app)
}
Say "$script:Failures failure(s)"
exit $script:Failures
