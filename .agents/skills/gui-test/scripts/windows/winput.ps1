# Dot-source in a script running on the interactive desktop.
# All coordinates are physical pixels (the process is per-monitor DPI aware).
Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

public static class WInput {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
  [StructLayout(LayoutKind.Sequential)] struct MOUSEINPUT { public int dx, dy; public uint data, flags, time; public IntPtr extra; }
  [StructLayout(LayoutKind.Sequential)] struct INPUT { public uint type; public MOUSEINPUT mi; }
  delegate bool EnumProc(IntPtr h, IntPtr l);

  [DllImport("user32.dll")] static extern bool SetProcessDpiAwarenessContext(IntPtr v);
  [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc p, IntPtr l);
  [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] static extern bool ClientToScreen(IntPtr h, ref POINT p);
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] static extern IntPtr WindowFromPoint(POINT p);
  [DllImport("user32.dll")] static extern IntPtr GetAncestor(IntPtr h, uint flags);
  [DllImport("user32.dll")] static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] static extern bool GetCursorPos(out POINT p);
  [DllImport("user32.dll")] static extern uint SendInput(uint n, INPUT[] inputs, int size);
  [DllImport("user32.dll")] static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] static extern uint GetDpiForWindow(IntPtr h);
  [DllImport("user32.dll")] static extern bool AllowSetForegroundWindow(int pid);
  [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);

  [DllImport("user32.dll")] static extern int GetSystemMetrics(int i);

  public static void Init() { SetProcessDpiAwarenessContext(new IntPtr(-4)); }

  // Size of the primary screen.
  public static int[] Screen() { return new[] { GetSystemMetrics(0), GetSystemMetrics(1) }; }

  // "hwnd|title|l t r b|client l t w h|dpi" for each visible top-level window of pid.
  public static string[] Windows(int pid) {
    var list = new List<string>();
    EnumWindows((h, l) => {
      uint p; GetWindowThreadProcessId(h, out p);
      if (p == pid && IsWindowVisible(h)) {
        var sb = new StringBuilder(256); GetWindowText(h, sb, 256);
        RECT r; GetWindowRect(h, out r);
        RECT c; GetClientRect(h, out c);
        var o = new POINT(); ClientToScreen(h, ref o);
        list.Add(h.ToInt64() + "|" + sb + "|" + r.L + " " + r.T + " " + r.R + " " + r.B + "|" +
                 o.X + " " + o.Y + " " + c.R + " " + c.B + "|" + GetDpiForWindow(h));
      }
      return true;
    }, IntPtr.Zero);
    return list.ToArray();
  }

  public static int Owner(int x, int y) {
    var p = new POINT { X = x, Y = y };
    IntPtr h = GetAncestor(WindowFromPoint(p), 2 /* GA_ROOT */);
    uint pid; GetWindowThreadProcessId(h, out pid);
    return (int)pid;
  }

  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetClassName(IntPtr h, StringBuilder s, int n);

  public static string ClassOf(long hwnd) {
    var sb = new StringBuilder(128); GetClassName(new IntPtr(hwnd), sb, 128);
    return sb.ToString();
  }

  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)] struct MENUITEMINFO {
    public int cbSize; public uint fMask, fType, fState, wID; public IntPtr hSubMenu, hbmpChecked, hbmpUnchecked, dwItemData;
    public string dwTypeData; public uint cch; public IntPtr hbmpItem;
  }
  [DllImport("user32.dll")] static extern IntPtr SendMessage(IntPtr h, uint msg, IntPtr w, IntPtr l);
  [DllImport("user32.dll")] static extern int GetMenuItemCount(IntPtr m);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern bool GetMenuItemInfo(IntPtr m, uint item, bool byPos, ref MENUITEMINFO mii);
  [DllImport("user32.dll")] static extern bool GetMenuItemRect(IntPtr h, IntPtr m, uint item, out RECT r);

  // Items of the popup menu shown by a #32768 window: "title|l t w h|flags", flags:
  // e enabled, c checked, s submenu, - separator. The title drops a "\t<accelerator>" suffix.
  public static string[] MenuItems(long hwnd) {
    var list = new List<string>();
    IntPtr menu = SendMessage(new IntPtr(hwnd), 0x01E1 /* MN_GETHMENU */, IntPtr.Zero, IntPtr.Zero);
    if (menu == IntPtr.Zero) return list.ToArray();
    int n = GetMenuItemCount(menu);
    for (uint i = 0; i < n; i++) {
      var mii = new MENUITEMINFO();
      mii.cbSize = Marshal.SizeOf(typeof(MENUITEMINFO));
      mii.fMask = 0x0001 | 0x0004 | 0x0100 | 0x0040;  // STATE | SUBMENU | FTYPE | STRING
      mii.dwTypeData = new string('\0', 512); mii.cch = 511;
      string title = "";
      if (GetMenuItemInfo(menu, i, true, ref mii) && mii.dwTypeData != null) {
        title = mii.dwTypeData;
        int nul = title.IndexOf('\0'); if (nul >= 0) title = title.Substring(0, nul);
        int tab = title.IndexOf('\t'); if (tab >= 0) title = title.Substring(0, tab);
      }
      RECT r; GetMenuItemRect(IntPtr.Zero, menu, i, out r);
      string flags = "";
      if ((mii.fState & 0x0003) == 0) flags += "e";  // not MFS_DISABLED / MFS_GRAYED
      if ((mii.fState & 0x0008) != 0) flags += "c";  // MFS_CHECKED
      if (mii.hSubMenu != IntPtr.Zero) flags += "s";
      if ((mii.fType & 0x0800) != 0) flags += "-";   // MFT_SEPARATOR
      list.Add(title + "|" + r.L + " " + r.T + " " + (r.R - r.L) + " " + (r.B - r.T) + "|" + flags);
    }
    return list.ToArray();
  }

  public static string RootClass(int x, int y) {
    var p = new POINT { X = x, Y = y };
    IntPtr h = GetAncestor(WindowFromPoint(p), 2);
    var sb = new StringBuilder(128); GetClassName(h, sb, 128);
    return sb.ToString();
  }

  public static int ForegroundPid() {
    uint pid; GetWindowThreadProcessId(GetForegroundWindow(), out pid);
    return (int)pid;
  }

  public static void Focus(long hwnd) { SetForegroundWindow(new IntPtr(hwnd)); }

  public static void Move(long hwnd, int x, int y) {
    SetWindowPos(new IntPtr(hwnd), IntPtr.Zero, x, y, 0, 0, 0x0015 /* NOSIZE|NOZORDER|NOACTIVATE */);
  }

  public static void SetBounds(long hwnd, int x, int y, int w, int h) {
    SetWindowPos(new IntPtr(hwnd), IntPtr.Zero, x, y, w, h, 0x0014 /* NOZORDER|NOACTIVATE */);
  }

  // Brings a window to the top of the z-order without activating it.
  public static void Raise(long hwnd) {
    var h = new IntPtr(hwnd);
    SetWindowPos(h, new IntPtr(-1) /* TOPMOST */, 0, 0, 0, 0, 0x0013 /* NOSIZE|NOMOVE|NOACTIVATE */);
    SetWindowPos(h, new IntPtr(-2) /* NOTOPMOST */, 0, 0, 0, 0, 0x0013);
  }

  public static int[] Pos() { POINT p; GetCursorPos(out p); return new[] { p.X, p.Y }; }

  static void Button(uint flag) {
    var i = new INPUT[1];
    i[0].type = 0; i[0].mi.flags = flag;
    SendInput(1, i, Marshal.SizeOf(typeof(INPUT)));
  }

  static double Ease(double t) { return t < 0.5 ? 4 * t * t * t : 1 - Math.Pow(-2 * t + 2, 3) / 2; }

  public static void Glide(int x, int y, int ms) {
    var from = Pos();
    int steps = Math.Max(1, ms / 8);
    for (int i = 1; i <= steps; i++) {
      double t = Ease((double)i / steps);
      SetCursorPos((int)Math.Round(from[0] + (x - from[0]) * t), (int)Math.Round(from[1] + (y - from[1]) * t));
      // A relative zero move turns the SetCursorPos jump into a real mouse-move message.
      var inp = new INPUT[1]; inp[0].type = 0; inp[0].mi.flags = 0x0001;
      SendInput(1, inp, Marshal.SizeOf(typeof(INPUT)));
      Thread.Sleep(Math.Max(1, ms / steps));
    }
  }

  public static void Click(int x, int y) {
    SetCursorPos(x, y);
    Button(0x0001);  // deliver the move before the press
    Thread.Sleep(150);
    Button(0x0002); Thread.Sleep(70); Button(0x0004);
  }

  // Secondary (right) button click.
  public static void RightClick(int x, int y) {
    SetCursorPos(x, y);
    Button(0x0001);
    Thread.Sleep(150);
    Button(0x0008); Thread.Sleep(70); Button(0x0010);
  }

  // Two clicks well inside the system double-click time (500 ms by default).
  public static void DoubleClick(int x, int y) {
    Click(x, y);
    Thread.Sleep(90);
    Button(0x0002); Thread.Sleep(60); Button(0x0004);
  }

  public static void Wheel(int lines) {
    for (int i = 0; i < Math.Abs(lines) * 4; i++) {
      var inp = new INPUT[1]; inp[0].type = 0; inp[0].mi.flags = 0x0800;
      inp[0].mi.data = (uint)(lines > 0 ? -30 : 30);
      SendInput(1, inp, Marshal.SizeOf(typeof(INPUT)));
      Thread.Sleep(16);
    }
  }

  // points: x0,y0, x1,y1,ms1, x2,y2,ms2 ...
  public static void Drag(int[] a) {
    SetCursorPos(a[0], a[1]); Button(0x0001); Thread.Sleep(150);
    Button(0x0002); Thread.Sleep(180);
    for (int i = 2; i + 2 < a.Length; i += 3) { Glide(a[i], a[i + 1], a[i + 2]); Thread.Sleep(120); }
    Thread.Sleep(200);
    Button(0x0004);
  }
}
"@
[WInput]::Init()

