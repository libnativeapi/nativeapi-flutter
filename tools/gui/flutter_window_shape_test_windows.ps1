# Real-input Windows validation of the polygonal Flutter window demo.
# Build a snapshot in $RemoteScratch\shape-flutter-767f456 first.
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"
. "$PSScriptRoot\winput.ps1"
. "$PSScriptRoot\guiapp.ps1"
Start-Result "$RemoteScratch\window-shapes-windows.result.txt"
Say "Starting Windows shaped-window validation"
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class ShapeProbe {
  [StructLayout(LayoutKind.Sequential)] public struct Point { public int X,Y; }
  [DllImport("user32.dll")] static extern int GetWindowRgn(IntPtr w, IntPtr r);
  [DllImport("gdi32.dll")] static extern IntPtr CreateRectRgn(int a,int b,int c,int d);
  [DllImport("gdi32.dll")] static extern bool PtInRegion(IntPtr r,int x,int y);
  [DllImport("gdi32.dll")] static extern bool DeleteObject(IntPtr o);
  [DllImport("user32.dll")] static extern IntPtr WindowFromPoint(Point p);
  [DllImport("user32.dll")] static extern IntPtr GetAncestor(IntPtr h,uint flags);
  public static int Kind(long w) {
    IntPtr r=CreateRectRgn(0,0,0,0);
    try { return GetWindowRgn(new IntPtr(w),r); } finally { DeleteObject(r); }
  }
  public static bool Contains(long w,int x,int y) {
    IntPtr r=CreateRectRgn(0,0,0,0);
    try { return GetWindowRgn(new IntPtr(w),r)!=0 && PtInRegion(r,x,y); }
    finally { DeleteObject(r); }
  }
  public static long RootAt(int x,int y) {
    return GetAncestor(WindowFromPoint(new Point {X=x,Y=y}),2).ToInt64();
  }
}
'@

function MainView($App) { Find-View (Get-Views $App) 'Beyond the rectangle' }
function Preview($App) { Get-Win $App 'Shape preview' }
function Press-Main($App, [string]$Text) {
  $w = Get-Win $App 'Window shapes'
  [WInput]::Raise($w.Hwnd); Pause 0.3
  $v = MainView $App
  Invoke-Click $App (ConvertTo-Screen $w (Get-TextCenter $v $Text))
  Pause 1
}
function Arrange($App) {
  $m = Get-Win $App 'Window shapes'
  [WInput]::Move($m.Hwnd,40,80)
  $m = Get-Win $App 'Window shapes'; $p = Preview $App
  $screen = [WInput]::Screen()
  [WInput]::Move($p.Hwnd,[int][math]::Min($m.Right+30,$screen[0]-($p.Right-$p.Left)-30),140)
  [WInput]::Raise($p.Hwnd); Pause 0.5
}
function In-Shape($Win,[double]$X,[double]$Y) {
  [ShapeProbe]::Contains($Win.Hwnd,
    [int]($Win.ClientX-$Win.Left+$X*$Win.ClientW),
    [int]($Win.ClientY-$Win.Top+$Y*$Win.ClientH))
}
function Capture-Preview($App,[string]$Name) {
  $p=Preview $App
  [WInput]::Raise($p.Hwnd); Pause 0.5
  $bitmap=New-Object System.Drawing.Bitmap ($p.Right-$p.Left),($p.Bottom-$p.Top)
  $graphics=[System.Drawing.Graphics]::FromImage($bitmap)
  try {
    $graphics.CopyFromScreen($p.Left,$p.Top,0,0,$bitmap.Size)
    $bitmap.Save("$RemoteScratch\shape-$Name.png",[System.Drawing.Imaging.ImageFormat]::Png)
  } finally { $graphics.Dispose(); $bitmap.Dispose() }
}

