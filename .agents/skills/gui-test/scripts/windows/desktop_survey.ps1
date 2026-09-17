# desktop_survey.ps1 [-X n -Y n]
# Without arguments: every visible, uncloaked top-level window, top of the z-order first.
# With a point (physical pixels): what WindowFromPoint reports there, then every
# window covering the point, top first. Run it on the interactive desktop; it only reads.
param([int]$X = -1, [int]$Y = -1)
Add-Type -TypeDefinition @"
using System; using System.Collections.Generic; using System.Runtime.InteropServices; using System.Text;
public static class DesktopSurvey {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
  delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] static extern bool SetProcessDpiAwarenessContext(IntPtr v);
  [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc p, IntPtr l);
  [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] static extern bool IsIconic(IntPtr h);
  [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] static extern IntPtr WindowFromPoint(POINT p);
  [DllImport("user32.dll")] static extern IntPtr GetAncestor(IntPtr h, uint f);
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetClassName(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] static extern int GetWindowLong(IntPtr h, int i);
  [DllImport("dwmapi.dll")] static extern int DwmGetWindowAttribute(IntPtr h, int a, out RECT r, int s);
  [DllImport("dwmapi.dll")] static extern int DwmGetWindowAttribute(IntPtr h, int a, out int v, int s);

  static string Describe(IntPtr h) {
    RECT r; if (DwmGetWindowAttribute(h, 9, out r, 16) != 0) GetWindowRect(h, out r);
    uint pid; GetWindowThreadProcessId(h, out pid);
    var t = new StringBuilder(128); GetWindowText(h, t, 128);
    var c = new StringBuilder(128); GetClassName(h, c, 128);
    string name = ""; try { name = System.Diagnostics.Process.GetProcessById((int)pid).ProcessName; } catch {}
    // ex: 0x20 transparent (click-through), 0x80000 layered, 0x8 topmost, 0x08000000 no-activate
    return String.Format("{0,-22} pid={1,-6} ex=0x{2:X8} {3},{4}-{5},{6} class={7} '{8}'",
      name, pid, GetWindowLong(h, -20), r.L, r.T, r.R, r.B, c, t);
  }

  public static List<string> Run(int x, int y) {
    SetProcessDpiAwarenessContext(new IntPtr(-4));
    var res = new List<string>();
    bool at = x >= 0 && y >= 0;
    if (at) {
      var root = GetAncestor(WindowFromPoint(new POINT { X = x, Y = y }), 2);
      res.Add("WindowFromPoint: " + Describe(root));
      res.Add("covering (" + x + "," + y + "), top first:");
    }
    EnumWindows((h, l) => {
      if (!IsWindowVisible(h) || IsIconic(h)) return true;
      int cloaked; DwmGetWindowAttribute(h, 14, out cloaked, 4); if (cloaked != 0) return true;
      RECT r; if (DwmGetWindowAttribute(h, 9, out r, 16) != 0) GetWindowRect(h, out r);
      if (at) { if (x < r.L || x >= r.R || y < r.T || y >= r.B) return true; }
      else if (r.R - r.L < 50 || r.B - r.T < 50) return true;
      res.Add(Describe(h));
      return true;
    }, IntPtr.Zero);
    return res;
  }
}
"@
[DesktopSurvey]::Run($X, $Y)
