# GUI test (Windows) of core's drag_drop_example (C++): drag the example's file out of the
# "Drag me" window onto the "Drop here" window (DragSource and DropTarget in one gesture),
# then start a drag and release it where nothing accepts it. The Windows twin of
# core_drag_drop_test.py. Built on the gui-test skill. Build first (desktop session):
#   cmake -S $RemoteWorkspace\core -B $RemoteScratch\core-build -G "Visual Studio 17 2022" -A x64
#   cmake --build $RemoteScratch\core-build --config Debug --target drag_drop_example
# Run (remote-hosts skill):  remote.sh <host> setup; remote.sh <host> desktop tools/gui/core_drag_drop_test.ps1 120
# ASCII only.
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\env.ps1"; . "$PSScriptRoot\winput.ps1"; . "$PSScriptRoot\guiapp.ps1"
Start-Result "$RemoteScratch\core_drag_drop_test.result.txt"

function Get-Center($win) { @(($win.ClientX + [int]($win.ClientW / 2)), ($win.ClientY + [int]($win.ClientH / 2))) }

Assert-Idle
$app = Start-ConsoleApp "$RemoteScratch\core-build\examples\drag_drop_example\Debug\drag_drop_example.exe"
$lines = @()
$target = $null; $dropWin = $null
try {
  # Park both windows where nothing else is, and lift them above other programs.
  foreach ($w in Get-Wins $app) {
    if ($w.Title -eq "Drop here") { [WInput]::Move($w.Hwnd, 40, 60) }
    if ($w.Title -eq "Drag me") { [WInput]::Move($w.Hwnd, 700, 60) }
    [WInput]::Raise($w.Hwnd)
  }
  Pause 0.5
  $dropWin = Get-Win $app "Drop here"; $source = Get-Win $app "Drag me"
  if (-not $dropWin -or -not $source) { throw "windows not found" }

  # The example starts a drag when "Drag me" becomes focused: focus the other first.
  $target = Get-Center $dropWin
  Invoke-Click $app $target 200
  Pause 0.5

  # 1. Press in "Drag me", drag onto "Drop here", release there.
  $s = Get-Center $source
  Invoke-Drag $app $s @(@(($s[0] - 40), ($s[1] + 20), 400), @(($target[0] + 60), $target[1], 700), @($target[0], $target[1], 500)) 300
  Pause 1.5

  # 2. Press in "Drag me", pass over "Drop here", come back and release on "Drag me",
  #    which accepts nothing.
  Invoke-Click $app $target 200
  Pause 0.5
  $source = Get-Win $app "Drag me"
  $s = Get-Center $source
  Invoke-Drag $app $s @(@(($s[0] - 40), ($s[1] + 20), 400), @($target[0], $target[1], 700), @($s[0], ($s[1] + 30), 700)) 300
  Pause 1.5

  # 3. The app still takes clicks afterwards.
  Invoke-Click $app $target 200
  Pause 0.5
  Check "3 app still responds" (-not $app.Proc.HasExited)
} catch {
  Check "ran to the end" $false "$_"
} finally {
  $lines = @(Stop-GuiApp $app)
}

# Scenario 1 and 2 are told apart by the "Dragging" line that starts each.
$starts = @(0..($lines.Count - 1) | ? { $lines[$_] -like "Dragging *" })
Check "both drags started" ($starts.Count -eq 2) "$($starts.Count) drag(s)"
if ($starts.Count -eq 2) {
  $first = $lines[$starts[0]..($starts[1] - 1)]
  $second = $lines[$starts[1]..($lines.Count - 1)]
  Check "1 target saw the drag enter" (@($first | ? { $_ -like "Entered at*" }).Count -gt 0)
  Check "1 target saw it move" (@($first | ? { $_ -like "Moved to*" }).Count -gt 0)
  Check "1 file dropped" (@($first | ? { $_ -like "*file: *nativeapi-drag-drop-example.txt" }).Count -eq 1)
  Check "1 text dropped" (@($first | ? { $_ -eq "  text: Hello from drag_drop_example" }).Count -eq 1)
  Check "1 source reports a copy" (@($first | ? { $_ -eq "Drag ended: copy" }).Count -eq 1)
  $dropped = @($first | ? { $_ -like "Dropped at*" }) | Select-Object -First 1
  if ($dropped -match "^Dropped at \(([-\d.]+), ([-\d.]+)\)$" -and $dropWin) {
    # Content coordinates: the drop point relative to the client area, in logical px.
    $ex = ($target[0] - $dropWin.ClientX) / $dropWin.Scale
    $ey = ($target[1] - $dropWin.ClientY) / $dropWin.Scale
    $ok = ([math]::Abs([double]$Matches[1] - $ex) -le 3) -and ([math]::Abs([double]$Matches[2] - $ey) -le 3)
    Check "1 drop position is in content coordinates" $ok "got $dropped, expected ($ex, $ey)"
  } else {
    Check "1 drop position reported" $false "$dropped"
  }
  Check "2 target saw the drag enter and exit" ((@($second | ? { $_ -like "Entered at*" }).Count -gt 0) -and (@($second | ? { $_ -eq "Exited" }).Count -gt 0))
  Check "2 nothing dropped" (@($second | ? { $_ -like "Dropped at*" }).Count -eq 0)
  Check "2 source reports no operation" (@($second | ? { $_ -eq "Drag ended: none" }).Count -eq 1)
}
$lines | ? { $_ -notlike "Moved to*" } | % { Say "app: $_" }
Say "$script:Failures failure(s)"
exit $script:Failures
