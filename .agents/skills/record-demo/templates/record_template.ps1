# Demo recording template (Windows): wrap scenario functions in the screen recorder.
# Run from the Mac:  .agents/skills/record-demo/scripts/record_remote.sh <host> <this file> <output dir>
# The MP4 is encoded on the host (needs ffmpeg there). No keyboard input, no audio. ASCII only.
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\env.ps1"; . "$PSScriptRoot\winput.ps1"; . "$PSScriptRoot\guiapp.ps1"; . "$PSScriptRoot\recorder.ps1"
$name = [IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
Start-Result "$RemoteScratch\$name.result.txt"

function Scenario-One {
  $app = Start-GuiApp (Get-FlutterExe "$RemoteWorkspace\TODO\path\to\flutter_project") -MinViews 1
  try {
    # TODO: the story - state, feature, proof. See the gui-test template for the building
    # blocks; pace it for a viewer (eased approaches, 2-3 drag legs, 1.2-1.5 s rests).
    Pause 2.5  # hold the final frame
    Say ("scenario one done: " + ((Get-ViewTexts (Get-Views $app) "^TODO proof pattern") -join " | "))
  } finally { Stop-GuiApp $app | Out-Null }
}

try {
  Assert-Idle
  Start-Recording "$RemoteScratch\$name-windows.mp4"   # named after this script
  Say "recording"
  try {
    Pause 1.5
    Scenario-One
    Pause 1      # a beat of bare desktop between scenarios becomes the transition
  } finally {
    Say "saved $(Stop-Recording)"
  }
} catch {
  Say "ERROR: $_"
}
