# guiapp.ps1 - launch an app, look at it, drive it. Dot-source after env.ps1 and winput.ps1:
#
#   . "$PSScriptRoot\env.ps1"; . "$PSScriptRoot\winput.ps1"; . "$PSScriptRoot\guiapp.ps1"
#
# Screen coordinates are physical pixels; view coordinates (from uiprobe) are logical.

function Pause([double]$Seconds) { Start-Sleep -Milliseconds ([int]($Seconds * 1000)) }

# Timestamped line into a UTF-8 result file (and the job log).
$script:ResultFile = $null
function Start-Result([string]$Path) { $script:ResultFile = $Path; Remove-Item $Path -ErrorAction SilentlyContinue }
function Say([string]$Message) {
  $line = "$(Get-Date -Format HH:mm:ss.fff) $Message"
  if ($script:ResultFile) { $line | Out-File $script:ResultFile -Append -Encoding utf8 }
  Write-Host $line  # not the pipeline: Say is called inside functions that return values
}
$script:Failures = 0
function Check([string]$What, [bool]$Ok, [string]$Detail = "") {
  if (-not $Ok) { $script:Failures++ }
  Say ("{0} {1}{2}" -f $(if ($Ok) { "PASS" } else { "FAIL" }), $What, $(if ($Detail) { " - $Detail" } else { "" }))
}

# -- launching -----------------------------------------------------------------

# The runner inside a Flutter project's Windows debug build; -Name defaults to the directory name.
function Get-FlutterExe([string]$ProjectDir, [string]$Name = "") {
  if (-not $Name) { $Name = Split-Path $ProjectDir -Leaf }
  "$ProjectDir\build\windows\x64\runner\Debug\$Name.exe"
}

# A GUI-subsystem app (Flutter runner). With -MinViews, waits until uiprobe sees that many views.
function Start-GuiApp([string]$Exe, [int]$MinViews = 0, [int]$TimeoutSeconds = 40) {
  if (-not (Test-Path $Exe)) { throw "$Exe is missing; build it first" }
  $log = Join-Path $RemoteScratch ((Split-Path $Exe -Leaf) + ".log")
  Remove-Item $log -ErrorAction SilentlyContinue
  $proc = Start-Process $Exe -PassThru -RedirectStandardOutput $log
  $app = @{ Proc = $proc; Log = $log; Stdout = $null }
  if ($MinViews -gt 0) {
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do { Start-Sleep -Milliseconds 500; $views = @(Get-Views $app) } until ($views.Count -ge $MinViews -or (Get-Date) -gt $deadline)
    if ($views.Count -lt $MinViews) { Stop-GuiApp $app | Out-Null; throw "$Exe did not come up with $MinViews views" }
  } else { Pause 3 }
  Pause 1.5  # first frames
  return $app
}

# A console-subsystem app (core C++ examples): no console window, stdout collected.
function Start-ConsoleApp([string]$Exe) {
  if (-not (Test-Path $Exe)) { throw "$Exe is missing; build it first" }
  $psi = New-Object System.Diagnostics.ProcessStartInfo $Exe
  $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true; $psi.RedirectStandardOutput = $true
  $proc = [System.Diagnostics.Process]::Start($psi)
  $app = @{ Proc = $proc; Log = $null; Stdout = $proc.StandardOutput.ReadToEndAsync() }
  Pause 3
  return $app
}

# Stops the app; returns a console app's output lines.
function Stop-GuiApp($App) {
  Stop-Process -Id $App.Proc.Id -ErrorAction SilentlyContinue
  Pause 1
  if ($App.Stdout -and $App.Stdout.Wait(3000)) { return ($App.Stdout.Result -split "`r?`n" | ? { $_ }) }
}

# -- looking -------------------------------------------------------------------

function Get-Wins($App) { @(Get-AppWindows $App.Proc.Id | ? { $_.ClientW -gt 100 }) }
function Get-Win($App, [string]$TitleLike) { Get-Wins $App | ? { $_.Title -like $TitleLike } | Select-Object -First 1 }

