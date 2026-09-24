#!/usr/bin/env python3
"""Records the GNOME/Wayland screen, keeping each frame's real time, and encodes the take.

    import sys; sys.path.insert(0, '.agents/skills/record-demo/scripts/linux')
    from recorder import Recorder, grab

    frame = grab('/tmp/look.png')         # one PNG of the primary monitor (no input sent)
    rec = Recorder('/path/to/demo.mp4')   # frames land in  /path/to/demo.mp4.frames/
    rec.start()                           # capture begins; the cursor is drawn into the frames
    try:
        ...                               # play the scenario
    finally:
        rec.stop()
    rec.report()

Why frames and not a movie: GNOME 46 lets nothing else read the screen — `gnome-screenshot`
is not installed, `org.gnome.Shell.Screenshot` answers AccessDenied, and XTEST/Xlib see no
Wayland window — so capture goes through `org.gnome.Mutter.ScreenCast` -> PipeWire. The
GStreamer plugins on this host have no H.264 encoder at all (`x264enc`, `avenc_h264`,
`openh264enc`, `vaapih264*` are all missing), so the take is written as JPEG frames plus their
real write times and encoded where ffmpeg exists (`encode()`, or the wrapper
`scripts/record_remote_linux.sh`, which pulls the frames to the Mac and encodes there).

The pipeline is `pipewiresrc ! videoconvert ! videoscale ! jpegenc ! multifilesink`, with the
monitor recorded `cursor-mode: 1` (embedded) so the real pointer is in the picture. Each
frame's timestamp is its file mtime in nanoseconds: the source is live (PipeWire delivers in
real time), so the gaps between files are the gaps between frames. Frames are scaled down to
fit `size` (default 1920x1200, the X limit) at capture time — the stream is the whole monitor
(2560x1440 here), and there is no point shipping 2.6x the pixels the MP4 may keep. Mutter
produces frames on damage, so a still picture costs nothing and motion reaches ~28 fps here.

    recorder.py encode <frames-dir> <out.mp4> [fps]     # ffmpeg, on a machine that has it
"""

import os
import subprocess
import sys
import time

MAX_SIZE = (1920, 1200)
FPS = 30
QUALITY = 85


def _fit(width, height, size):
    """(width, height) scaled down to fit in `size`, aspect kept, both even."""
    mx, my = size
    scale = min(1.0, mx / width, my / height)
    w, h = int(width * scale) // 2 * 2, int(height * scale) // 2 * 2
    return max(2, w), max(2, h)


class ScreenCast:
    """One Mutter ScreenCast session on the primary monitor.

    A plain cast session: it does NOT need (and does not create) a RemoteDesktop session, so
    it coexists with whatever session the input driver owns. When the host has no monitor
    attached (`DisplayConfig` reports none, `/sys/class/drm/*/status` says `disconnected`),
    there is nothing to RecordMonitor and the session records a Mutter **virtual monitor**
    instead — 1280x720, the only size Mutter 46 accepts. Mutter does not paint the pointer
    into a virtual stream, so the frames have no cursor; `virtual` says which case it is.
    """

    #: What Mutter gives a virtual monitor; DisplayConfig does not report it at all.
    VIRTUAL_SIZE = (1280, 720)

    def __init__(self, cursor=True):
        self.cursor = cursor
        self.session = None
        self.node = None
        self.stream = None
        self.virtual = False
        self.connector = None
        self.width = self.height = 0  # the monitor's physical size, from DisplayConfig

    def _proxy(self, bus, name, path, iface):
        from gi.repository import Gio
        return Gio.DBusProxy.new_sync(bus, Gio.DBusProxyFlags.NONE, None,
                                      name, path, iface, None)

    def _monitors(self, bus):
        from gi.repository import Gio
        config = self._proxy(bus, 'org.gnome.Mutter.DisplayConfig',
                             '/org/gnome/Mutter/DisplayConfig',
                             'org.gnome.Mutter.DisplayConfig')
        _serial, monitors, _logical, _props = config.call_sync(
            'GetCurrentState', None, Gio.DBusCallFlags.NONE, -1, None).unpack()
        return monitors

    def open(self, timeout=20):
        """Start the session; returns the PipeWire node id of the monitor stream."""
        from gi.repository import Gio, GLib
        if self.node is not None:
            return self.node
        bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
        cast = self._proxy(bus, 'org.gnome.Mutter.ScreenCast', '/org/gnome/Mutter/ScreenCast',
                           'org.gnome.Mutter.ScreenCast')
        path = cast.call_sync('CreateSession', GLib.Variant('(a{sv})', [{}]),
                              Gio.DBusCallFlags.NONE, -1, None).unpack()[0]
        session = self._proxy(bus, 'org.gnome.Mutter.ScreenCast', path,
                              'org.gnome.Mutter.ScreenCast.Session')
        self.session = session
        options = {'cursor-mode': GLib.Variant('u', 1 if self.cursor else 0)}
        monitors = self._monitors(bus)
        if monitors:
            # monitors[0] is ((connector, vendor, product, serial), modes, x, y, props)
            connector, modes = monitors[0][0][0], monitors[0][1]
            current = next((m for m in modes if m[6].get('is-current')), modes[0])
            self.connector = connector
            self.width, self.height = int(current[1]), int(current[2])
            self.stream = session.call_sync(
                'RecordMonitor', GLib.Variant('(sa{sv})', (connector, options)),
                Gio.DBusCallFlags.NONE, -1, None).unpack()[0]
        else:
            self.virtual = True
            self.width, self.height = self.VIRTUAL_SIZE
            self.stream = session.call_sync(
                'RecordVirtual', GLib.Variant('(a{sv})', [options]),
                Gio.DBusCallFlags.NONE, -1, None).unpack()[0]
        loop = GLib.MainLoop()
        found = {}

        def on_stream(_c, _s, _p, _i, _sig, params):
            found['node'] = params.unpack()[0]
            loop.quit()

        bus.signal_subscribe('org.gnome.Mutter.ScreenCast',
                             'org.gnome.Mutter.ScreenCast.Stream', 'PipeWireStreamAdded',
                             self.stream, None, Gio.DBusSignalFlags.NONE, on_stream)
        session.call_sync('Start', None, Gio.DBusCallFlags.NONE, -1, None)
        GLib.timeout_add_seconds(timeout, loop.quit)
        loop.run()
        if 'node' not in found:
            raise SystemExit('the ScreenCast stream never announced a PipeWire node')
        self.node = found['node']
        return self.node

    def close(self):
        if self.session is not None:
            try:
                from gi.repository import Gio
                self.session.call_sync('Stop', None, Gio.DBusCallFlags.NONE, -1, None)
            except Exception:
                pass
            self.session = None
        self.node = None