function Get-AppWindows([int]$ProcessId) {
  foreach ($line in [WInput]::Windows($ProcessId)) {
    $f = $line.Split("|")
    $r = $f[2].Split(" ") | % { [int]$_ }
    $c = $f[3].Split(" ") | % { [int]$_ }
    [pscustomobject]@{
      Hwnd = [long]$f[0]; Title = $f[1]
      Left = $r[0]; Top = $r[1]; Right = $r[2]; Bottom = $r[3]
      ClientX = $c[0]; ClientY = $c[1]; ClientW = $c[2]; ClientH = $c[3]
      Scale = [int]$f[4] / 96.0
    }
  }
}

# Presses only when the point is on one of $ProcessId's windows.
function Assert-Owner([int]$ProcessId, [int]$X, [int]$Y) {
  $o = [WInput]::Owner($X, $Y)
  if ($o -ne $ProcessId) { throw "($X,$Y) belongs to pid $o, not $ProcessId" }
}

# Throws when the mouse moves on its own: someone is using the machine.
function Assert-Idle {
  $a = [WInput]::Pos(); Start-Sleep -Milliseconds 1500; $b = [WInput]::Pos()
  if ($a[0] -ne $b[0] -or $a[1] -ne $b[1]) { throw "the mouse is moving; someone is using this machine" }
}

