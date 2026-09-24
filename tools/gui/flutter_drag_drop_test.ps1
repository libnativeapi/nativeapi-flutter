# GUI test (Windows) of drag_drop_example: drag the note card (a file) and the text card out of
# their DragOutArea onto the DropRegion of the same window; the region lists what arrived, the
# source reports the operation, and a second drag works after the first. The Windows twin of
# flutter_drag_drop_test.py. Dropping outside the window is not exercised: it would drop the
# note on another program. Built on the gui-test skill; takes over the mouse for ~20 s.
# Run (remote-hosts skill):  remote.sh <host> setup; remote.sh <host> desktop tools/gui/flutter_drag_drop_test.ps1 150
# ASCII only.
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\env.ps1"; . "$PSScriptRoot\winput.ps1"; . "$PSScriptRoot\guiapp.ps1"
Start-Result "$RemoteScratch\flutter_drag_drop_test.result.txt"

$Drop = "Drop files or text here"
$File = "nativeapi-drag-drop-note.txt"

function Look($app) {
  Pause 0.3
  $win = Get-Win $app "*Drag and drop"
  if (-not $win) { throw "the example's window is gone" }
  @{ Win = $win; View = (Find-View (Get-Views $app) "Drag out") }
}
# The full path the drop list shows (the drag card only shows the file name).
function Get-DroppedPath($view) { @($view.texts | % { $_[0] } | ? { $_ -like "*\$File" }) | Select-Object -First 1 }
function Invoke-DragCard($app, [string]$card) {
  $now = Look $app
  $start = ConvertTo-Screen $now.Win (Get-TextCenter $now.View $card)
  $area = @($now.View.texts | ? { $_[0] -eq $Drop -or $_[0] -eq "Release to drop" })[0][1]
  $t = ConvertTo-Screen $now.Win @(($area[0] + $area[2] / 2), ($area[1] + 120))
  $s = $now.Win.Scale
  Invoke-Drag $app $start @(@(($start[0] - 30 * $s), ($start[1] + 10 * $s), 350), @(($t[0] + 60 * $s), $t[1], 700), @($t[0], $t[1], 500)) 300
  Pause 1.5
}

Assert-Idle
$app = Start-GuiApp (Get-FlutterExe "$RemoteWorkspace\examples\flutter_drag_drop_example") -MinViews 1
try {
  $now = Look $app
  Invoke-Activate $app $now.Win
  $now = Look $app
  Check "both widgets report support" (@(Get-ViewTexts @($now.View) "^Supported: true$").Count -eq 2) ((Get-ViewTexts @($now.View) "^Supported") -join ", ")
  Check "nothing dropped yet" (Test-ViewText $now.View "Drops: 0")

  # 1. The note: a file.
  Invoke-DragCard $app "Drag this note"
  $now = Look $app
  Check "1 one drop" (Test-ViewText $now.View "Drops: 1") ((Get-ViewTexts @($now.View) "^Drops") -join ", ")
  Check "1 the note file arrived" ($null -ne (Get-DroppedPath $now.View)) ((@($now.View.texts | % { $_[0] })) -join " | ")
  Check "1 the source saw a copy" (Test-ViewText $now.View "Last drag: copy") ((Get-ViewTexts @($now.View) "^Last drag") -join ", ")
  Check "1 highlight is gone after the drop" (Test-ViewText $now.View $Drop)

  # 2. The text: proves the first drag left no gesture stuck behind.
  Invoke-DragCard $app "Drag this text"
  $now = Look $app
  Check "2 second drop" (Test-ViewText $now.View "Drops: 2") ((Get-ViewTexts @($now.View) "^Drops") -join ", ")
  Check "2 the text arrived" (Test-ViewText $now.View "Text: Hello from nativeapi") ((Get-ViewTexts @($now.View) "^Text") -join ", ")
  Check "2 no file this time" ($null -eq (Get-DroppedPath $now.View))
  Check "2 the source saw a copy" (Test-ViewText $now.View "Last drag: copy")
} catch {
  Check "ran to the end" $false "$_"
} finally {
  Stop-GuiApp $app | Out-Null
}
Say "$script:Failures failure(s)"
exit $script:Failures