def _read_node(node, path, timeout=30):
    """One PNG frame off an existing PipeWire node (the `wayland_shot.py` sequence)."""
    subprocess.run(['gst-launch-1.0', '-q', 'pipewiresrc', f'path={node}',
                    'num-buffers=1', '!', 'videoconvert', '!', 'pngenc',
                    'snapshot=false', '!', 'multifilesink', f'location={path}'],
                   timeout=timeout, check=True)
    return path


def grab(path, node=None, cast=None, cursor=False, timeout=30):
    """Save one PNG frame of the monitor: off `node` when given, else a fresh session."""
    if node is not None:
        return _read_node(node, path, timeout)
    own = cast is None
    cast = cast if cast is not None else ScreenCast(cursor=cursor)
    node = cast.open()
    try:
        return _read_node(node, path, timeout)
    finally:
        if own:
            cast.close()


class Recorder:
    """Captures the primary monitor to JPEG frames with their real timing.

    `output` names the MP4 to be produced later; the frames live in `output + '.frames'`
    (so `encode()` and the pull-back wrapper find them) — nothing is written to `output`
    on this machine unless `encode()` is called here.
    """

    def __init__(self, output, size=MAX_SIZE, quality=QUALITY, cursor=True, cast=None):
        self.output = os.path.abspath(output)
        self.frames = self.output + '.frames'
        self.size = size
        self.quality = quality
        self.cursor = cursor
        self.cast = cast          # an already-open ScreenCast to record through
        self.count = 0
        self.seconds = 0.0
        self.width = self.height = 0
        self.virtual = False
        self._cast = None
        self._pipeline = None

    def _frame_paths(self):
        """[(index, path)] of the captured frames, in index order."""
        names = [n for n in os.listdir(self.frames) if n.endswith('.jpg')]
        return sorted((int(n[:-4].lstrip('f')), os.path.join(self.frames, n)) for n in names)

    def start(self, first_frame_timeout=15):
        import gi
        gi.require_version('Gst', '1.0')
        from gi.repository import Gst
        Gst.init(None)
        if os.path.isdir(self.frames):
            for name in os.listdir(self.frames):
                os.remove(os.path.join(self.frames, name))
        else:
            os.makedirs(self.frames)
        self._cast = self.cast if self.cast is not None else ScreenCast(cursor=self.cursor)
        node = self._cast.open()
        self.virtual = self._cast.virtual
        self.width, self.height = _fit(self._cast.width, self._cast.height, self.size)
        pipeline = Gst.parse_launch(
            f'pipewiresrc path={node} do-timestamp=true ! videoconvert ! videoscale ! '
            f'video/x-raw,width={self.width},height={self.height} ! '
            f'jpegenc quality={self.quality} ! multifilesink '
            f'location={self.frames}/f%06d.jpg')
        self._pipeline = pipeline
        pipeline.set_state(Gst.State.PLAYING)
        # Do not return before the stream really is running: the caller starts playing the
        # scenario the moment this returns, and the take must not open on a stale desktop.
        deadline = time.time() + first_frame_timeout
        while time.time() < deadline:
            if len(self._frame_paths()) >= 2:
                return
            time.sleep(0.05)
        self.stop()
        raise SystemExit('the ScreenCast stream produced no frames')

    def stop(self):
        from gi.repository import Gst
        if self._pipeline is not None:
            self._pipeline.set_state(Gst.State.NULL)
            self._pipeline = None
        if self._cast is not None and self.cast is None:
            self._cast.close()   # a cast we were given is the caller's to close
        self._cast = None
        rows = _rows(self.frames)
        self.count = len(rows)
        self.seconds = (rows[-1][1] - rows[0][1]) / 1000.0 if len(rows) > 1 else 0.0

    def report(self):
        fps = self.count / self.seconds if self.seconds else 0
        source = 'virtual monitor' if self.virtual else 'monitor'
        print(f'RECORD_FRAMES {self.frames}', flush=True)
        print(f'recording: {self.count} frames over {self.seconds:.1f}s '
              f'({fps:.1f} fps captured) at {self.width}x{self.height} from the {source}',
              flush=True)
        if self.virtual:
            print('warning: Mutter does not paint the pointer into a virtual-monitor stream; '
                  'these frames have no cursor', flush=True)
        return self.count


