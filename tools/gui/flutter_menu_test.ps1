# GUI test (Windows) of menu_example: the context menu opens where it is asked to (click
# point, placement, absolute position, cursor), shows the item types and states the example
# set (checkbox, radio group, disabled, submenu, special characters), fires click and
# open/close events for the right items only, and reflects changes made while closed (label,
# added item, detached submenu). Runs once per menu backend: WinUI 3 (when supported), then
# Native (Win32). Built on the gui-test skill; takes over the mouse for ~3 min.
# Run (remote-hosts skill):  remote.sh <host> setup; remote.sh <host> desktop tools/gui/flutter_menu_test.ps1 400
# ASCII only: the special-characters item is matched by its prefix.
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\env.ps1"; . "$PSScriptRoot\winput.ps1"; . "$PSScriptRoot\guiapp.ps1"
Start-Result "$RemoteScratch\flutter_menu_test.result.txt"

$Region = "Right-click here"
$Items = @("Normal Menu Item", "Checkbox Item", "Radio Option 1", "Radio Option 2", "Radio Option 3",
  "Disabled Item", "Disabled Checkbox", "Dynamic Label Item", "Item with Tooltip", "Submenu", "Special: *")
$SubItems = @("Submenu Item 1", "Submenu Item 2", "Submenu Item 3")
$Positioning = @("Positioning Menu Item 1", "Positioning Menu Item 2")
# The lower sections of the scrolling left column must be in sight (the probe does not apply
# scroll offsets): the window is made this tall (logical px), capped by the work area.
$WantHeight = 1000
# A menu frame may sit a few px off the requested corner (flyout margins, shadows); physical px.
$Pad = 8

# -- looking (never while a menu is open) --------------------------------------
function Look($app) {
  if (@(Get-OpenMenus $app).Count) { throw "a menu is still open; refusing to probe" }
  $win = Get-Wins $app | ? { $_.Title -eq "menu_example" } | Select-Object -First 1
  $view = Find-View (Get-Views $app) $Region
  if (-not $win -or -not $view) { throw "the example window is not there" }
  @{ Win = $win; View = $view }
}
function Get-History($app) {
  # "[hh:mm:ss] message", newest first; returns the messages.
  $l = Look $app
  @($l.View.texts | % { $_[0] } | ? { $_ -match '^\[\d\d:\d\d:\d\d\] ' } | % { $_.Substring(11) })
}
function Get-Info($app, [string]$Label) {
  $l = Look $app
  $r = ($l.View.texts | ? { $_[0] -eq $Label } | Select-Object -First 1)[1]
  $below = @($l.View.texts | ? { [math]::Abs($_[1][0] - $r[0]) -lt 2 -and $_[1][1] -ge $r[1] + $r[3] - 1 -and $_[1][1] -lt $r[1] + $r[3] + 30 } | Sort-Object { $_[1][1] })
  if ($below.Count) { $below[0][0] } else { $null }
}
function Invoke-Button($app, [string]$Label) {
  $l = Look $app
  $pt = ConvertTo-Screen $l.Win (Get-TextCenter $l.View $Label)
  if ($pt[1] -ge $l.Win.ClientY + $l.Win.ClientH - 10) { throw "button '$Label' is out of sight" }
  Invoke-Click $app $pt
  Pause 0.8
  return $pt
}
# Picks an entry of a Flutter DropdownButton: opens it at its current value, then clicks the
# entry in the list (the button itself holds every entry at its own position).
function Select-Dropdown($app, [string]$Current, [string]$Choice) {
  $l = Look $app
  $at = Get-TextCenter $l.View $Current
  Invoke-Click $app (ConvertTo-Screen $l.Win $at)
  Pause 1
  $l = Look $app
  $hit = $l.View.texts | ? { $_[0] -eq $Choice -and [math]::Abs(($_[1][1] + $_[1][3] / 2) - $at[1]) -gt 4 } | Select-Object -First 1
  if (-not $hit) { throw "the list with '$Choice' did not open" }
  Invoke-Click $app (ConvertTo-Screen $l.Win @(($hit[1][0] + $hit[1][2] / 2), ($hit[1][1] + $hit[1][3] / 2)))
  Pause 1
}

