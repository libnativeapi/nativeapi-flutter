#!/usr/bin/env python3
"""GUI test (Linux) of core's view_example (C++): a sign-in form of native controls
(Label, TextField, Button) laid out by a Column and a Row. The Linux twin of
core_view_test.py (macOS) and core_view_test.ps1 (Windows): the layout the example
prints, clicks on the real buttons, the focus event, and the re-flow after a resize.

    tools/gui/core_view_test_linux.py [--wayland] [--keep-open]

Runs on the host's desktop session through the remote-hosts skill:

    .agents/skills/remote-hosts/scripts/remote.sh linux desktop \\
        tools/gui/core_view_test_linux.py 180

The example is expected in $REMOTE_SCRATCH/core-build (build_core_example_linux.sh) or,
run locally, in core/build. It takes over the mouse for ~15 s and sends no keys.
"""

import ctypes
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # the flat kit on a remote host

from guiapp import Abort, Checks, GuiApp, assert_idle, pause  # noqa: E402
from xinput import session_type  # noqa: E402

NAME = 'view_example'
WINDOW = 'Sign in'
CONTENT = (360, 220)
PADDING, SPACING = 16, 8


def executable():
    scratch = os.environ.get('REMOTE_SCRATCH')
    if scratch and os.path.exists(os.path.join(scratch, 'core-build')):
        return os.path.join(scratch, 'core-build', 'examples', NAME, NAME)
    workspace = os.environ.get('REMOTE_WORKSPACE') or os.path.dirname(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    return os.path.join(workspace, 'core', 'build', 'examples', NAME, NAME)


def layouts(app):
    """{label: (x, y, w, h)} from the LAST "[view] layout" block the example printed."""
    out = {}
    for line in app.output().splitlines():
        m = re.match(r'\[view\] layout (\w+) (\S+) (\S+) (\S+) (\S+)', line)
        if m:
            if m.group(1) == 'root':
                out = {}
            out[m.group(1)] = tuple(float(v) for v in m.group(2, 3, 4, 5))
    return out


def statuses(app):
    return [l.split(': ', 1)[1] for l in app.output().splitlines()
            if l.startswith('[view] status: ')]


def near(checks, what, actual, expected, tolerance=2):
    checks.check(what, abs(actual - expected) <= tolerance, f'{actual} vs {expected}')


def control_center(app, layout, name):
    """Screen point of a control's centre: its root-relative logical frame, scaled by the
    client area against the root (GNOME's scale is per monitor)."""
    x, y, w, _ = next(c for t, c in app.contents() if t == WINDOW)
    scale = w / layout['root'][2]
    cx, cy, cw, ch = layout[name]
    return x + (cx + cw / 2) * scale, y + (cy + ch / 2) * scale


def click_control(app, layout, name):
    xid = next(w.xid for w in app._windows() if w.title == WINDOW)
    app.x.activate(xid)  # raise it over whatever else is on the desktop
    pause(0.4)
    point = control_center(app, layout, name)
    print(f'click {name} at {point[0]:.0f},{point[1]:.0f}', flush=True)
    app.click(point)


def resize_client(app, width, height):
    """XResizeWindow on the client window; the window manager keeps the frame around it."""
    xid = next(w.xid for w in app._windows() if w.title == WINDOW)
    x11 = app.x.x11
    x11.XResizeWindow.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.c_uint, ctypes.c_uint]
    x11.XResizeWindow(app.x.dpy, xid, int(width), int(height))
    app.x.flush()


def main():
    backend = 'wayland' if '--wayland' in sys.argv else 'x11'
    assert_idle()
    app = GuiApp(executable(), backend=backend)
    app.keep_open = '--keep-open' in sys.argv
    checks = Checks()
    print(f'session: {session_type()}, app backend: {backend}', flush=True)
    try:
        app.launch(min_windows=1, flutter=False)
        pause(0.5)
        layout = layouts(app)
        checks.check('layout printed for every control',
                     {'root', 'heading', 'name', 'password', 'status', 'actions', 'clear',
                      'sign_in'} <= set(layout), sorted(layout))
        near(checks, 'root is the content area (w)', layout['root'][2], CONTENT[0])
        near(checks, 'root is the content area (h)', layout['root'][3], CONTENT[1])
        content = next(c for t, c in app.contents() if t == WINDOW)
        near(checks, "client area has the root's aspect", content[3] / content[2],
             CONTENT[1] / CONTENT[0], 0.01)
        near(checks, 'heading starts at the padding', layout['heading'][1], PADDING)
        near(checks, 'heading spans the padded width', layout['heading'][2],
             CONTENT[0] - 2 * PADDING)
        h, n = layout['heading'], layout['name']
        near(checks, 'name follows the heading', n[1], h[1] + h[3] + SPACING)
        near(checks, 'password follows name', layout['password'][1], n[1] + n[3] + SPACING)
        checks.check('a text field has a height', n[3] > 10, n[3])
        near(checks, 'actions row is 32 high (preferred size)', layout['actions'][3], 32)
        s, c = layout['sign_in'], layout['clear']
        near(checks, 'sign in hugs the trailing edge', s[0] + s[2], CONTENT[0] - PADDING)
        near(checks, 'clear sits before sign in, spaced', c[0] + c[2] + SPACING, s[0])
        checks.check('buttons have an intrinsic width', 40 < s[2] < 140, s[2])

        click_control(app, layout, 'sign_in')
        pause(1.0)
        checks.check('empty sign-in is refused',
                     statuses(app)[-1:] == ['A username is required.'], statuses(app))
        checks.check('the refused sign-in focused the username field',
                     '[view] focused: name' in app.output())

        click_control(app, layouts(app), 'clear')
        pause(1.0)
        checks.check('clear resets the status',
                     statuses(app)[-1:] == ['Enter your credentials.'], statuses(app))

        scale = content[2] / CONTENT[0]
        resize_client(app, (CONTENT[0] + 120) * scale, (CONTENT[1] + 60) * scale)
        pause(1.5)
        # WindowResizedEvent arrives before GTK lays the content out, so the layout the
        # example printed for it is stale. Click where "Sign in" must be now — it hugs
        # the trailing edge, and the Column keeps its row where it was — and read the
        # layout printed with the status line.
        moved = dict(layout)
        moved['root'] = (0, 0, CONTENT[0] + 120, CONTENT[1] + 60)
        moved['sign_in'] = (s[0] + 120, s[1], s[2], s[3])
        click_control(app, moved, 'sign_in')
        pause(1.0)
        st = statuses(app)
        checks.check('sign in answers where the re-flow put it',
                     len(st) >= 3 and st[-1] == 'A username is required.', st)
        after = layouts(app)
        near(checks, 'root grew with the window (w)', after['root'][2], CONTENT[0] + 120)
        near(checks, 'root grew with the window (h)', after['root'][3], CONTENT[1] + 60)
        near(checks, 'heading re-stretched', after['heading'][2], CONTENT[0] + 120 - 2 * PADDING)
        s2 = after['sign_in']
        near(checks, 'sign in followed the trailing edge', s2[0] + s2[2],
             CONTENT[0] + 120 - PADDING)
        near(checks, 'button width unchanged by the resize', s2[2], s[2])
    except Abort as e:
        checks.check('ran to the end', False, e)
    finally:
        app.quit()
    for line in app.output().splitlines():
        if not line.startswith('[view] layout'):
            print(f'app: {line}')
    print(f'{checks.failures} failure(s); app log: {app.log_path}')
    return 1 if checks.failures else 0


if __name__ == '__main__':
    sys.exit(main())
