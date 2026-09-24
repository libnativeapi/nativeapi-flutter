# interactive.ps1 -Script <name.ps1 in this directory> [-Timeout seconds]
# Runs a script hidden in the logged-on desktop session (an SSH session has no
# desktop) through a one-shot scheduled task, waits for it, and prints its output.
param([string]$Script, [int]$Timeout = 600)
$task = "ClaudeInteractive"
$done = "$PSScriptRoot\interactive.done"
$log = "$PSScriptRoot\job.log"
Remove-Item $done, $log -ErrorAction SilentlyContinue
# job.ps1 wraps the script so that everything it prints ends up in job.log.
@"
& '$PSScriptRoot\$Script' *> '$log'
exit `$LASTEXITCODE
"@ | Out-File "$PSScriptRoot\job.ps1" -Encoding ascii
schtasks /Create /TN $task /TR "wscript.exe $PSScriptRoot\job.vbs" /SC ONCE /ST 23:59 /RU $env:USERNAME /IT /F | Out-Null
schtasks /Run /TN $task | Out-Null
$t = 0
while (-not (Test-Path $done) -and $t -lt $Timeout) { Start-Sleep 1; $t++ }
schtasks /Delete /TN $task /F | Out-Null
if (Test-Path $log) { Get-Content $log }
if (Test-Path $done) { "[desktop] finished after ${t}s, exit $((Get-Content $done).Trim())" }
else { "[desktop] TIMEOUT after ${t}s - the job may still be running"; exit 1 }
