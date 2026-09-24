"""Look at windows and drive the pointer on a Linux desktop, through ctypes and D-Bus.

Two halves, because on a Wayland session no single interface does both:

* **Looking** — `X11`: window list, titles, geometry and stacking, straight from
  Xlib. It only sees X11 windows, which on a Wayland session means Xwayland clients,
  so apps under test are launched with `GDK_BACKEND=x11` (see guiapp.py). Wayland-native
  windows and the GNOME shell chrome are invisible here.
* **Acting** — `RemoteDesktop`: absolute pointer motion, buttons and wheel through
  `org.gnome.Mutter.RemoteDesktop`, which is real input at the compositor: it focuses
  and raises windows exactly like a hand on the mouse.

XTEST (`XTestFakeMotionEvent` and friends) looks like the obvious driver and is a trap
on Wayland: Xwayland delivers those events to X clients, so button presses even arrive
at the right window, but the compositor never sees them — the real cursor does not move,
nothing takes the focus, and no Wayland client notices. Anything that reacts to
activation (a tear-off that starts on a focus change, say) silently does nothing.
"""

import ctypes
import ctypes.util
import os
import subprocess
import time

CurrentTime = 0
AnyPropertyType = 0
XA_CARDINAL = 6
XA_WINDOW = 33
IsViewable = 2


class _XWindowAttributes(ctypes.Structure):
    _fields_ = [('x', ctypes.c_int), ('y', ctypes.c_int),
                ('width', ctypes.c_int), ('height', ctypes.c_int),
                ('border_width', ctypes.c_int), ('depth', ctypes.c_int),
                ('visual', ctypes.c_void_p), ('root', ctypes.c_ulong),
                ('class', ctypes.c_int), ('bit_gravity', ctypes.c_int),
                ('win_gravity', ctypes.c_int), ('backing_store', ctypes.c_int),
                ('backing_planes', ctypes.c_ulong), ('backing_pixel', ctypes.c_ulong),
                ('save_under', ctypes.c_int), ('colormap', ctypes.c_ulong),
                ('map_installed', ctypes.c_int), ('map_state', ctypes.c_int),
                ('all_event_masks', ctypes.c_long), ('your_event_mask', ctypes.c_long),
                ('do_not_propagate_mask', ctypes.c_long), ('override_redirect', ctypes.c_int),
                ('screen', ctypes.c_void_p)]


class _XClientMessageData(ctypes.Union):
    _fields_ = [('b', ctypes.c_char * 20), ('s', ctypes.c_short * 10), ('l', ctypes.c_long * 5)]


class _XClientMessageEvent(ctypes.Structure):
    _fields_ = [('type', ctypes.c_int), ('serial', ctypes.c_ulong), ('send_event', ctypes.c_int),
                ('display', ctypes.c_void_p), ('window', ctypes.c_ulong),
                ('message_type', ctypes.c_ulong), ('format', ctypes.c_int),
                ('data', _XClientMessageData)]


class _XEvent(ctypes.Union):
    _fields_ = [('type', ctypes.c_int), ('xclient', _XClientMessageEvent),
                ('pad', ctypes.c_long * 24)]


class Window:
    """An X11 toplevel of some application."""

    def __init__(self, xid, pid, title, frame, content):
        self.xid = xid
        self.pid = pid
        self.title = title
        self.frame = frame      # (x, y, w, h) including the window manager's decorations
        self.content = content  # (x, y, w, h) of the client area

    def __repr__(self):
        return f'Window(0x{self.xid:x}, pid={self.pid}, {self.title!r}, frame={self.frame})'


