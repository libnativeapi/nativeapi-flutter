# GUI test (Windows) of tray_icon_example: animated tray icons really are rendered and pushed
# frame by frame (frame counter, rate, no dropped frames, Pause / Step, the widget-captured
# animation, three icons at once), every property reads back from the native getters, the
# window moves next to the tray icon, and the context menu opens from code, shows its items
# and closes again from code - once per menu backend (WinUI 3 when supported, then Native).
# The Windows twin of flutter_tray_icon_test.py. It does not click the tray icon itself: the
# driver only presses on the app's own windows, so those events stay manual items of the
# example's Checklist tab. Windows tray icons have no title, so the macOS twin's title checks
# become one "no-op" check here. Built on the gui-test skill; takes over the mouse for ~2 min.
# Run (remote-hosts skill):  remote.sh <host> setup; remote.sh <host> desktop tools/gui/flutter_tray_icon_test.ps1 400
# ASCII only: the middle dot and the CJK title are built from char codes.
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\env.ps1"; . "$PSScriptRoot\winput.ps1"; . "$PSScriptRoot\guiapp.ps1"
Start-Result "$RemoteScratch\flutter_tray_icon_test.result.txt"

$Dot = [string][char]0x00B7
$NiHao = [string][char]0x4F60 + [string][char]0x597D
$MenuItems = "Show window", "Animate", "Notifications", "Check for updates", "About", "Quit"
# TrayManager never registers icons (specs/managers.md, known gap).
$KnownFailures = @("managed")

function Look($app) {
  if (@(Get-OpenMenus $app).Count) { throw "a menu is still open; refusing to probe" }
  $win = Get-Win $app "*tray*"
  if (-not $win) { throw "the example's window is gone" }
  @{ Win = $win; View = (Find-View (Get-Views $app) "Tray icons") }
}
function Get-Texts($app) { @((Look $app).View.texts | % { $_[0] }) }
function Get-TextLike($app, [string]$Like) { @(Get-Texts $app | ? { $_ -like $Like }) | Select-Object -First 1 }
function Press($app, [string]$Label, [double]$Settle = 0.7, [switch]$Like) {
  $now = Look $app
  $center = if ($Like) { Get-TextCenter $now.View $Label -Like } else { Get-TextCenter $now.View $Label }
  Invoke-Click $app (ConvertTo-Screen $now.Win $center)
  Pause $Settle
}
function Get-FrameCount($app) {
  $line = Get-TextLike $app "frame * fps"
  if ($line -notmatch "^frame (\d+) . ([\d.]+) fps") { throw "the preview shows no frame counter ($line)" }
  @([int]$Matches[1], [double]$Matches[2])
}
# Latest status of each checklist item, from the [checklist] lines the example prints.
function Get-Checklist($app) {
  $status = @{}
  foreach ($line in (Get-Content $app.Log -Encoding UTF8)) {
    if ($line -match "\[checklist\] (\S+) (\w+) ?(.*)") { $status[$Matches[1]] = @($Matches[2], $Matches[3]) }
  }
  $status
}

function Test-Menu($app, [string]$Backend) {
  Press $app "Open menu" 0.3
  $opened = Wait-Menu $app
  Check "[$Backend] openContextMenu opens the menu" $opened
  if ($opened) {
    Pause 0.5
    $items = @(Get-OpenMenus $app | ? { $_.Depth -eq 0 } | % { $_.Items })
    $titles = @($items | % { $_.Title } | ? { $_ })
    Check "[$Backend] the menu shows its items" (($titles -join "|") -eq ($MenuItems -join "|")) ($titles -join ", ")
    Check "[$Backend] the disabled item is disabled" (-not (Get-MenuItem $app "Check for updates").Enabled)
    Check "[$Backend] the checkbox starts checked" (Get-MenuItem $app "Notifications").Checked
    Invoke-MenuItem $app "About" | Out-Null
    Check "[$Backend] picking an item closes the menu" (Wait-Menu $app -Closed)
    Pause 1.0
    $log = @(Get-Texts $app | ? { $_ -match "^\d\d:\d\d:\d\d " } | % { $_.Substring(9) })
    Check "[$Backend] the item click arrives" ($log -contains 'menu item "about" #1') ($log -join " / ")
  }
  Press $app "Open, close in 2 s" 0.3
  Check "[$Backend] the menu opens again" (Wait-Menu $app)
  $closed = Wait-Menu $app -Closed -TimeoutSeconds 6
  Check "[$Backend] closeContextMenu closes it without a click" $closed
  if (-not $closed) { throw "the menu stayed open; leaving it for a person to close" }
  Pause 2.0
}

