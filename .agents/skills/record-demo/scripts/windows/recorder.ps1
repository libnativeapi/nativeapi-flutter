# Dot-source after winput.ps1. Captures the primary screen to JPEG frames on
# a background thread, with the cursor and a click highlight drawn in.
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Collections.Concurrent;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading;

public static class ScreenRecorder {
  [StructLayout(LayoutKind.Sequential)] struct POINT { public int X, Y; }
  [StructLayout(LayoutKind.Sequential)] struct CURSORINFO { public int cbSize, flags; public IntPtr hCursor; public POINT pt; }
  [StructLayout(LayoutKind.Sequential)] struct ICONINFO { public bool fIcon; public int xHotspot, yHotspot; public IntPtr hbmMask, hbmColor; }
  [DllImport("user32.dll")] static extern bool GetCursorInfo(ref CURSORINFO ci);
  [DllImport("user32.dll")] static extern bool GetIconInfo(IntPtr h, out ICONINFO ii);
  [DllImport("user32.dll")] static extern bool DrawIconEx(IntPtr hdc, int x, int y, IntPtr icon, int w, int h, int step, IntPtr brush, int flags);
  [DllImport("user32.dll")] static extern short GetAsyncKeyState(int key);
  [DllImport("user32.dll")] static extern int GetSystemMetrics(int i);
  [DllImport("gdi32.dll")] static extern bool DeleteObject(IntPtr h);

  static Thread capture;
  static Thread[] writers;
  static volatile bool running;
  static BlockingCollection<Tuple<int, Bitmap>> queue;
  static StreamWriter times;
  public static int Frames;

  public static void Start(string dir, int fps) {
    Directory.CreateDirectory(dir);
    foreach (var f in Directory.GetFiles(dir)) File.Delete(f);
    int w = GetSystemMetrics(0), h = GetSystemMetrics(1);
    queue = new BlockingCollection<Tuple<int, Bitmap>>(120);
    times = new StreamWriter(Path.Combine(dir, "times.txt"));
    var codec = ImageCodecInfo.GetImageEncoders().First(c => c.MimeType == "image/jpeg");
    var prms = new EncoderParameters(1);
    prms.Param[0] = new EncoderParameter(System.Drawing.Imaging.Encoder.Quality, 82L);
    writers = Enumerable.Range(0, 3).Select(i => new Thread(() => {
      foreach (var item in queue.GetConsumingEnumerable()) {
        item.Item2.Save(Path.Combine(dir, item.Item1.ToString("D6") + ".jpg"), codec, prms);
        item.Item2.Dispose();
      }
    })).ToArray();
    foreach (var t in writers) t.Start();
    running = true;
    Frames = 0;
    capture = new Thread(() => {
      var clock = Stopwatch.StartNew();
      long interval = 1000 / fps, next = 0;
      int primary = GetSystemMetrics(23) != 0 ? 0x02 : 0x01;  // SM_SWAPBUTTON
      while (running) {
        long now = clock.ElapsedMilliseconds;
        if (now < next) { Thread.Sleep((int)(next - now)); continue; }
        next = now + interval;
        var bmp = new Bitmap(w, h, PixelFormat.Format24bppRgb);
        using (var g = Graphics.FromImage(bmp)) {
          g.CopyFromScreen(0, 0, 0, 0, new Size(w, h));
          var ci = new CURSORINFO { cbSize = Marshal.SizeOf(typeof(CURSORINFO)) };
          if (GetCursorInfo(ref ci) && ci.hCursor != IntPtr.Zero) {
            if ((GetAsyncKeyState(primary) & 0x8000) != 0) {
              using (var brush = new SolidBrush(Color.FromArgb(90, 255, 200, 0)))
                g.FillEllipse(brush, ci.pt.X - 22, ci.pt.Y - 22, 44, 44);
            }
            ICONINFO ii;
            int hx = 0, hy = 0;
            if (GetIconInfo(ci.hCursor, out ii)) {
              hx = ii.xHotspot; hy = ii.yHotspot;
              if (ii.hbmMask != IntPtr.Zero) DeleteObject(ii.hbmMask);
              if (ii.hbmColor != IntPtr.Zero) DeleteObject(ii.hbmColor);
            }
            IntPtr hdc = g.GetHdc();
            DrawIconEx(hdc, ci.pt.X - hx, ci.pt.Y - hy, ci.hCursor, 0, 0, 0, IntPtr.Zero, 0x0003);
            g.ReleaseHdc(hdc);
          }
        }
        int index = Frames++;
        times.WriteLine(index + " " + now);
        queue.Add(Tuple.Create(index, bmp));
      }
    });
    capture.Priority = ThreadPriority.AboveNormal;
    capture.Start();
  }

  public static void Stop() {
    running = false;
    capture.Join();
    queue.CompleteAdding();
    foreach (var t in writers) t.Join();
    times.Dispose();
  }
}
"@
