# Dot-source after winput.ps1. Records the primary screen to an MP4:
#
#   Start-Recording "$RemoteScratch\name-windows.mp4"
#   try { ...scenario... } finally { Stop-Recording }   # encodes, then deletes the frames
#
# Frames are grabbed on a background thread (cursor and a click highlight drawn in),
# saved as JPEGs next to the output, and encoded with ffmpeg on this machine when the
# recording stops, keeping their real timing. Needs ffmpeg on this machine.
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

function Get-Ffmpeg {
  $cmd = Get-Command ffmpeg -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  # A scheduled task may start with a PATH from before ffmpeg was installed.
  foreach ($p in "$env:LOCALAPPDATA\Programs\ffmpeg\bin\ffmpeg.exe", "$env:USERPROFILE\scoop\shims\ffmpeg.exe",
                 "$env:LOCALAPPDATA\Microsoft\WinGet\Links\ffmpeg.exe", "C:\ProgramData\chocolatey\bin\ffmpeg.exe") {
    if (Test-Path $p) { return $p }
  }
  throw "ffmpeg not found; install it on this machine (see the record-demo skill)"
}

$script:RecordingOutput = $null

function Start-Recording([string]$Output, [int]$Fps = 30) {
  $null = Get-Ffmpeg  # fail before the scenario, not after it
  $script:RecordingOutput = $Output
  [ScreenRecorder]::Start("$Output.frames", $Fps)
}

# Stops capturing and encodes the frames to the MP4 given to Start-Recording:
# H.264 High, yuv420p, 30 fps, fitted into 1920x1200, no audio. Returns its path.
function Stop-Recording([int]$Fps = 30, [string]$MaxSize = "1920x1200") {
  [ScreenRecorder]::Stop()
  $out = $script:RecordingOutput
  $dir = "$out.frames"
  $rows = @(Get-Content "$dir\times.txt" | ? { $_ } | % { $f = $_.Split(" "); @{ I = [int]$f[0]; T = [long]$f[1] } } |
            ? { Test-Path ("$dir\{0:D6}.jpg" -f $_.I) })
  if ($rows.Count -lt 2) { throw "only $($rows.Count) frames captured" }
  # The concat demuxer keeps each frame for its real duration; it ignores the last duration.
  $list = New-Object System.Text.StringBuilder
  for ($k = 0; $k -lt $rows.Count - 1; $k++) {
    [void]$list.AppendLine(("file '{0:D6}.jpg'" -f $rows[$k].I))
    [void]$list.AppendLine(("duration {0:F3}" -f (($rows[$k + 1].T - $rows[$k].T) / 1000.0)).Replace(",", "."))
  }
  $last = "file '{0:D6}.jpg'" -f $rows[-1].I
  [void]$list.AppendLine($last); [void]$list.AppendLine("duration 0.040"); [void]$list.AppendLine($last)
  [IO.File]::WriteAllText("$dir\list.txt", $list.ToString(), (New-Object System.Text.UTF8Encoding $false))

  $w, $h = $MaxSize.Split("x")
  # JPEG frames are full range; converting to yuv420p (tv range) keeps players from washing them out.
  $vf = "fps=$Fps,scale=w=${w}:h=${h}:force_original_aspect_ratio=decrease:flags=lanczos,scale=trunc(iw/2)*2:trunc(ih/2)*2,format=yuv420p"
  $ffArgs = @("-y", "-loglevel", "error", "-f", "concat", "-safe", "0", "-i", "`"$dir\list.txt`"",
            "-vf", "`"$vf`"", "-c:v", "libx264", "-preset", "medium", "-crf", "18", "-profile:v", "high",
            "-pix_fmt", "yuv420p", "-color_range", "tv", "-movflags", "+faststart", "-an", "`"$out`"")
  # Start-Process: ffmpeg writes to stderr, which PowerShell 5.1 turns into terminating errors.
  $p = Start-Process (Get-Ffmpeg) -ArgumentList $ffArgs -NoNewWindow -Wait -PassThru -RedirectStandardError "$out.ffmpeg.log"
  if ($p.ExitCode -ne 0 -or -not (Test-Path $out)) {
    throw "ffmpeg failed ($($p.ExitCode)): $(Get-Content "$out.ffmpeg.log" -Raw)"
  }
  $seconds = ($rows[-1].T - $rows[0].T) / 1000.0
  Remove-Item $dir -Recurse -Force
  Remove-Item "$out.ffmpeg.log" -ErrorAction SilentlyContinue
  "{0}: {1} frames over {2:F1}s ({3:F1} fps captured)" -f $out, $rows.Count, $seconds, ($rows.Count / $seconds) | Write-Host
  return $out
}