class X11:
    def __init__(self):
        self.x11 = ctypes.CDLL(ctypes.util.find_library('X11') or 'libX11.so.6')
        self.x11.XOpenDisplay.restype = ctypes.c_void_p
        self.x11.XOpenDisplay.argtypes = [ctypes.c_char_p]
        self.dpy = self.x11.XOpenDisplay(None)
        if not self.dpy:
            raise RuntimeError(f'cannot open X display {os.environ.get("DISPLAY")!r}')
        self.x11.XDefaultRootWindow.restype = ctypes.c_ulong
        self.x11.XDefaultRootWindow.argtypes = [ctypes.c_void_p]
        self.root = self.x11.XDefaultRootWindow(self.dpy)
        self.x11.XInternAtom.restype = ctypes.c_ulong
        self.x11.XInternAtom.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_int]
        self._atoms = {}

    # -- plumbing -------------------------------------------------------------

    def atom(self, name):
        if name not in self._atoms:
            self._atoms[name] = self.x11.XInternAtom(self.dpy, name.encode(), False)
        return self._atoms[name]

    def flush(self):
        self.x11.XFlush(self.dpy)

    def _property(self, window, name, prop_type):
        actual_type = ctypes.c_ulong()
        actual_format = ctypes.c_int()
        nitems = ctypes.c_ulong()
        bytes_after = ctypes.c_ulong()
        data = ctypes.POINTER(ctypes.c_ubyte)()
        self.x11.XGetWindowProperty.argtypes = [
            ctypes.c_void_p, ctypes.c_ulong, ctypes.c_ulong, ctypes.c_long, ctypes.c_long,
            ctypes.c_int, ctypes.c_ulong, ctypes.POINTER(ctypes.c_ulong),
            ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_ulong),
            ctypes.POINTER(ctypes.c_ulong), ctypes.POINTER(ctypes.POINTER(ctypes.c_ubyte))]
        status = self.x11.XGetWindowProperty(
            self.dpy, window, self.atom(name), 0, 4096, False, prop_type,
            ctypes.byref(actual_type), ctypes.byref(actual_format), ctypes.byref(nitems),
            ctypes.byref(bytes_after), ctypes.byref(data))
        if status != 0 or not data:
            return None, 0, 0
        return data, nitems.value, actual_format.value

    def cardinals(self, window, name, prop_type=AnyPropertyType):
        data, n, fmt = self._property(window, name, prop_type)
        if not data:
            return []
        try:
            if fmt == 32:  # 32-bit X properties come back as longs
                arr = ctypes.cast(data, ctypes.POINTER(ctypes.c_ulong))
            elif fmt == 16:
                arr = ctypes.cast(data, ctypes.POINTER(ctypes.c_ushort))
            else:
                arr = ctypes.cast(data, ctypes.POINTER(ctypes.c_ubyte))
            return [arr[i] for i in range(n)]
        finally:
            self.x11.XFree(data)

    def text(self, window, name):
        data, n, _ = self._property(window, name, AnyPropertyType)
        if not data:
            return None
        try:
            return bytes(bytearray(data[i] for i in range(n))).decode('utf-8', 'replace')
        finally:
            self.x11.XFree(data)

    def attributes(self, window):
        attrs = _XWindowAttributes()
        self.x11.XGetWindowAttributes.argtypes = [ctypes.c_void_p, ctypes.c_ulong,
                                                  ctypes.POINTER(_XWindowAttributes)]
        if not self.x11.XGetWindowAttributes(self.dpy, window, ctypes.byref(attrs)):
            return None
        return attrs

    def absolute(self, window, x=0, y=0):
        ax, ay, child = ctypes.c_int(), ctypes.c_int(), ctypes.c_ulong()
        self.x11.XTranslateCoordinates.argtypes = [
            ctypes.c_void_p, ctypes.c_ulong, ctypes.c_ulong, ctypes.c_int, ctypes.c_int,
            ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_int),
            ctypes.POINTER(ctypes.c_ulong)]
        if not self.x11.XTranslateCoordinates(self.dpy, window, self.root, x, y,
                                              ctypes.byref(ax), ctypes.byref(ay),
                                              ctypes.byref(child)):
            return None
        return ax.value, ay.value

    # -- looking --------------------------------------------------------------

    def screen_size(self):
        self.x11.XDisplayWidth.argtypes = [ctypes.c_void_p, ctypes.c_int]
        self.x11.XDisplayHeight.argtypes = [ctypes.c_void_p, ctypes.c_int]
        return self.x11.XDisplayWidth(self.dpy, 0), self.x11.XDisplayHeight(self.dpy, 0)

    def _window(self, xid):
        attrs = self.attributes(xid)
        if not attrs or attrs.map_state != IsViewable:
            return None
        origin = self.absolute(xid)
        if origin is None:
            return None
        pids = self.cardinals(xid, '_NET_WM_PID', XA_CARDINAL)
        title = self.text(xid, '_NET_WM_NAME') or self.text(xid, 'WM_NAME') or ''
        content = (origin[0], origin[1], attrs.width, attrs.height)
        extents = self.cardinals(xid, '_NET_FRAME_EXTENTS', XA_CARDINAL)
        if len(extents) == 4:
            left, right, top, bottom = extents
            frame = (origin[0] - left, origin[1] - top,
                     attrs.width + left + right, attrs.height + top + bottom)
        else:
            frame = content
        return Window(xid, pids[0] if pids else None, title, frame, content)

    def windows(self, pid=None, stacking=False):
        """Managed toplevels, optionally only those of one process.

        `stacking=True` returns them bottom-most first (`_NET_CLIENT_LIST_STACKING`).
        """
        prop = '_NET_CLIENT_LIST_STACKING' if stacking else '_NET_CLIENT_LIST'
        out = []
        for xid in self.cardinals(self.root, prop, XA_WINDOW):
            window = self._window(xid)
            if window and (pid is None or window.pid == pid):
                out.append(window)
        return out

    def window_at(self, x, y):
        """The top-most X11 toplevel whose frame covers the point, or None.

        None means "no X11 window there" — on Wayland it does *not* mean the point is
        free, since Wayland-native windows are invisible from here.
        """
        for window in reversed(self.windows(stacking=True)):
            fx, fy, fw, fh = window.frame
            if fx <= x < fx + fw and fy <= y < fy + fh:
                return window
        return None

    def active_window(self):
        xids = self.cardinals(self.root, '_NET_ACTIVE_WINDOW', XA_WINDOW)
        return xids[0] if xids else 0

    def pointer(self):
        """(x, y, buttons_mask) as the X server knows it.

        On a Wayland session that is only current while the pointer is over an Xwayland
        surface — which is what makes it a useful check that a point about to be pressed
        really is on the app's own window and not under some Wayland window on top.
        """
        root_ret, child = ctypes.c_ulong(), ctypes.c_ulong()
        rx, ry, wx, wy = (ctypes.c_int() for _ in range(4))
        mask = ctypes.c_uint()
        self.x11.XQueryPointer.argtypes = [
            ctypes.c_void_p, ctypes.c_ulong, ctypes.POINTER(ctypes.c_ulong),
            ctypes.POINTER(ctypes.c_ulong), ctypes.POINTER(ctypes.c_int),
            ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_int),
            ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_uint)]
        self.x11.XQueryPointer(self.dpy, self.root, ctypes.byref(root_ret), ctypes.byref(child),
                               ctypes.byref(rx), ctypes.byref(ry), ctypes.byref(wx),
                               ctypes.byref(wy), ctypes.byref(mask))
        return rx.value, ry.value, mask.value

    # -- acting ---------------------------------------------------------------

    def activate(self, xid):
        """Ask the window manager to focus and raise a window (_NET_ACTIVE_WINDOW).

        A request, not a guarantee: GNOME raises the window but often leaves the focus
        alone. Only a real click reliably moves the focus — see GuiApp.blur().
        """
        event = _XEvent()
        event.xclient.type = 33  # ClientMessage
        event.xclient.display = self.dpy
        event.xclient.window = xid
        event.xclient.message_type = self.atom('_NET_ACTIVE_WINDOW')
        event.xclient.format = 32
        event.xclient.data.l[0] = 2  # source: pager
        event.xclient.data.l[1] = CurrentTime
        self.x11.XSendEvent.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.c_int,
                                        ctypes.c_long, ctypes.POINTER(_XEvent)]
        self.x11.XSendEvent(self.dpy, self.root, False,
                            (1 << 20) | (1 << 19),  # SubstructureNotify | SubstructureRedirect
                            ctypes.byref(event))
        self.flush()


