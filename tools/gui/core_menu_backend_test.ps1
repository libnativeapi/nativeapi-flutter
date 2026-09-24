# GUI test (Windows) of core's native menu backend: a menu item click must reach its
# listener before Menu::Open() returns. A posted WM_COMMAND (the pre-TPM_RETURNCMD
# behaviour) is dispatched later, from the host's message loop, where bindings with
# call-scoped callbacks cannot receive it - Dart's NativeCallable.isolateLocal aborts
# the process there.
#
# Drives core's tests/menu_click_test.cpp, which opens one real menu per run and checks
# the events itself; this script only supplies the mouse. Built on the gui-test skill.
# Build first (desktop session):
#   cmake -S $RemoteWorkspace\core -B $RemoteScratch\core-build -G "Visual Studio 17 2022" -A x64 -DBUILD_TESTING=ON
#   cmake --build $RemoteScratch\core-build --config Debug --target menu_click_test
# Run (remote-hosts skill):  remote.sh <host> setup; remote.sh <host> desktop tools/gui/core_menu_backend_test.ps1 300
# ASCII only.
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\env.ps1"; . "$PSScriptRoot\winput.ps1"; . "$PSScriptRoot\guiapp.ps1"
Start-Result "$RemoteScratch\core_menu_backend_test.result.txt"

$exe = "$RemoteScratch\core-build\tests\Debug\menu_click_test.exe"
$flag = Join-Path $RemoteScratch "go.flag"

# Launches one round, activates its window, tells it to open the menu, works the menu
# with the mouse, and returns the round's own PASS/FAIL lines.
function Invoke-Round([string]$Round) {
  Remove-Item $flag -ErrorAction SilentlyContinue
  $psi = New-Object System.Diagnostics.ProcessStartInfo $exe
  $psi.Arguments = $Round
  $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true; $psi.RedirectStandardOutput = $true
  $psi.WorkingDirectory = $RemoteScratch     # where the test looks for go.flag
  $proc = [System.Diagnostics.Process]::Start($psi)
  $app = @{ Proc = $proc; Log = $null; Stdout = $proc.StandardOutput.ReadToEndAsync() }
  $script:RoundLines = @()   # kept even when this round throws
  try {
    $win = $null
    $deadline = (Get-Date).AddSeconds(10)
    do { $win = Get-Win $app "nativeapi menu click test"; if (-not $win) { Pause 0.3 } } until ($win -or (Get-Date) -gt $deadline)
    if (-not $win) { throw "the test window never appeared" }
    # One click only: a second one would dismiss the menu the test is about to open.
    Invoke-Activate $app $win
    Pause 1.0
    New-Item -ItemType File -Path $flag -Force | Out-Null

    if (-not (Wait-Menu $app 0 -TimeoutSeconds 20)) { throw "the menu never opened" }
    switch ($Round) {
      "pick_top_level" { Invoke-MenuItem $app "Alpha" 0 | Out-Null }
      "pick_submenu" {
        Invoke-HoverMenuItem $app "More" 0 | Out-Null
        if (-not (Wait-Menu $app 1 -TimeoutSeconds 8)) { throw "the submenu never opened" }
        Invoke-MenuItem $app "Beta" 1 | Out-Null
      }
      "dismiss" {
        # The app's own window, well clear of the menu: the open menu eats this click.
        $pt = @([int]($win.Left + ($win.Right - $win.Left) / 2), [int]($win.Bottom - 60))
        Move-Cursor $pt 400
        Assert-Owner $app.Proc.Id $pt[0] $pt[1]
        [WInput]::Click([int]$pt[0], [int]$pt[1])
      }
    }
    if (-not (Wait-Menu $app 0 -Closed -TimeoutSeconds 10)) { throw "the menu stayed open" }
    $app.Proc.WaitForExit(20000) | Out-Null
  } finally {
    $script:RoundLines = @(Stop-GuiApp $app)
    Remove-Item $flag -ErrorAction SilentlyContinue
  }
  return $script:RoundLines
}

Assert-Idle
if (-not (Test-Path $exe)) { throw "$exe is missing; build menu_click_test first" }

foreach ($round in @("pick_top_level", "dismiss", "pick_submenu")) {
  $script:RoundLines = @()
  try {
    Invoke-Round $round | Out-Null
  } catch {
    Check "$round ran to the end" $false "$_"
  }
  $lines = $script:RoundLines
  foreach ($line in $lines) {
    if ($line -like "FAIL *") { Check "$round - $($line.Substring(5))" $false }
    elseif ($line -like "PASS *") { Check "$round - $($line.Substring(5))" $true }
    else { Say "$round : $line" }
  }
  Check "$round reported a verdict" (@($lines | ? { $_ -eq "OK" -or $_ -eq "FAILED" }).Count -eq 1)
}

Say "$script:Failures failure(s)"
exit $script:Failures
