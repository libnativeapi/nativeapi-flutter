#!/usr/bin/env python3
"""Save one frame of the GNOME/Wayland screen as PNG: Mutter ScreenCast -> PipeWire -> gst.
usage: wayland_shot.py out.png   (run inside the desktop session; sends no input)"""
import subprocess
import sys

import gi
gi.require_version('Gio', '2.0')
from gi.repository import Gio, GLib  # noqa: E402

out = sys.argv[1]
bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)


def proxy(name, path, iface):
    return Gio.DBusProxy.new_sync(bus, Gio.DBusProxyFlags.NONE, None, name, path, iface, None)


def call(p, method, args=None):
    return p.call_sync(method, args, Gio.DBusCallFlags.NONE, -1, None)


config = proxy('org.gnome.Mutter.DisplayConfig', '/org/gnome/Mutter/DisplayConfig',
               'org.gnome.Mutter.DisplayConfig')
connector = call(config, 'GetCurrentState').unpack()[1][0][0][0]
remote = proxy('org.gnome.Mutter.RemoteDesktop', '/org/gnome/Mutter/RemoteDesktop',
               'org.gnome.Mutter.RemoteDesktop')
session = proxy('org.gnome.Mutter.RemoteDesktop', call(remote, 'CreateSession').unpack()[0],
                'org.gnome.Mutter.RemoteDesktop.Session')
session_id = session.get_cached_property('SessionId').unpack()
cast = proxy('org.gnome.Mutter.ScreenCast', '/org/gnome/Mutter/ScreenCast',
             'org.gnome.Mutter.ScreenCast')
cast_session = proxy('org.gnome.Mutter.ScreenCast', call(cast, 'CreateSession', GLib.Variant(
    '(a{sv})', [{'remote-desktop-session-id': GLib.Variant('s', session_id)}])).unpack()[0],
    'org.gnome.Mutter.ScreenCast.Session')
stream_path = call(cast_session, 'RecordMonitor', GLib.Variant('(sa{sv})', (
    connector, {'cursor-mode': GLib.Variant('u', 0)}))).unpack()[0]

loop = GLib.MainLoop()
result = {'code': 1}


def on_stream(_c, _s, _p, _i, _sig, params):
    node = params.unpack()[0]
    result['code'] = subprocess.run(
        ['gst-launch-1.0', '-q', 'pipewiresrc', f'path={node}', 'num-buffers=1', '!',
         'videoconvert', '!', 'pngenc', 'snapshot=false', '!', 'multifilesink',
         f'location={out}'], timeout=30).returncode
    loop.quit()


bus.signal_subscribe('org.gnome.Mutter.ScreenCast', 'org.gnome.Mutter.ScreenCast.Stream',
                     'PipeWireStreamAdded', stream_path, None, Gio.DBusSignalFlags.NONE, on_stream)
call(session, 'Start')
GLib.timeout_add_seconds(20, loop.quit)
loop.run()
try:
    call(session, 'Stop')
except Exception:
    pass
sys.exit(result['code'])
