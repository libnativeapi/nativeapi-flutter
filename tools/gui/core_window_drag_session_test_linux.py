#!/usr/bin/env python3
"""GUI test (Linux) of core's window_drag_session_example (C++): carry the panel with
the cursor, dock it by dropping it on the dock window, tear it off again and check it
lands anchored under the cursor. The Linux twin of core_window_drag_session_test.py
(macOS) and core_window_drag_session_test.ps1 (Windows).

    tools/gui/core_window_drag_session_test_linux.py [--wayland] [--keep-open]

Runs on the host's desktop session through the remote-hosts skill:

    .agents/skills/remote-hosts/scripts/remote.sh linux desktop \
        tools/gui/core_window_drag_session_test_linux.py 180

The example is expected in $REMOTE_SCRATCH/core-build (build_core_example.sh) or, run
locally, in core/build. It takes over the mouse for ~30 s.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # the flat kit on a remote host

from guiapp import Abort, Checks, GuiApp, assert_idle, pause  # noqa: E402
from xinput import session_type  # noqa: E402

NAME = 'window_drag_session_example'
ANCHOR = (130, 12)  # where the example grabs the torn-off panel, from its frame corner


def executable():
    scratch = os.environ.get('REMOTE_SCRATCH')
    if scratch and os.path.exists(os.path.join(scratch, 'core-build')):
        return os.path.join(scratch, 'core-build', 'examples', NAME, NAME)
    workspace = os.environ.get('REMOTE_WORKSPACE') or os.path.dirname(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    return os.path.join(workspace, 'core', 'build', 'examples', NAME, NAME)


def content_point(app, title, fx=0.5, fy=0.6):
    """A point inside a window's content — never on the title bar, which the window
    manager drags itself."""
    x, y, w, h = app.window(title)
    bar = app.title_bar_height(title)
    return x + w * fx, y + bar + (h - bar) * fy


def titled(app, prefix):
    return next((t for t, _ in app.windows() if t.startswith(prefix)), None)


def main():
    backend = 'wayland' if '--wayland' in sys.argv else 'x11'
    assert_idle()
    app = GuiApp(executable(), backend=backend)
    app.keep_open = '--keep-open' in sys.argv
    checks = Checks()
    print(f'session: {session_type()}, app backend: {backend}', flush=True)
    try:
        app.launch(min_windows=2, flutter=False)
        for title, frame in app.windows():
            print(f'window: {title!r} frame={frame} title bar={app.title_bar_height(title)}',
                  flush=True)
        dock_title = titled(app, 'Dock')
        panel_title = titled(app, 'Panel')
        checks.check('0 both windows are up', dock_title and panel_title, app.windows())
        if not (dock_title and panel_title):
            raise Abort('the example did not show its two windows')

        # The example treats a focus change as the press: focus the dock first.
        app.click(content_point(app, dock_title))
        pause(0.6)

        # 1. Press in the panel and carry it: the grabbed point stays under the cursor.
        start = content_point(app, panel_title)
        before = app.window(panel_title)
        grab = (start[0] - before[0], start[1] - before[1])
        drop = (before[0] - 500, before[1] + 260)  # empty desktop, clear of the dock
        end = (drop[0] + grab[0], drop[1] + grab[1])
        app.drag(start, (start[0] - 120, start[1] + 60, 250), (*end, 450), approach_ms=250)
        pause(0.8)
        after = app.window(panel_title)
        checks.near('1 the panel followed the cursor', after[:2], drop, 3)

        # 2. Drag it onto the dock: it docks. The example starts a drag on a focus
        # change, so the dock has to hold the focus before the panel is pressed again.
        app.click(content_point(app, dock_title))
        pause(0.6)
        start = content_point(app, panel_title)
        app.drag(start, (start[0] + 100, start[1] - 40, 250),
                 (*content_point(app, dock_title), 450), approach_ms=250)
        pause(1.0)
        titles = [t for t, _ in app.windows()]
        checks.check('2 the panel window is gone once docked',
                     not any(t.startswith('Panel') for t in titles), titles)
        checks.check('2 the dock says it holds the panel', any('docked' in t for t in titles),
                     titles)

        # 3. Take the focus away, press inside the dock and drag out: tear off.
        app.blur()
        dock_title = titled(app, 'Dock')
        dock = app.window(dock_title)
        bar = app.title_bar_height(dock_title)
        start = (dock[0] + dock[2] / 3, dock[1] + bar + (dock[3] - bar) / 2)
        torn = (dock[0] + 320, max(120, dock[1] - 200))
        # The press is only felt once the window manager has moved the focus, a few
        # hundred milliseconds later: hold the button still until then, as a hand would.
        app.drag(start, (start[0] + 150, start[1] + 30, 250), (*torn, 450), approach_ms=250,
                 hold_until=lambda: app.is_focused(dock_title))
        pause(1.0)
        panel_title = titled(app, 'Panel')
        checks.check('3 the panel is a window again', panel_title is not None,
                     [t for t, _ in app.windows()])
        if panel_title:
            checks.near('3 the panel sits anchored under the cursor',
                        app.window(panel_title)[:2],
                        (torn[0] - ANCHOR[0], torn[1] - ANCHOR[1]), 3)
    except Abort as e:
        checks.check('ran to the end', False, e)
    finally:
        app.quit()
    output = app.output() if app.log_path else ''
    checks.check('output: panel docked', 'Panel docked' in output)
    checks.check('output: panel torn off', 'Panel torn off' in output)
    for line in output.splitlines():
        print(f'app: {line}')
    print(f'{checks.failures} failure(s); app log: {app.log_path}')
    return 1 if checks.failures else 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except Abort as e:  # before the app was launched: machine in use
        sys.exit(f'Stopped: {e}')