# -- menus ---------------------------------------------------------------------
function Get-TopItems($app, [int]$Depth = 0) { @(Get-OpenMenus $app | ? { $_.Depth -eq $Depth } | % { $_.Items }) }
function Get-TopMenu($app) { Get-OpenMenus $app | ? { $_.Depth -eq 0 } | Select-Object -First 1 }
function Open-ContextMenu($app) {
  $l = Look $app
  $pt = ConvertTo-Screen $l.Win (Get-TextCenter $l.View $Region)
  Invoke-RightClick $app $pt
  if (-not (Wait-Menu $app)) { throw "the context menu did not open" }
  Pause 0.4
  return $pt
}
function Test-ItemTitles($actual, $expected) {
  if ($actual.Count -ne $expected.Count) { return $false }
  for ($i = 0; $i -lt $actual.Count; $i++) { if ($actual[$i] -notlike $expected[$i]) { return $false } }
  return $true
}
# Closes the menus with a click on the app's own window, clear of every menu.
function Close-Menus($app, $safeDy) {
  $menus = @(Get-OpenMenus $app)
  $win = Get-Wins $app | ? { $_.Title -eq "menu_example" } | Select-Object -First 1
  $cands = @(@(($win.Left + [int](($win.Right - $win.Left) / 2)), ($win.Top + [int](($win.ClientY - $win.Top) / 2))),
             @(($win.Right - 40), ($win.ClientY + $safeDy)),
             @(($win.Left + 90), ($win.Top + [int](($win.ClientY - $win.Top) / 2))))
  foreach ($c in $cands) {
    $clear = $true
    foreach ($m in $menus) {
      $r = $m.Rect
      if ($c[0] -ge $r[0] - 20 -and $c[0] -le $r[0] + $r[2] + 20 -and $c[1] -ge $r[1] - 20 -and $c[1] -le $r[1] + $r[3] + 20) { $clear = $false }
    }
    if ($clear) {
      Invoke-Click $app $c
      $closed = Wait-Menu $app -Closed
      Pause 0.6
      return $closed
    }
  }
  throw "no free spot outside the menus to dismiss them"
}
function Invoke-Pick($app, [string]$Title, [int]$Depth = 0) {
  Invoke-MenuItem $app $Title $Depth | Out-Null
  $closed = Wait-Menu $app -Closed
  Pause 0.8
  return $closed
}
# Opens the "Submenu" item's submenu by hovering it. WinUI 3 flyouts did not open a sub item
# on synthetic hover in our runs, only on a click: that is reported as a NOTE, then clicked.
function Open-Submenu($app, [string]$Backend) {
  $parent = Invoke-HoverMenuItem $app "Submenu" 0
  if (Wait-Menu $app -Depth 1 -TimeoutSeconds 2) { return @{ Parent = $parent; How = "hover" } }
  if ($Backend -ne "WinUI 3") { return $null }
  Say "NOTE [$Backend] hovering 'Submenu' did not open it; clicking it"
  $pt = Get-RectCenter $parent.Rect
  [WInput]::Click($pt[0], $pt[1])
  if (Wait-Menu $app -Depth 1) { return @{ Parent = (Get-MenuItem $app "Submenu" 0); How = "click" } }
  return $null
}
function Test-Starts($list, [string]$Prefix) { @($list | ? { $_.StartsWith($Prefix) }).Count -gt 0 }

