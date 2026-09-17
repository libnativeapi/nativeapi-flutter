# GUI test (Windows) of core's window_drag_session_example (C++): dock the panel by dragging
# it onto the dock window, tear it off again, check it lands anchored under the cursor.
# Built on the gui-test skill. Build first (desktop session):
#   cmake -S $RemoteWorkspace\core -B $RemoteScratch\core-build -G "Visual Studio 17 2022" -A x64
#   cmake --build $RemoteScratch\core-build --config Debug --target window_drag_session_example
# Run (remote-hosts skill):  remote.sh <host> setup; remote.sh <host> desktop tools/gui/core_window_drag_session_test.ps1 120
# ASCII only.
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\env.ps1"; . "$PSScriptRoot\winput.ps1"; . "$PSScriptRoot\guiapp.ps1"
Start-Result "$RemoteScratch\core_window_drag_session_test.result.txt"

Assert-Idle
$app = Start-ConsoleApp "$RemoteScratch\core-build\examples\window_drag_session_example\Debug\window_drag_session_example.exe"
$lines = @()
try {
  # Park both windows where nothing else is, and lift them above other programs.
  foreach ($w in Get-Wins $app) {
    if ($w.Title -like "Dock*") { [WInput]::Move($w.Hwnd, 40, 480) }
    if ($w.Title -like "Panel*") { [WInput]::Move($w.Hwnd, 40, 60) }
    [WInput]::Raise($w.Hwnd)
  }
  Pause 0.5
  $dock = Get-Win $app "Dock*"; $panel = Get-Win $app "Panel*"
  if (-not $dock -or -not $panel) { throw "windows not found" }

  # The example treats a focus change as the press: focus the dock first.
  $d = @(($dock.ClientX + [int]($dock.ClientW / 2)), ($dock.ClientY + [int]($dock.ClientH / 2)))
  Invoke-Click $app $d
  Pause 1

  # 1. Drag the panel (pressed inside its client area) onto the dock.
  $p = @(($panel.ClientX + [int]($panel.ClientW / 2)), ($panel.ClientY + [int]($panel.ClientH / 2)))
  Invoke-Drag $app $p @(@(($p[0] - 100), ($p[1] + 20), 400), @($d[0], $d[1], 900))
  Pause 1.5
  Check "1 panel window is gone once docked" ($null -eq (Get-Win $app "Panel*")) ((Get-Wins $app | % { $_.Title }) -join ", ")
  Check "1 dock says it holds the panel" ($null -ne (Get-Win $app "Dock*docked*")) ((Get-Wins $app | % { $_.Title }) -join ", ")

  # 2. Take the focus away (the press proxy needs a focus change), then press inside the
  #    dock and drag out: tear off.
  Invoke-Blur
  $dock = Get-Win $app "Dock*"
  $s = @(($dock.ClientX + [int]($dock.ClientW / 3)), ($dock.ClientY + [int]($dock.ClientH / 2)))
  $e = @(($dock.Left + 300), ($dock.Top - 200))
  Invoke-Drag $app $s @(@(($s[0] + 150), ($s[1] + 30), 500), @($e[0], $e[1], 900))
  Pause 1.5
  $panel = Get-Win $app "Panel*"
  Check "2 panel is a window again" ($null -ne $panel)
  if ($panel) {
    # The example anchors the torn-off panel at (130, 12) from its frame corner.
    Check "2 panel sits anchored under the cursor" (([math]::Abs($panel.Left - ($e[0] - 130)) -le 2) -and ([math]::Abs($panel.Top - ($e[1] - 12)) -le 2)) "panel $($panel.Left),$($panel.Top); cursor $($e -join ',')"
  }
} catch {
  Check "ran to the end" $false "$_"
} finally {
  $lines = @(Stop-GuiApp $app)
  Close-BlurWindow
}
$text = $lines -join "`n"
Check "output: panel docked" ($text -match "Panel docked")
Check "output: panel torn off" ($text -match "Panel torn off")
$lines | % { Say "app: $_" }
Say "$script:Failures failure(s)"
exit $script:Failures