def _rows(frames, fps=FPS):
    """[(index, ms since the first frame)] for the frames on disk.

    The real timing is each frame's write time. Files that have been copied around (or a
    filesystem without usable stamps) can lose that order, so when the stamps are not
    strictly increasing the frames are spaced evenly at `fps` instead of producing a list
    with nonsense durations — a take is not thrown away for that.
    """
    names = [n for n in os.listdir(frames) if n.endswith('.jpg')]
    found = sorted((int(n[:-4].lstrip('f')), os.path.join(frames, n)) for n in names)
    if len(found) < 2:
        return [(i, 0) for i, _ in found]
    # times.txt ("<name> <mtime in s>" per line, written on the host before the pull) keeps
    # the stamps that scp drops.
    listed = {}
    times = os.path.join(frames, 'times.txt')
    if os.path.exists(times):
        with open(times) as f:
            for line in f:
                name, _, stamp = line.strip().partition(' ')
                if stamp:
                    listed[name] = int(float(stamp) * 1_000_000_000)
    stamps = [listed.get(os.path.basename(p)) or os.stat(p).st_mtime_ns for _, p in found]
    if any(later <= earlier for earlier, later in zip(stamps, stamps[1:])):
        step = 1_000_000_000 // fps
        stamps = [i * step for i in range(len(found))]
    first = stamps[0]
    return [(i, (stamp - first) // 1_000_000) for (i, _), stamp in zip(found, stamps)]


def encode(frames, output, fps=FPS, max_size=MAX_SIZE):
    """Encodes a frames directory to an X-ready MP4: H.264 High, yuv420p, no audio.

    A variable-framerate concat list keeps every frame for its real duration (the concat
    demuxer ignores the last duration, so the final frame is repeated); `fps` then
    resamples that to the constant rate the MP4 carries.
    """
    frames = os.path.abspath(frames)
    rows = _rows(frames)
    if len(rows) < 2:
        raise SystemExit(f'only {len(rows)} frames in {frames}')
    listing = []
    for k in range(len(rows) - 1):
        listing.append(f"file '{frames}/f{rows[k][0]:06d}.jpg'")
        listing.append(f'duration {(rows[k + 1][1] - rows[k][1]) / 1000.0:.3f}')
    listing += [f"file '{frames}/f{rows[-1][0]:06d}.jpg'", 'duration 0.040',
                f"file '{frames}/f{rows[-1][0]:06d}.jpg'"]
    list_path = os.path.join(frames, 'list.txt')
    with open(list_path, 'w') as f:
        f.write('\n'.join(listing) + '\n')

    w, h = max_size
    # JPEG frames are full range; converting to yuv420p (tv range) keeps players from
    # washing them out. The scale is a no-op when the frames were already fitted.
    vf = (f'fps={fps},scale=w={w}:h={h}:force_original_aspect_ratio=decrease:flags=lanczos,'
          'scale=trunc(iw/2)*2:trunc(ih/2)*2,format=yuv420p')
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-f', 'concat', '-safe', '0',
                    '-i', list_path, '-vf', vf, '-c:v', 'libx264', '-preset', 'medium',
                    '-crf', '18', '-profile:v', 'high', '-pix_fmt', 'yuv420p',
                    '-color_range', 'tv', '-movflags', '+faststart', '-an', output],
                   check=True)
    seconds = (rows[-1][1] - rows[0][1]) / 1000.0
    print(f'{output}: {len(rows)} frames over {seconds:.1f}s '
          f'({len(rows) / seconds:.1f} fps captured)')
    return output


def main(argv):
    if len(argv) >= 4 and argv[1] == 'encode':
        return 0 if encode(argv[2], argv[3], *(int(a) for a in argv[4:])) else 1
    print(__doc__)
    return 2


if __name__ == '__main__':
    sys.exit(main(sys.argv))