function Invoke-Scenario($app, [string]$Backend) {
  Say "--- backend: $Backend ---"
  $l = Look $app
  # The empty right end of the history header, from the client top: stays valid when the window moves.
  $safeY = (ConvertTo-Screen $l.Win (Get-TextCenter $l.View "Event History*" -Like))[1] - $l.Win.ClientY

  # 1. Right click opens the menu at the click point (placement Bottom Start).
  $pt = Open-ContextMenu $app
  $top = Get-TopMenu $app
  $titles = @($top.Items | % { $_.Title })
  Check "[$Backend] context menu shows the example items in order" (Test-ItemTitles $titles $Items) ($titles -join ", ")
  Check "[$Backend] menu top-left is at the click point (Bottom Start)" ([math]::Abs($top.Rect[0] - $pt[0]) -le $Pad -and [math]::Abs($top.Rect[1] - $pt[1]) -le $Pad) "menu at $($top.Rect[0]),$($top.Rect[1]), click at $pt"
  $by = @{}; foreach ($i in $top.Items) { $by[$i.Title] = $i }
  Check "[$Backend] checkbox starts unchecked" (-not $by["Checkbox Item"].Checked)
  $marks = @(1, 2, 3 | % { $by["Radio Option $_"].Checked })
  Check "[$Backend] radio group starts on option 1" (($marks -join ",") -eq "True,False,False") ($marks -join ",")
  $disabled = @($top.Items | ? { -not $_.Enabled } | % { $_.Title })
  Check "[$Backend] disabled items are disabled, the rest enabled" (($disabled -join ",") -eq "Disabled Item,Disabled Checkbox") ($disabled -join ",")
  Check "[$Backend] disabled checkbox keeps its checked state" $by["Disabled Checkbox"].Checked
  $subs = @($top.Items | ? { $_.HasSubmenu } | % { $_.Title })
  Check "[$Backend] only 'Submenu' has a submenu" (($subs -join ",") -eq "Submenu") ($subs -join ",")

  # 2. Clicking an item fires its event and closes the menu.
  Check "[$Backend] menu closes after a click" (Invoke-Pick $app "Normal Menu Item")
  $h = Get-History $app
  Check "[$Backend] item click event" (Test-Starts $h "Normal item clicked") ($h[0..3] -join " / ")
  Check "[$Backend] menu opened and closed events" ((Test-Starts $h "Menu opened") -and (Test-Starts $h "Menu closed")) ($h[0..3] -join " / ")

  # 3. Checkbox: the app flips the state; the menu shows it the next time.
  Open-ContextMenu $app | Out-Null
  Invoke-Pick $app "Checkbox Item" | Out-Null
  $v = Get-Info $app "Checkbox"
  Check "[$Backend] checkbox click reaches the app" ($v -eq "true") $v
  Open-ContextMenu $app | Out-Null
  Check "[$Backend] checkbox shows checked on reopen" (Get-MenuItem $app "Checkbox Item" 0).Checked
  Invoke-Pick $app "Checkbox Item" | Out-Null
  $v = Get-Info $app "Checkbox"
  Check "[$Backend] second click unchecks it" ($v -eq "false") $v

  # 4. Radio group: exactly one option checked.
  Open-ContextMenu $app | Out-Null
  Invoke-Pick $app "Radio Option 3" | Out-Null
  $v = Get-Info $app "Radio"
  Check "[$Backend] radio selection reaches the app" ($v -eq "Option 3") $v
  Open-ContextMenu $app | Out-Null
  $marks = @(1, 2, 3 | % { (Get-MenuItem $app "Radio Option $_" 0).Checked })
  Check "[$Backend] only option 3 is checked on reopen" (($marks -join ",") -eq "False,False,True") ($marks -join ",")
  Invoke-Pick $app "Radio Option 1" | Out-Null
  $v = Get-Info $app "Radio"
  Check "[$Backend] back to option 1" ($v -eq "Option 1") $v

  # 5. A disabled item does nothing.
  Open-ContextMenu $app | Out-Null
  Invoke-MenuItem $app "Disabled Item" 0 | Out-Null
  Pause 0.8
  $stillOpen = @(Get-OpenMenus $app).Count -gt 0
  Check "[$Backend] clicking a disabled item leaves the menu open" $stillOpen
  if ($stillOpen) { Check "[$Backend] dismissed by a click outside" (Close-Menus $app $safeY) }
  $h = Get-History $app
  Check "[$Backend] disabled item fires no click" (@($h | ? { $_ -like "*should not fire*" }).Count -eq 0) ($h[0..3] -join " / ")

  # 6. Dismissing without picking fires close but no click.
  $clicks = @(Get-History $app | ? { $_ -like "*clicked*" }).Count
  Open-ContextMenu $app | Out-Null
  Check "[$Backend] click outside closes the menu" (Close-Menus $app $safeY)
  $h = Get-History $app
  Check "[$Backend] dismiss fires 'Menu closed'" ($h[0].StartsWith("Menu closed")) ($h[0..2] -join " / ")
  Check "[$Backend] dismiss fires no item click" (@($h | ? { $_ -like "*clicked*" }).Count -eq $clicks)

  # 7. Submenu: hovering opens it beside its item (see Open-Submenu); its items fire their own events.
  Open-ContextMenu $app | Out-Null
  $sm = Open-Submenu $app $Backend
  $opened = [bool]$sm
  Check "[$Backend] 'Submenu' opens its submenu$(if ($sm) { " ($($sm.How))" })" $opened
  if ($opened) {
    $parent = $sm.Parent
    Pause 0.4
    $sub = @(Get-TopItems $app 1)
    Check "[$Backend] submenu items" (Test-ItemTitles @($sub | % { $_.Title }) $SubItems) (($sub | % { $_.Title }) -join ", ")
    $p = $parent.Rect; $s = $sub[0].Rect
    Check "[$Backend] submenu opens to the right of its item, level with it" ($s[0] -ge $p[0] + $p[2] - $Pad -and [math]::Abs($s[1] - $p[1]) -le 2 * $Pad) "parent $p, first subitem $s"
    # Slide right along the parent's row first, so the submenu stays open.
    Move-Cursor @(((Get-RectCenter $s)[0]), ((Get-RectCenter $p)[1])) 350
    Check "[$Backend] submenu item click closes all menus" (Invoke-Pick $app "Submenu Item 2" 1)
    $h = Get-History $app
    Check "[$Backend] submenu item click event" (Test-Starts $h "Submenu Item 2 clicked") ($h[0..4] -join " / ")
    Check "[$Backend] submenu opened/closed events" ((Test-Starts $h "Submenu opened") -and (Test-Starts $h "Submenu closed")) ($h[0..4] -join " / ")
  } else { Close-Menus $app $safeY | Out-Null }

  # 8. Placement: Top End puts the menu's bottom-right corner at the click point. The window
  #    moves to the bottom of the work area first, so there is room above the click point.
  $w0 = Get-Wins $app | ? { $_.Title -eq "menu_example" } | Select-Object -First 1
  $low = [int](700 * $w0.Scale)
  [WInput]::SetBounds($w0.Hwnd, $w0.Left, ($area.Bottom - $low), ($w0.Right - $w0.Left), $low)
  Pause 1
  Select-Dropdown $app "Bottom Start" "Top End"
  $h = Get-History $app
  Check "[$Backend] placement changed" (Test-Starts $h "Placement changed to: topEnd") ($h[0..1] -join " / ")
  $pt = Open-ContextMenu $app
  $r = (Get-TopMenu $app).Rect
  Check "[$Backend] menu bottom-right is at the click point (Top End)" ([math]::Abs($r[0] + $r[2] - $pt[0]) -le $Pad -and [math]::Abs($r[1] + $r[3] - $pt[1]) -le $Pad) "menu ends at $($r[0] + $r[2]),$($r[1] + $r[3]), click at $pt"
  Close-Menus $app $safeY | Out-Null

  # 9. Changes made while the menu is closed show up on the next open (placement is still
  #    Top End, so this also checks that it uses the menu's new size).
  Invoke-Button $app "Update Label" | Out-Null
  $newLabel = (Get-History $app | ? { $_.StartsWith("Menu item label changed to: ") } | Select-Object -First 1) -replace "^Menu item label changed to: ", ""
  Invoke-Button $app "Add Item" | Out-Null
  $count = Get-Info $app "Items"
  Invoke-Button $app "Detach Submenu" | Out-Null
  $pt = Open-ContextMenu $app
  $titles = @(Get-TopItems $app | % { $_.Title })
  $r = (Get-TopMenu $app).Rect
  Check "[$Backend] Top End still exact after the menu changed" ([math]::Abs($r[0] + $r[2] - $pt[0]) -le $Pad -and [math]::Abs($r[1] + $r[3] - $pt[1]) -le $Pad) "menu ends at $($r[0] + $r[2]),$($r[1] + $r[3]), click at $pt"
  Check "[$Backend] updated label is shown" (($titles -contains $newLabel) -and -not ($titles -contains "Dynamic Label Item")) "'$newLabel' in $($titles -join ', ')"
  Check "[$Backend] added item is appended" ($titles[-1] -like "New Item *") $titles[-1]
  Check "[$Backend] detached submenu leaves a plain item" (-not (Get-MenuItem $app "Submenu" 0).HasSubmenu)
  Invoke-Pick $app $titles[-1] | Out-Null
  $h = Get-History $app
  Check "[$Backend] added item fires its click" (Test-Starts $h "New item") ($h[0..2] -join " / ")
  Check "[$Backend] item count matches the app" ([int]$count -eq $titles.Count + 4) "app says $count, menu shows $($titles.Count) items + 4 separators"
  Invoke-Button $app "Detach Submenu" | Out-Null  # attach it again
  Open-ContextMenu $app | Out-Null
  Check "[$Backend] re-attached submenu is back" (Get-MenuItem $app "Submenu" 0).HasSubmenu
  $sm = Open-Submenu $app $Backend
  $sub = if ($sm) { @(Get-TopItems $app 1 | % { $_.Title }) } else { @() }
  Check "[$Backend] re-attached submenu still shows its items" (Test-ItemTitles $sub $SubItems) ($sub -join ", ")
  Close-Menus $app $safeY | Out-Null
  Select-Dropdown $app "Top End" "Bottom Start"
  [WInput]::SetBounds($w0.Hwnd, $w0.Left, $w0.Top, ($w0.Right - $w0.Left), ($w0.Bottom - $w0.Top))
  Pause 1

  # 10. Absolute position and cursor position (the positioning menu).
  Invoke-Button $app "Pos (300,200)" | Out-Null
  if (Wait-Menu $app) {
    Pause 0.4
    $top = Get-TopMenu $app
    $titles = @($top.Items | % { $_.Title })
    Check "[$Backend] positioning menu items" (Test-ItemTitles $titles $Positioning) ($titles -join ", ")
    # Absolute positions are logical: scaled by the screen's DPI.
    $s = $l.Win.Scale
    Check "[$Backend] absolute position (300, 200)" ([math]::Abs($top.Rect[0] - 300 * $s) -le $Pad -and [math]::Abs($top.Rect[1] - 200 * $s) -le $Pad) "menu at $($top.Rect[0]),$($top.Rect[1]); scale $s"
    Invoke-Pick $app "Positioning Menu Item 2" | Out-Null
    $h = Get-History $app
    Check "[$Backend] positioning item click" ($h -contains "Positioning menu item 2 clicked") ($h[0..2] -join " / ")
  } else { Check "[$Backend] positioning menu opens at (300, 200)" $false }

  $pt = Invoke-Button $app "At Cursor"
  if (Wait-Menu $app) {
    Pause 0.4
    $r = (Get-TopMenu $app).Rect
    # A menu that would cross the bottom of the work area is lifted to fit.
    Check "[$Backend] menu opens at the cursor" ([math]::Abs($r[0] - $pt[0]) -le $Pad -and $pt[1] -ge $r[1] - $Pad -and $pt[1] -le $r[1] + $r[3]) "menu $r, cursor at $pt"
    Close-Menus $app $safeY | Out-Null
    $h = Get-History $app
    Check "[$Backend] positioning menu closed event" ($h[0..2] -contains "Positioning menu closed") ($h[0..2] -join " / ")
  } else { Check "[$Backend] menu opens at the cursor" $false }
}