# Views of a debug Flutter app: objects with name, size, texts ([text, [x, y, w, h]]).
# Empty while the VM service is not up yet.
function Get-Views($App) {
  # PowerShell 5.1's ConvertFrom-Json emits a JSON array as ONE object; assigning it first
  # makes the function output its elements, so `Get-Views $app | ? { ... }` filters views.
  $parsed = (& $Python "$RemoteScratch\uiprobe.py" $App.Log) | ConvertFrom-Json
  if ($parsed -isnot [array]) { return }  # {"error": ...}
  $parsed
}
function Test-ViewText($View, [string]$Text) { @($View.texts | ? { $_[0] -eq $Text }).Count -gt 0 }
function Find-View($Views, [string]$Text) { $Views | ? { Test-ViewText $_ $Text } | Select-Object -First 1 }
function Get-ViewTexts($Views, [string]$Pattern) { $Views | % { $_.texts | % { $_[0] } | ? { $_ -match $Pattern } } }

# Center of a text in view coordinates. -MaxY keeps only texts above that line
# (e.g. a tab chip rather than the page heading with the same text); -Like matches a wildcard.
function Get-TextCenter($View, [string]$Text, [double]$MaxY = [double]::MaxValue, [switch]$Like) {
  foreach ($t in $View.texts) {
    $hit = if ($Like) { $t[0] -like $Text } else { $t[0] -eq $Text }
    if ($hit -and $t[1][1] -lt $MaxY) { $r = $t[1]; return @(($r[0] + $r[2] / 2), ($r[1] + $r[3] / 2)) }
  }
  throw "'$Text' not found in view $($View.name)"
}

# A view point (logical) to the screen (physical) through the window showing the view.
function ConvertTo-Screen($Win, $Point) { @([int]($Win.ClientX + $Point[0] * $Win.Scale), [int]($Win.ClientY + $Point[1] * $Win.Scale)) }

# -- acting (every press is checked to land on the app's own windows) ----------

function Move-Cursor($Point, [int]$Ms = 600) { [WInput]::Glide([int]$Point[0], [int]$Point[1], $Ms) }

function Invoke-Click($App, $Point, [int]$ApproachMs = 450) {
  Move-Cursor $Point $ApproachMs
  Assert-Owner $App.Proc.Id $Point[0] $Point[1]
  [WInput]::Click([int]$Point[0], [int]$Point[1])
}

# $Legs: @(x, y, ms) arrays. A single leg needs the unary comma: @(,@(x, y, ms)).
function Invoke-Drag($App, $Start, [object[]]$Legs, [int]$ApproachMs = 500) {
  Move-Cursor $Start $ApproachMs
  Assert-Owner $App.Proc.Id $Start[0] $Start[1]
  $a = @([int]$Start[0], [int]$Start[1])
  foreach ($l in $Legs) { $a += @([int]$l[0], [int]$l[1], [int]$l[2]) }
  [WInput]::Drag([int[]]$a)
}

function Invoke-Wheel($App, $Point, [int]$Lines) {
  Move-Cursor $Point 400
  Assert-Owner $App.Proc.Id $Point[0] $Point[1]
  [WInput]::Wheel($Lines)
}

# A background-launched app cannot take the foreground and may open underneath another
# program's window: lift the window in the z-order, then click its title bar to activate it.
# For a window without a title bar pass -ClientY (logical px from the client top) of a safe strip.
function Invoke-Activate($App, $Win, [int]$ClientY = -1) {
  [WInput]::Raise($Win.Hwnd)
  Pause 0.3
  $x = $Win.Left + [int](($Win.Right - $Win.Left) * 0.7)
  $y = if ($ClientY -ge 0) { $Win.ClientY + [int]($ClientY * $Win.Scale) } else { $Win.Top + [int](($Win.ClientY - $Win.Top) / 2) }
  Invoke-Click $App @($x, $y) 500
  Pause 0.3
}
