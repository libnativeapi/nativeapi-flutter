# GUI test (Windows) of detachable_window_example: tear a panel off, dock it into the other
# window, check size, position and preserved state. Built on the gui-test skill.
# Run (remote-hosts skill):  remote.sh <host> setup; remote.sh <host> desktop tools/gui/flutter_detachable_window_test.ps1 120
# ASCII only.
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\env.ps1"; . "$PSScriptRoot\winput.ps1"; . "$PSScriptRoot\guiapp.ps1"
Start-Result "$RemoteScratch\flutter_detachable_window_test.result.txt"

function Look($app) {
  $views = Get-Views $app
  @{ A = Find-View $views "Window A"; B = Find-View $views "Window B"
     Floating = @($views | ? { -not (Test-ViewText $_ "Window A") -and -not (Test-ViewText $_ "Window B") }) }
}

Assert-Idle
$app = Start-GuiApp (Get-FlutterExe "$RemoteWorkspace\bindings\flutter\examples\detachable_window_example") -MinViews 2
try {
  $wa = Get-Win $app "*Window A"; $wb = Get-Win $app "*Window B"
  Invoke-Activate $app $wb; Invoke-Activate $app $wa
  $v = Look $app

  # State that has to survive the moves.
  $plus = ConvertTo-Screen $wa (Get-TextCenter $v.A "+1")
  1..3 | % { Invoke-Click $app $plus 350; Pause 0.25 }

  # 1. Tear the Inspector off; drop it over the workspace so it stays a window.
  $start = ConvertTo-Screen $wa (Get-TextCenter $v.A "Inspector")
  $drop = @(($wa.ClientX + [int](470 * $wa.Scale)), ($wa.ClientY + [int](160 * $wa.Scale)))
  Invoke-Drag $app $start @(@(($start[0] + 60), ($start[1] + 40), 350), @($drop[0], $drop[1], 900))
  Pause 1.5
  $wi = Get-Win $app "Inspector"
  Check "Inspector became its own window" ($null -ne $wi) ((Get-Wins $app | % { $_.Title }) -join ", ")
  $v = Look $app
  Check "one floating view" ($v.Floating.Count -eq 1) "got $($v.Floating.Count)"
  if ($wi) {
    # The floating window's content is exactly as big as the slot it left (240 logical px wide).
    $w = $wi.ClientW / $wi.Scale
    Check "floating content width is 240" ([math]::Abs($w - 240) -le 1) "got $w"
    # The grabbed point stays under the cursor.
    $v = Look $app
    $grabbed = ConvertTo-Screen $wi (Get-TextCenter $v.Floating[0] "Inspector")
    Check "header still under the cursor" (([math]::Abs($grabbed[0] - $drop[0]) -le 3) -and ([math]::Abs($grabbed[1] - $drop[1]) -le 3)) "header $($grabbed -join ','), cursor $($drop -join ',')"

    # 2. Dock it into Window B's wide sidebar.
    $target = ConvertTo-Screen $wb (Get-TextCenter $v.B "Wide sidebar")
    Invoke-Drag $app $grabbed @(@(($grabbed[0] + 200), ($grabbed[1] + 60), 700), @($target[0], $target[1], 900))
    Pause 1.5
    Check "floating window is gone after docking" ($null -eq (Get-Win $app "Inspector"))
    $v = Look $app
    Check "Inspector now lives in Window B" (Test-ViewText $v.B "Inspector")
  }

  # 3. The State object moved with it: same clicks, not a fresh panel.
  $state = @(Get-ViewTexts (Get-Views $app) "^(Clicks|State #)")
  Check "click count survived" (@($state | ? { $_ -match "^Clicks.*3" }).Count -gt 0) ($state -join " | ")
} catch {
  Check "ran to the end" $false "$_"
} finally {
  Stop-GuiApp $app | Out-Null
}
Say "$script:Failures failure(s)"
exit $script:Failures