function Raise-AppWindows([int]$ProcessId) {
  foreach ($w in @(Get-AppWindows $ProcessId)) { if ($w.ClientW -gt 0) { [WInput]::Raise($w.Hwnd) } }
  Start-Sleep -Milliseconds 300
}

# A point where the bare desktop shows through, or $null when windows cover all of it.
function Find-DesktopPoint {
  $size = [WInput]::Screen()
  for ($y = 120; $y -lt $size[1] - 120; $y += 160) {
    for ($x = $size[0] - 120; $x -gt 120; $x -= 160) {
      $cls = [WInput]::RootClass($x, $y)
      if ($cls -eq "Progman" -or $cls -eq "WorkerW") { return @($x, $y) }
    }
  }
  return $null
}

# Clicks an empty spot of the desktop, to take focus away from the app.
function Click-Desktop([int]$X, [int]$Y) {
  $cls = [WInput]::RootClass($X, $Y)
  if ($cls -ne "Progman" -and $cls -ne "WorkerW") { throw "($X,$Y) is not the desktop but $cls" }
  [WInput]::Click($X, $Y)
  Start-Sleep -Milliseconds 500
}

# Takes the focus away from the app under test without touching anybody else's window:
# shows a small window of this script's own process in the bottom-right corner and clicks
# it. Works however crowded the desktop is. The window stays until Close-BlurWindow (closing
# it earlier would hand the focus straight back).
Add-Type -AssemblyName System.Windows.Forms
$script:BlurForm = $null
function Invoke-Blur {
  if (-not $script:BlurForm) {
    $f = New-Object System.Windows.Forms.Form
    $f.Text = "gui-test blur"; $f.FormBorderStyle = "None"; $f.ShowInTaskbar = $false
    $f.TopMost = $true; $f.StartPosition = "Manual"; $f.BackColor = [System.Drawing.Color]::Gray
    $area = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $f.SetBounds($area.Right - 200, $area.Bottom - 100, 160, 60)
    $f.Show()
    $script:BlurForm = $f
  }
  [System.Windows.Forms.Application]::DoEvents()
  $w = Get-AppWindows $PID | ? { $_.Title -eq "gui-test blur" } | Select-Object -First 1
  if (-not $w) { throw "the blur window did not show" }
  $x = [int](($w.Left + $w.Right) / 2); $y = [int](($w.Top + $w.Bottom) / 2)
  [WInput]::Glide($x, $y, 400)
  Assert-Owner $PID $x $y
  [WInput]::Click($x, $y)
  foreach ($i in 1..10) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 50 }
  if ([WInput]::ForegroundPid() -ne $PID) { throw "could not take the focus away (foreground pid $([WInput]::ForegroundPid()))" }
}
function Close-BlurWindow {
  if ($script:BlurForm) { $script:BlurForm.Close(); $script:BlurForm = $null }
}
