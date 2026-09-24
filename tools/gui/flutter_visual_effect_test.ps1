# GUI test (Windows) of visual_effect_example: a Flutter window really shows the material
# set with Window.setVisualEffect. Started with VISUAL_EFFECT_AUTOPLAY=1 the example puts a
# plain red window behind itself and walks through the effects on its own; this looks at the
# screen after each step. An effect that blurs what is behind the window comes out reddish
# where Flutter paints nothing, and with the effect removed the Flutter view is as opaque as
# it was before. The Windows twin of flutter_visual_effect_test.py. Built on the gui-test
# skill. Build first (desktop session): flutter build windows --debug in the example.
# Run (remote-hosts skill):  remote.sh <host> setup; remote.sh <host> desktop tools/gui/flutter_visual_effect_test.ps1 150
# One click, on the example's title bar, to make it the active window: the system's
# backdrops (Acrylic, Mica) are only drawn for the active one. ASCII only.
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\env.ps1"; . "$PSScriptRoot\winput.ps1"; . "$PSScriptRoot\guiapp.ps1"
Start-Result "$RemoteScratch\flutter_visual_effect_test.result.txt"
Add-Type -AssemblyName System.Drawing

$name = "visual_effect_example"
$dirs = @("$RemoteScratch\ve-flutter\examples\flutter_$name", "$RemoteWorkspace\examples\flutter_$name")
$dir = $dirs | ? { Test-Path (Get-FlutterExe $_) } | Select-Object -First 1
if (-not $dir) { throw "$name is not built in any of: $($dirs -join ', ')" }

# (r, g, b) of the screen around a point, averaged over 4 x 4 pixels.
function Get-ScreenColor([int]$X, [int]$Y) {
  $bmp = New-Object System.Drawing.Bitmap 4, 4
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen($X, $Y, 0, 0, $bmp.Size)
  $g.Dispose()
  $sum = @(0, 0, 0)
  foreach ($i in 0..3) { foreach ($j in 0..3) {
    $p = $bmp.GetPixel($i, $j); $sum[0] += $p.R; $sum[1] += $p.G; $sum[2] += $p.B
  } }
  $bmp.Dispose()
  return @([int]($sum[0] / 16), [int]($sum[1] / 16), [int]($sum[2] / 16))
}
function Get-Redness($c) { $c[0] - [math]::Max($c[1], $c[2]) }

Assert-Idle
$env:VISUAL_EFFECT_AUTOPLAY = "1"
$app = Start-GuiApp (Get-FlutterExe $dir)
function Get-Steps { @(Get-Content $app.Log -Encoding UTF8 -ErrorAction SilentlyContinue | ? { $_ -like "*STEP *" } | % { $_.Substring($_.IndexOf("STEP ") + 5) }) }

$seen = @{}
try {
  $win = Get-Win $app "Visual effect"
  if (-not $win) { throw "the example's window did not appear" }
  Invoke-Activate $app $win
  Check "the example's window is the active one" ([WInput]::ForegroundPid() -eq $app.Proc.Id)

  # The screen where the example paints nothing (right of the chips, above the note) after
  # each "STEP <name> <outcome>" line. The example moves on by itself, so a look that a
  # later step overtook does not count.
  $deadline = (Get-Date).AddSeconds(60)
  while (-not $app.Proc.HasExited -and (Get-Date) -lt $deadline -and -not $seen.ContainsKey("none")) {
    $steps = @(Get-Steps)  # one line alone would come back as a string
    if ($steps.Count -eq 0) { Pause 0.1; continue }
    $step = $steps[-1].Split(" ")[0]
    if ($seen.ContainsKey($step)) { Pause 0.1; continue }
    Pause 1.2
    $win = Get-Win $app "Visual effect"
    $color = Get-ScreenColor ($win.ClientX + [int]($win.ClientW * 0.8)) ($win.ClientY + [int]($win.ClientH * 0.72))
    $beside = Get-ScreenColor ($win.Left - [int](40 * $win.Scale)) ($win.ClientY + [int]($win.ClientH * 0.72))
    $current = @(Get-Steps)[-1].Split(" ")[0]
    $seen[$step] = @{ Outcome = $steps[-1].Split(" ")[1]; Color = $(if ($current -eq $step) { $color } else { $null }); Beside = $beside }
  }

  function Get-Look([string]$Step) {
    if (-not $seen.ContainsKey($Step) -or -not $seen[$Step].Color) { throw "step $Step was not looked at in time" }
    return $seen[$Step].Color
  }
  $plain = Get-Look "backdrop"
  Check "the backdrop is red around the example" ((Get-Redness $seen["backdrop"].Beside) -gt 150) "$($seen["backdrop"].Beside)"
  Check "without an effect the Flutter view hides what is behind it" ((Get-Redness $plain) -lt 30) "$plain"
  # blur is on every Windows; what the others need is in Window::SetVisualEffect()'s notes.
  foreach ($step in @("blur", "acrylic", "hud", "popover", "menu")) {
    $look = Get-Look $step
    if ($seen[$step].Outcome -eq "applied") {
      Check "$step shows the red window through the Flutter view" ((Get-Redness $look) -gt 15) "$look"
    } else {
      Check "$step may only be refused where the system lacks it" ($step -ne "blur") $seen[$step].Outcome
    }
  }
  foreach ($step in @("mica", "micaAlt")) {
    Say "INFO $step $($seen[$step].Outcome): $(Get-Look $step)"
  }
  $look = Get-Look "none"
  Check "the effect can be removed" ($seen["none"].Outcome -eq "applied") $seen["none"].Outcome
  $drift = (0..2 | % { [math]::Abs($look[$_] - $plain[$_]) } | Measure-Object -Maximum).Maximum
  Check "and the Flutter view has the backing it had before" ($drift -le 8) "$plain -> $look"
} catch {
  Check "ran to the end" $false "$_"
} finally {
  Stop-GuiApp $app | Out-Null
  $env:VISUAL_EFFECT_AUTOPLAY = $null
}
Say "$script:Failures failure(s)"
exit $script:Failures