BTN_LEFT = 0x110    # linux/input-event-codes.h, what RemoteDesktop expects
BTN_RIGHT = 0x111
BTN_MIDDLE = 0x112
AXIS_VERTICAL = 0
AXIS_HORIZONTAL = 1


class RemoteDesktop:
    """Real pointer input through org.gnome.Mutter.RemoteDesktop (GNOME).

    The session is created for this process only and lives as long as this object;
    on GNOME it needs no consent dialog for a direct (non-sandboxed) caller. Absolute
    motion is addressed to a screen cast stream, so a `ScreenCast` session bound to the
    remote desktop session is created too — nothing here reads its PipeWire buffers, it
    only gives the coordinates a frame of reference (`node` and `stream` name them, so a
    recorder can read the same stream).

    When the host has **no monitor attached** — both HDMI outputs report `disconnected`
    in `/sys/class/drm/*/status`, and DisplayConfig then answers with an empty monitor
    list, so there is nothing to RecordMonitor and no cursor to render — the stream is a
    Mutter **virtual monitor** instead (1280x720, the only size 46 accepts: `width` /
    `height` / `refresh-rate` properties are ignored). The compositor then has a logical
    monitor to place windows on and absolute motion still works; what it does NOT do is
    paint the pointer into a virtual stream, in cursor-mode 0 or 1 (measured: two frames
    taken with the pointer at (300,300) and (900,500) differ only in the top bar's clock).
    `virtual` says which case this session is.
    """

    #: What Mutter gives a virtual monitor; DisplayConfig does not report it at all.
    VIRTUAL_SIZE = (1280, 720)

    def __init__(self):
        import gi
        from gi.repository import Gio, GLib
        self._Gio, self._GLib = Gio, GLib
        self.bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
        self.session = None
        self.stream = None
        self.node = None        # PipeWire node id of the reference stream
        self.virtual = False    # True when the stream is a virtual monitor
        self.size = None        # the monitor's physical size, when there is one
        self.position = None  # where we last put the pointer; None until the first move
        self._start()

    def _proxy(self, name, path, iface):
        return self._Gio.DBusProxy.new_sync(self.bus, self._Gio.DBusProxyFlags.NONE, None,
                                            name, path, iface, None)

    def _call(self, proxy, method, args=None):
        return proxy.call_sync(method, args, self._Gio.DBusCallFlags.NONE, -1, None)

    def _monitors(self):
        """Mutter's monitor list; empty when no output is attached."""
        config = self._proxy('org.gnome.Mutter.DisplayConfig', '/org/gnome/Mutter/DisplayConfig',
                             'org.gnome.Mutter.DisplayConfig')
        _serial, monitors, _logical, _props = self._call(config, 'GetCurrentState').unpack()
        return monitors

    def _start(self):
        GLib = self._GLib
        remote = self._proxy('org.gnome.Mutter.RemoteDesktop', '/org/gnome/Mutter/RemoteDesktop',
                             'org.gnome.Mutter.RemoteDesktop')
        path = self._call(remote, 'CreateSession').unpack()[0]
        self.session = self._proxy('org.gnome.Mutter.RemoteDesktop', path,
                                   'org.gnome.Mutter.RemoteDesktop.Session')
        session_id = self.session.get_cached_property('SessionId').unpack()

        cast = self._proxy('org.gnome.Mutter.ScreenCast', '/org/gnome/Mutter/ScreenCast',
                           'org.gnome.Mutter.ScreenCast')
        cast_path = self._call(cast, 'CreateSession', GLib.Variant('(a{sv})', [
            {'remote-desktop-session-id': GLib.Variant('s', session_id)}])).unpack()[0]
        cast_session = self._proxy('org.gnome.Mutter.ScreenCast', cast_path,
                                   'org.gnome.Mutter.ScreenCast.Session')
        options = {'cursor-mode': GLib.Variant('u', 1)}
        monitors = self._monitors()
        if monitors:
            # monitors[0] is ((connector, vendor, product, serial), modes, x, y, props)
            connector, modes = monitors[0][0][0], monitors[0][1]
            current = next((m for m in modes if m[6].get('is-current')), modes[0])
            self.size = (int(current[1]), int(current[2]))
            self.stream = self._call(cast_session, 'RecordMonitor',
                                     GLib.Variant('(sa{sv})', (connector, options))).unpack()[0]
        else:
            self.virtual = True
            self.size = self.VIRTUAL_SIZE
            self.stream = self._call(cast_session, 'RecordVirtual',
                                     GLib.Variant('(a{sv})', [options])).unpack()[0]
        self._node_of(cast_session)
        # Starting the remote desktop session starts the cast bound to it; starting the
        # cast session itself fails with "Must be started from remote desktop session".
        self._call(self.session, 'Start')

    def _node_of(self, cast_session):
        """Learn the stream's PipeWire node id (for a recorder reading the same stream)."""
        GLib = self._GLib
        loop = GLib.MainLoop()

        def on_stream(_c, _s, _p, _i, _sig, params):
            self.node = params.unpack()[0]
            loop.quit()

        self.bus.signal_subscribe('org.gnome.Mutter.ScreenCast',
                                  'org.gnome.Mutter.ScreenCast.Stream', 'PipeWireStreamAdded',
                                  self.stream, None, self._Gio.DBusSignalFlags.NONE, on_stream)
        GLib.timeout_add_seconds(15, loop.quit)
        loop.run()

    def stop(self):
        if self.session is not None:
            try:
                self._call(self.session, 'Stop')
            except Exception:
                pass
            self.session = None

    def motion(self, x, y):
        self._call(self.session, 'NotifyPointerMotionAbsolute',
                   self._GLib.Variant('(sdd)', (self.stream, float(x), float(y))))
        self.position = (float(x), float(y))

    def button(self, code, down):
        self._call(self.session, 'NotifyPointerButton',
                   self._GLib.Variant('(ib)', (int(code), bool(down))))

    def wheel(self, steps, axis=AXIS_VERTICAL):
        """One discrete wheel step per unit; negative scrolls the other way."""
        for _ in range(abs(int(steps))):
            self._call(self.session, 'NotifyPointerAxisDiscrete',
                       self._GLib.Variant('(ui)', (axis, 1 if steps > 0 else -1)))
            time.sleep(0.03)


def idle_ms():
    """Milliseconds since the last real user input, from GNOME's idle monitor.

    Returns None when the service is not there (then the caller must fall back).
    """
    result = subprocess.run(
        ['gdbus', 'call', '--session', '-d', 'org.gnome.Mutter.IdleMonitor',
         '-o', '/org/gnome/Mutter/IdleMonitor/Core', '-m',
         'org.gnome.Mutter.IdleMonitor.GetIdletime'],
        capture_output=True, text=True)
    if result.returncode != 0:
        return None
    digits = ''.join(c for c in result.stdout if c.isdigit())
    return int(digits) if digits else None


def session_type():
    return os.environ.get('XDG_SESSION_TYPE', 'unknown')