Assert-Idle
$app=$null
try {
  $project="$RemoteScratch\shape-flutter-767f456\examples\shaped_window_example"
  $app=Start-GuiApp (Get-FlutterExe $project)
  # The service can announce its URL before the main isolate and views exist.
  # Keep the process handle before probing, so any startup failure is cleaned up.
  $deadline=(Get-Date).AddSeconds(60)
  do {
    try { $ready=@(Get-Views $app).Count -ge 2 } catch { $ready=$false }
    if (-not $ready) { Pause 0.5 }
  } until ($ready -or (Get-Date) -gt $deadline)
  if (-not $ready) { throw 'Flutter did not expose two views within 60 seconds' }
  Arrange $app
  Invoke-Activate $app (Get-Win $app 'Window shapes')
  $count=0
  foreach ($shape in @('circle','star','bubble')) {
    Assert-Idle
    Press-Main $app $shape
    $p=Preview $app
    Check "$shape native region exists" ([ShapeProbe]::Kind($p.Hwnd) -gt 1) "DPI scale $($p.Scale)"
    Check "$shape centre included" (In-Shape $p 0.5 0.5)
    Check "$shape corner excluded" (-not (In-Shape $p 0.05 0.05))
    Check "$shape left contour" ((In-Shape $p 0.05 0.5) -eq ($shape -ne 'star'))
    Check "$shape bottom contour" ((In-Shape $p 0.5 0.9) -eq ($shape -eq 'circle'))
    $views=Get-Views $app
    $v=Find-View $views $shape
    # The main view also contains the shape name; select the square preview view.
    $v=$views | Where-Object { (Test-ViewText $_ $shape) -and [math]::Abs($_.size[0]-$_.size[1]) -lt 1 } | Select-Object -First 1
    Check "$shape Flutter label rendered" ($null -ne $v)
    [WInput]::Raise($p.Hwnd); Pause 0.3
    Invoke-Click $app (ConvertTo-Screen $p (Get-TextCenter $v 'Tap*' -Like))
    Pause 0.8
    $count++
    $texts=@(Get-ViewTexts (Get-Views $app) "^Counter: $count ")
    Check "$shape button responds" ($texts.Count -eq 1)
    Capture-Preview $app $shape
  }

  # A real mouse drag from the icon above the preview's shape label.
  $p=Preview $app
  $v=(Get-Views $app | Where-Object { (Test-ViewText $_ 'bubble') -and $_.size[0] -eq $_.size[1] } | Select-Object -First 1)
  $label=Get-TextCenter $v 'bubble'
  $grab=ConvertTo-Screen $p @($label[0],($label[1]-32))
  Invoke-Click $app $grab
  Pause 0.5
  $after=Preview $app
  Check 'click on drag handle does not move window' (($p.Left -eq $after.Left) -and ($p.Top -eq $after.Top))
  Invoke-Drag $app $grab @(@(($grab[0]+35),($grab[1]+15),400),@(($grab[0]+80),($grab[1]+50),600))
  Pause 1
  $after=Preview $app
  Check 'native drag moves shaped window' (([math]::Abs($after.Left-$p.Left-80) -le 6) -and ([math]::Abs($after.Top-$p.Top-50) -le 6)) "delta $($after.Left-$p.Left),$($after.Top-$p.Top)"

  Press-Main $app 'Toggle size'
  $p=Preview $app
  Check 'resized content is 400 logical pixels' (([math]::Abs($p.ClientW/$p.Scale-400) -lt 1) -and ([math]::Abs($p.ClientH/$p.Scale-400) -lt 1)) "$($p.ClientW/$p.Scale) x $($p.ClientH/$p.Scale)"
  Check 'shape reapplied after resize' ((In-Shape $p 0.5 0.5) -and -not (In-Shape $p 0.05 0.05))
  Capture-Preview $app 'resized'

  # Position an excluded corner over THIS APP's Restore button. The input guard
  # still owns every click, and GetAncestor identifies which of our windows won.
  $m=Get-Win $app 'Window shapes'
  $target=ConvertTo-Screen $m (Get-TextCenter (MainView $app) 'Restore rectangle')
  $p=Preview $app
  $dx=[int]($p.ClientX-$p.Left+0.05*$p.ClientW)
  $dy=[int]($p.ClientY-$p.Top+0.05*$p.ClientH)
  [WInput]::Move($p.Hwnd,($target[0]-$dx),($target[1]-$dy))
  [WInput]::Raise($p.Hwnd); Pause 0.5
  Check 'excluded corner hits underlying app window' ([ShapeProbe]::RootAt($target[0],$target[1]) -eq $m.Hwnd)
  Invoke-Click $app $target
  Pause 1
  $p=Preview $app
  Check 'click passes through corner and restores rectangle' ([ShapeProbe]::Kind($p.Hwnd) -eq 0)
  Check 'underlying button handled the click' (@(Get-ViewTexts (Get-Views $app) '^Rectangle restored$').Count -eq 1)
  [WInput]::Raise($p.Hwnd); Pause 0.3
  Check 'restored corner receives input again' ([ShapeProbe]::RootAt($target[0],$target[1]) -eq $p.Hwnd)
  Capture-Preview $app 'rectangle'
  Arrange $app
  Pause 1
  Capture-Preview $app 'rectangle-arranged'
  $p=Preview $app
  $v=(Get-Views $app | Where-Object { (Test-ViewText $_ 'bubble') -and $_.size[0] -eq $_.size[1] } | Select-Object -First 1)
  Invoke-Click $app (ConvertTo-Screen $p (Get-TextCenter $v 'Tap*' -Like))
  Pause 1
  Capture-Preview $app 'rectangle-clicked'
  Check 'restored rectangle button responds' (@(Get-ViewTexts (Get-Views $app) '^Counter: 4 ').Count -eq 1)
  Press-Main $app 'Apply shape'
  Check 'shape can be reapplied after clear' ([ShapeProbe]::Kind((Preview $app).Hwnd) -gt 1)
  Check 'counter survived shaping and resizing' (@(Get-ViewTexts (Get-Views $app) '^Counter: 4 ').Count -eq 1)
  Check 'no Flutter framework exceptions' (-not ((Get-Content $app.Log -Raw) -match 'EXCEPTION CAUGHT'))
} catch {
  Say "ERROR: $_"
  throw
} finally {
  if ($app) { Stop-GuiApp $app | Out-Null; Say "App log: $($app.Log)" }
}
Say "Failures: $script:Failures"
exit $script:Failures
