# GUI test (Windows) of core's window_visual_effect_example (C++): the example puts a window
# over a plain red one and walks it through every VisualEffect; this looks at the screen
# after each step. An effect that blurs what is behind the window comes out reddish, no
# effect does not, and a background color given while an effect was active is what the
# window shows once the effect is removed. The Windows twin of
# core_window_visual_effect_test.py. Built on the gui-test skill. Build first (desktop session):
#   cmake -S $RemoteWorkspace\core -B $RemoteScratch\core-build -G "Visual Studio 17 2022" -A x64
#   cmake --build $RemoteScratch\core-build --config Debug --target window_visual_effect_example
# Run (remote-hosts skill):  remote.sh <host> setup; remote.sh <host> desktop tools/gui/core_window_visual_effect_test.ps1 120
# One click, on the example's title bar, to make it the active window: the system's
# backdrops (Acrylic, Mica) are only drawn for the active one. ASCII only.
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\env.ps1"; . "$PSScriptRoot\winput.ps1"; . "$PSScriptRoot\guiapp.ps1"
Start-Result "$RemoteScratch\core_window_visual_effect_test.result.txt"
Add-Type -AssemblyName System.Drawing

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

$exe = "$RemoteScratch\core-build\examples\window_visual_effect_example\Debug\window_visual_effect_example.exe"
if (-not (Test-Path $exe)) { throw "$exe is missing; build it first" }
$out = "$RemoteScratch\core_window_visual_effect_test.app.log"
Remove-Item $out -ErrorAction SilentlyContinue

Assert-Idle
$proc = Start-Process $exe -PassThru -WindowStyle Hidden -RedirectStandardOutput $out
$app = @{ Proc = $proc; Log = $null; Stdout = $null }
function Get-Steps { @(Get-Content $out -ErrorAction SilentlyContinue | ? { $_ -like "STEP *" }) }

$seen = @{}
try {
  # The example leaves its windows alone for six seconds after showing them.
  $deadline = (Get-Date).AddSeconds(15)
  while (-not (Get-Win $app "Visual effect") -and (Get-Date) -lt $deadline) { Pause 0.3 }
  $win = Get-Win $app "Visual effect"
  if (-not $win) { throw "the example's window did not appear" }
  Invoke-Activate $app $win
  Check "the example's window is the active one" ([WInput]::ForegroundPid() -eq $proc.Id)

  # What the window looks like after each "STEP <name> <outcome>" line. The example moves
  # on by itself, so a look that a later step overtook does not count.
  $deadline = (Get-Date).AddSeconds(70)
  while (-not $proc.HasExited -and (Get-Date) -lt $deadline) {
    $steps = @(Get-Steps)  # one line alone would come back as a string
    if ($steps.Count -eq 0) { Pause 0.1; continue }
    $name = $steps[-1].Split(" ")[1]
    if ($seen.ContainsKey($name)) { Pause 0.1; continue }
    Pause 1.0
    $win = Get-Win $app "Visual effect"
    $color = Get-ScreenColor ($win.ClientX + [int]($win.ClientW / 2)) ($win.ClientY + [int]($win.ClientH / 2))
    $current = @(Get-Steps)[-1].Split(" ")[1]
    $seen[$name] = @{ Outcome = $steps[-1].Split(" ")[2]; Color = $(if ($current -eq $name) { $color } else { $null }) }
  }

  function Get-Look([string]$Name) {
    if (-not $seen.ContainsKey($Name) -or -not $seen[$Name].Color) { throw "step $Name was not looked at in time" }
    return $seen[$Name].Color
  }
  $plain = Get-Look "None"
  Check "without an effect the window hides what is behind it" ((Get-Redness $plain) -lt 30) "$plain"
  # Blur is on every Windows; what the others need is in Window::SetVisualEffect()'s notes.
  # A refused effect leaves the last one in force, which the example itself checks.
  foreach ($name in @("Blur", "Acrylic", "Hud", "Popover", "Menu")) {
    $look = Get-Look $name
    if ($seen[$name].Outcome -eq "applied") {
      Check "$name shows the red window behind" ((Get-Redness $look) -gt 15) "$look"
    } else {
      Check "$name may only be refused where the system lacks it" ($name -ne "Blur") $seen[$name].Outcome
    }
  }
  foreach ($name in @("Mica", "MicaAlt")) {
    Say "INFO $name $($seen[$name].Outcome): $(Get-Look $name)"
  }
  $look = Get-Look "Background"
  Check "a background color set meanwhile does not replace the effect" ($look[2] -lt 200 -or $look[0] -gt 60) "$look"
  $look = Get-Look "Removed"
  Check "removing the effect shows that background color" ($look[2] -gt 200 -and $look[0] -lt 60 -and $look[1] -lt 60) "$look"

  $proc.WaitForExit(10000) | Out-Null
  # Not the exit code: Start-Process does not keep it for a process it did not wait on.
  $verdict = @(Get-Content $out | ? { $_ -eq "ALL PASS" -or $_ -eq "FAILED" })
  Check "the example's own expectations hold" ($verdict.Count -eq 1 -and $verdict[0] -eq "ALL PASS") "$verdict"
} catch {
  Check "ran to the end" $false "$_"
} finally {
  Stop-Process -Id $proc.Id -ErrorAction SilentlyContinue
}
Get-Content $out -ErrorAction SilentlyContinue | % { Say "app: $_" }
Say "$script:Failures failure(s)"
exit $script:Failures
