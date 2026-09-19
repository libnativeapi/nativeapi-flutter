# Runs core's tests/menu_lifetime_test.cpp on the real desktop (issue 54): destroying a
# Menu from a listener that runs inside the window procedure must not kill the process,
# and a menu created after every other menu was destroyed must still get its events.
# No mouse, no keyboard - the menus close themselves from a timer - but it does need a
# logged-on desktop session, which is why it lives here and not in CTest's headless run.
# Build first (desktop session):
#   cmake -S $RemoteWorkspace\core -B $RemoteScratch\core-build -G "Visual Studio 17 2022" -A x64 -DBUILD_TESTING=ON
#   cmake --build $RemoteScratch\core-build --config Debug --target menu_lifetime_test
# Run (remote-hosts skill):  remote.sh <host> setup; remote.sh <host> desktop tools/gui/core_menu_lifetime_test.ps1 120
# A process killed by the kernel reports an exit code like 0xC000041D
# (STATUS_FATAL_USER_CALLBACK_EXCEPTION), which is what the unfixed dispatcher did.
# ASCII only.
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\env.ps1"; . "$PSScriptRoot\winput.ps1"; . "$PSScriptRoot\guiapp.ps1"
Start-Result "$RemoteScratch\core_menu_lifetime_test.result.txt"

$exe = "$RemoteScratch\core-build\tests\Debug\menu_lifetime_test.exe"
if (-not (Test-Path $exe)) { throw "$exe is missing; build menu_lifetime_test first" }

$psi = New-Object System.Diagnostics.ProcessStartInfo $exe
$psi.Arguments = "interactive"
$psi.UseShellExecute = $false; $psi.CreateNoWindow = $true; $psi.RedirectStandardOutput = $true
$psi.WorkingDirectory = $RemoteScratch
$proc = [System.Diagnostics.Process]::Start($psi)
$stdout = $proc.StandardOutput.ReadToEndAsync()
if (-not $proc.WaitForExit(60000)) { $proc.Kill(); Check "test finished" $false "still running after 60s" }
$code = $proc.ExitCode
$lines = @($stdout.Result -split "`r?`n" | ? { $_ })

foreach ($line in $lines) {
  if ($line -like "PASS *") { Check $line.Substring(5) $true }
  elseif ($line -like "FAIL *") { Check $line.Substring(5) $false }
  else { Say $line }
}
Check "process survived" ($code -eq 0 -or $code -eq 1) ("exit 0x" + ("{0:X8}" -f $code))
Check "test reported a verdict" (@($lines | ? { $_ -eq "OK" -or $_ -eq "FAILED" }).Count -eq 1)

Say "$script:Failures failure(s)"
exit $script:Failures