Assert-Idle
$app = Start-GuiApp (Get-FlutterExe "$RemoteWorkspace\examples\flutter_tray_icon_example") -MinViews 1
try {
  $now = Look $app
  Invoke-Activate $app $now.Win
  $now = Look $app
  $size = $now.View.size
  Check "window content is 400 x 640" ([math]::Round($size[0]) -eq 400 -and [math]::Round($size[1]) -eq 640) "$($size -join ' x ')"
  Check "starts on the asset icon" ((Get-TextLike $app "Asset icon*") -eq "Asset icon $Dot still")

  # -- animation: frames are rendered and pushed
  Press $app "Progress" 4.5
  $f = Get-FrameCount $app
  Check "Progress plays" ((Get-TextLike $app "Progress ?*") -eq "Progress $Dot playing") (Get-TextLike $app "Progress ?*")
  Check "about 30 frames a second reach the tray" ($f[0] -ge 100 -and $f[1] -ge 27) "$($f[0]) frames, $($f[1]) fps"
  # Reading the render tree stalls the UI thread for a moment, so a probe can cost a frame.
  $dropped = if ((Get-TextLike $app "dropped *") -match "^dropped (\d+) ") { [int]$Matches[1] } else { 999 }
  Check "next to no dropped frames" ($dropped -le 3) (Get-TextLike $app "dropped *")
  Check "frames are 36 px (2x)" ((Get-TextLike $app "render *") -like "*36?36 px") (Get-TextLike $app "render *")

  Press $app "Pause" 0.5
  $a = (Get-FrameCount $app)[0]; Pause 1.0; $b = (Get-FrameCount $app)[0]
  Check "Pause stops the frames" ($a -eq $b -and (Get-TextLike $app "Progress ?*") -eq "Progress $Dot paused") "$a -> $b"
  Press $app "Step" 0.5
  $c = (Get-FrameCount $app)[0]
  Check "Step renders exactly one frame" ($c -eq $b + 1) "$b -> $c"
  Press $app "Resume" 1.0
  Check "Resume continues" ((Get-FrameCount $app)[0] -gt $b + 5)

  Press $app "60 fps" 3.0
  $f = Get-FrameCount $app
  Check "60 fps is reached" ($f[1] -ge 54) "$($f[1]) fps"
  Press $app "3x" 1.0
  Check "3x renders 54 px frames" ((Get-TextLike $app "render *") -like "*54?54 px") (Get-TextLike $app "render *")
  Press $app "2x" 0.3
  Press $app "30 fps" 0.3

  Press $app "Any widget" 2.5
  $f = Get-FrameCount $app
  Check "a live widget is captured into frames" ($f[0] -ge 40 -and $f[1] -ge 24) "$($f[0]) frames, $($f[1]) fps"

  Press $app "Download" 1.5
  Press $app "Properties" 0.8
  # Windows tray icons have no title (SetTitle is a no-op there); the scene's tooltip shows.
  $tooltip = Get-TextLike $app "tooltip *"
  Check "the Download scene sets its tooltip" ($tooltip -eq 'tooltip "Downloading nativeapi.zip"') $tooltip
  Press $app "Animate" 0.5

  Press $app "Three icons" 2.0
  $chips = Get-Texts $app
  Check "three icons exist" (($chips -contains "#1") -and ($chips -contains "#2") -and ($chips -contains "#3"))
  $running = @()
  foreach ($n in "#1", "#2", "#3") { Press $app $n 1.2; $running += (Get-TextLike $app "* $Dot playing") }
  Check "each of the three plays its own animation" (($running -join "|") -eq "Spinner $Dot playing|Wave $Dot playing|Clock $Dot playing") ($running -join ", ")
  Press $app "Remove #3" 0.6
  Press $app "Remove #2" 0.6
  $chips = Get-Texts $app
  Check "removing leaves one icon" (($chips -notcontains "#2") -and ($chips -contains "#1"))
  Press $app "Stop" 1.0
  Check "Stop returns to the asset icon" ($null -ne (Get-TextLike $app "Asset icon*"))
  foreach ($kind in "Drawn", "Base64", "Asset") {
    Press $app $kind 0.8
    Check "the $kind still icon is set" ((Get-TextLike $app "$kind icon*") -eq "$kind icon $Dot still")
  }

  # -- properties read back from the native getters
  Press $app "Properties" 0.8
  Press $app $NiHao
  Check "setTitle is a harmless no-op on Windows" ((Get-TextLike $app "title *") -eq "title null") (Get-TextLike $app "title *")
  Press $app "2 lines"
  Check "a two-line tooltip reads back" ((Get-TextLike $app "tooltip *") -eq 'tooltip "Line one\nLine two"') (Get-TextLike $app "tooltip *")
  Press $app "Hidden"
  Check "setVisible(false) reads back" ((Get-TextLike $app "id *") -like "*visible false*") (Get-TextLike $app "id *")
  Press $app "Shown"
  Check "setVisible(true) reads back" ((Get-TextLike $app "id *") -like "*visible true*") (Get-TextLike $app "id *")
  Press $app "Double"
  Check "the trigger reads back" ((Get-TextLike $app "id *") -like "*trigger doubleClicked*") (Get-TextLike $app "id *")
  Press $app "Manual"
  Press $app "Refresh"
  $bounds = Get-TextLike $app "bounds *"
  Check "getBounds is a real rectangle" ($bounds -match '^bounds (-?\d+),(-?\d+) (\d+).(\d+) ' -and [int]$Matches[3] -gt 0 -and [int]$Matches[4] -gt 0) $bounds

  # -- the window goes next to the icon: above it, the tray being at the bottom here
  $before = (Look $app).Win
  Press $app "Window to icon" 1.5
  $after = (Look $app).Win
  $log = @(Get-Texts $app | ? { $_ -like "*window to icon #*" }) | Select-Object -First 1
  $icon = if ($bounds -match '^bounds (-?\d+),(-?\d+) (\d+).(\d+) ') { @([int]$Matches[1], [int]$Matches[2], [int]$Matches[3], [int]$Matches[4]) } else { @(0, 0, 0, 0) }
  Check "Window to icon places the window above the tray" ($log -like "*above*") $log
  Check "the window is centred on the icon, its bottom just above it" ([math]::Abs(($after.Left + $after.Right) / 2 - ($icon[0] + $icon[2] / 2)) -le 16 -and ($icon[1] - $after.Bottom) -ge -8 -and ($icon[1] - $after.Bottom) -le 24) "window $($after.Left),$($after.Top)-$($after.Right),$($after.Bottom), icon $($icon -join ',')"
  Check "the window moved towards the tray and stayed on screen" (($after.ClientX -ne $before.ClientX -or $after.ClientY -ne $before.ClientY) -and $after.ClientX -ge 0 -and $after.ClientY -ge 0) "client $($before.ClientX),$($before.ClientY) -> $($after.ClientX),$($after.ClientY), $bounds"

  # -- the menu, opened and closed from code, per backend
  $backends = @()
  if (@(Get-Texts $app) -contains "WinUI 3") { $backends += "WinUI 3" }
  $backends += "Native"
  foreach ($backend in $backends) {
    if (@(Get-Texts $app) -contains $backend) { Press $app $backend 0.8 }
    Test-Menu $app $backend
  }

  # -- the example's own checklist
  $status = Get-Checklist $app
  foreach ($item in "supported", "create", "menuOpenClose", "openMenu", "closeMenu", "visible", "readBack", "bounds", "frames") {
    $s = if ($status.ContainsKey($item)) { $status[$item] } else { @("open", "") }
    Check "checklist: $item" ($s[0] -eq "pass") "$($s[0]) $($s[1])"
  }
  $unexpected = @($status.Keys | ? { $status[$_][0] -eq "fail" -and $KnownFailures -notcontains $_ } | % { "$_ ($($status[$_][1]))" })
  Check "checklist: no unexpected failures" ($unexpected.Count -eq 0) ($unexpected -join ", ")
} catch {
  Check "ran to the end" $false "$_ (line $($_.InvocationInfo.ScriptLineNumber))"
} finally {
  Stop-GuiApp $app | Out-Null
}
Say "$script:Failures failure(s)"
exit $script:Failures
