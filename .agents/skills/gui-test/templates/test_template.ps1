# GUI test template (Windows). Copy it next to the project's other GUI tests, fill in the
# TODOs, and keep the shape: idle check, launch, look, act, settle, look again, assert, quit.
# Run (remote-hosts skill):  remote.sh <host> setup; remote.sh <host> desktop <this file> 120
# Keep the file ASCII; match non-ASCII window titles with wildcards.
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\env.ps1"; . "$PSScriptRoot\winput.ps1"; . "$PSScriptRoot\guiapp.ps1"
Start-Result "$RemoteScratch\TODO_name.result.txt"

Assert-Idle  # never fight a person for the mouse
# A Flutter project's debug build (waits for its views), or Start-ConsoleApp for a console exe.
$app = Start-GuiApp (Get-FlutterExe "$RemoteWorkspace\TODO\path\to\flutter_project") -MinViews 1
try {
  # Look: OS windows + probed views. Identify a view by a text only it shows.
  $win = Get-Win $app "*TODO window title*"
  Invoke-Activate $app $win          # a background-launched app is neither on top nor active
  $view = Find-View (Get-Views $app) "TODO: a text in that window"

  # Act: one owner-checked gesture. Drag in two legs: a short one to pass the drag
  # threshold, then the long one. View points are logical; ConvertTo-Screen applies the DPI scale.
  $start = ConvertTo-Screen $win (Get-TextCenter $view "TODO: text to grab")
  $drop = @(($start[0] + 300), ($start[1] + 200))
  Invoke-Drag $app $start @(@(($start[0] + 60), ($start[1] + 40), 350), @($drop[0], $drop[1], 900))
  Pause 1.5                          # windows are created, destroyed and laid out asynchronously

  # Look again (never reuse coordinates from before the gesture), then assert numbers.
  $titles = (Get-Wins $app | % { $_.Title }) -join ", "
  Check "TODO: what should be true now" ($null -ne (Get-Win $app "TODO*")) $titles
  $state = @(Get-ViewTexts (Get-Views $app) "^TODO pattern")
  Check "TODO: state survived" ($state.Count -gt 0) ($state -join " | ")
} catch {
  Check "ran to the end" $false "$_"
} finally {
  Stop-GuiApp $app | Out-Null
}
Say "$script:Failures failure(s)"
exit $script:Failures