Assert-Idle
$app = Start-GuiApp (Get-FlutterExe "$RemoteWorkspace\bindings\flutter\examples\menu_example") -MinViews 1
try {
  $win = Get-Wins $app | ? { $_.Title -eq "menu_example" } | Select-Object -First 1
  $area = [System.Windows.Forms.Screen]::FromHandle([IntPtr]$win.Hwnd).WorkingArea
  $height = [math]::Min([int]($WantHeight * $win.Scale), $area.Height - 20)
  [WInput]::SetBounds($win.Hwnd, $area.Left + 10, $area.Top + 10, [int](1100 * $win.Scale), $height)
  Pause 1
  $win = Get-Wins $app | ? { $_.Title -eq "menu_example" } | Select-Object -First 1
  Invoke-Activate $app $win
  # The example starts on WinUI 3 where it is supported: a Win32 menu is a #32768 window.
  Open-ContextMenu $app | Out-Null
  $winui = @(Get-AppWindows $app.Proc.Id | ? { [WInput]::ClassOf($_.Hwnd) -eq "#32768" }).Count -eq 0
  Close-Menus $app 200 | Out-Null
  Invoke-Scenario $app $(if ($winui) { "WinUI 3" } else { "Native" })
  if ($winui) {
    # Restart for a clean menu state, then switch the backend.
    Stop-GuiApp $app | Out-Null
    $app = Start-GuiApp (Get-FlutterExe "$RemoteWorkspace\bindings\flutter\examples\menu_example") -MinViews 1
    $win = Get-Wins $app | ? { $_.Title -eq "menu_example" } | Select-Object -First 1
    [WInput]::SetBounds($win.Hwnd, $area.Left + 10, $area.Top + 10, [int](1100 * $win.Scale), $height)
    Pause 1
    $win = Get-Wins $app | ? { $_.Title -eq "menu_example" } | Select-Object -First 1
    Invoke-Activate $app $win
    Select-Dropdown $app "WinUI 3" "Native"
    $h = Get-History $app
    Check "switched to the Native backend" (Test-Starts $h "Backend native: context=true") ($h[0..1] -join " / ")
    Invoke-Scenario $app "Native"
  }
} catch {
  Check "ran to the end" $false "$_ at line $($_.InvocationInfo.ScriptLineNumber)"
} finally {
  Stop-GuiApp $app | Out-Null
}
Say "$script:Failures failure(s)"
exit $script:Failures
