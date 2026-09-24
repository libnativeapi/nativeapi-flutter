# Windows desktop integration test: select each theme in Flutter and inspect the
# rendered native menu. Build with WinUI 3 enabled, or pass -NativeOnly.
# No OS preferences are changed.
# remote.sh win desktop tools/gui/flutter_menu_theme_test.ps1 300
param([string]$Exe = '', [switch]$KeepOpen, [switch]$NativeOnly)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"
. "$PSScriptRoot\winput.ps1"
. "$PSScriptRoot\guiapp.ps1"
if (-not $Exe) { $Exe = "$RemoteWorkspace\examples\flutter_menu_example\build\windows\x64\runner\Debug\menu_example.exe" }
Start-Result "$RemoteScratch\flutter_menu_theme_test.result.txt"
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class MenuThemePixel {
  [DllImport("user32.dll")] static extern IntPtr GetDC(IntPtr window);
  [DllImport("user32.dll")] static extern int ReleaseDC(IntPtr window, IntPtr dc);
  [DllImport("gdi32.dll")] static extern uint GetPixel(IntPtr dc, int x, int y);
  public static uint Read(int x, int y) {
    var dc = GetDC(IntPtr.Zero);
    try { return GetPixel(dc, x, y); }
    finally { ReleaseDC(IntPtr.Zero, dc); }
  }
}
'@
function Look {
  if (@(Get-OpenMenus $app).Count) { throw 'Close the native menu before probing Flutter.' }
  $win = Get-Win $app 'menu_example'
  $view = Find-View (Get-Views $app) 'Right-click here'
  if (-not $win -or -not $view) { throw 'Flutter example is not visible.' }
  @{ Win = $win; View = $view }
}
function Select-Value([string]$Current, [string]$Choice) {
  $l = Look
  $at = Get-TextCenter $l.View $Current
  Invoke-Click $app (ConvertTo-Screen $l.Win $at)
  Pause 0.6
  $l = Look
  $hit = $l.View.texts | Where-Object {
    $_[0] -eq $Choice -and [math]::Abs(($_[1][1] + $_[1][3] / 2) - $at[1]) -gt 4
  } | Select-Object -First 1
  if (-not $hit) { throw "Dropdown option $Choice not found." }
  Invoke-Click $app (ConvertTo-Screen $l.Win @(($hit[1][0] + $hit[1][2] / 2), ($hit[1][1] + $hit[1][3] / 2)))
  Pause 0.8
}
Assert-Idle
$app = Start-GuiApp $Exe -MinViews 1
try {
  $l = Look
  Invoke-Activate $app $l.Win
  $l = Look
  $backends = if ($NativeOnly) { @('Native') } else { @('WinUI 3', 'Native') }
  $currentTheme = 'System'
  foreach ($backend in $backends) {
    if ($backend -eq 'Native' -and $backends.Count -gt 1) { Select-Value 'WinUI 3' 'Native' }
    foreach ($choice in @('Dark', 'Light', 'System')) {
      Select-Value $currentTheme $choice
      $currentTheme = $choice
      $l = Look
      $pattern = '*Theme: ' + $choice.ToLowerInvariant() + '; native appearance applied: true'
      Check "$backend / ${choice}: theme applied" (@($l.View.texts | Where-Object { $_[0] -like $pattern }).Count -gt 0)
      Invoke-RightClick $app (ConvertTo-Screen $l.Win (Get-TextCenter $l.View 'Right-click here'))
      if (-not (Wait-Menu $app)) { throw "$backend menu failed to open." }
      Pause 0.6
      $item = Get-MenuItem $app 'Normal Menu Item' 0
      $x = [int]($item.Rect[0] + $item.Rect[2] - 20)
      $y = [int]($item.Rect[1] + $item.Rect[3] / 2)
      $color = [MenuThemePixel]::Read($x, $y)
      $red = $color -band 255; $green = ($color -shr 8) -band 255; $blue = ($color -shr 16) -band 255
      $dark = $red -lt 128 -and $green -lt 128 -and $blue -lt 128
      $expectedDark = if ($choice -eq 'System') {
        (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize').AppsUseLightTheme -eq 0
      } else { $choice -eq 'Dark' }
      Check "$backend / ${choice}: menu background" ($color -ne [uint32]::MaxValue -and $dark -eq $expectedDark) "RGB=$red,$green,$blue"
      Invoke-MenuItem $app 'Normal Menu Item' 0 | Out-Null
      if (-not (Wait-Menu $app -Closed)) { throw 'Menu did not close after selection.' }
      Pause 0.5
    }
  }
} finally {
  if (-not $KeepOpen) { Stop-GuiApp $app | Out-Null }
}
Say "$script:Failures failure(s)"
exit $script:Failures
