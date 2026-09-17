# Demo recording template (Windows): wrap scenario functions in the screen recorder.
# Run (remote-hosts skill):  remote.sh <host> setup; remote.sh <host> desktop <this file> 400
# Then:                      remote.sh <host> pull <script name>.frames ./frames; video.py encode-frames ./frames <script name>-windows.full.mp4
# No keyboard input, no audio. ASCII only.
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\env.ps1"; . "$PSScriptRoot\winput.ps1"; . "$PSScriptRoot\guiapp.ps1"; . "$PSScriptRoot\recorder.ps1"
Start-Result "$RemoteScratch\demo.result.txt"

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
  [ScreenRecorder]::Start("$RemoteScratch\TODO_script_name.frames", 30)  # named after this script
  Say "recording"
  Pause 1.5
  Scenario-One
  Pause 1      # a beat of bare desktop between scenarios becomes the transition
} catch {
  Say "ERROR: $_"
} finally {
  [ScreenRecorder]::Stop()
  Say "stopped after $([ScreenRecorder]::Frames) frames"
}
