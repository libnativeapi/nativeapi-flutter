#!/usr/bin/env python3
"""GUI test (macOS) of core's window_drag_session_example (C++): dock the panel by
dragging it onto the dock window, tear it off again, check it lands anchored under the
cursor. The macOS twin of core_window_drag_session_test.ps1.

    tools/gui/core_window_drag_session_test.py [--build]

Built on the gui-test skill (.agents/skills). It takes over the mouse for ~15 s.
"""

import sys

from common import build_core_example, core_example
from guiapp import Abort, Checks, assert_idle, pause

NAME = 'window_drag_session_example'
ANCHOR = (130, 12)  # where the example grabs the torn-off panel, from its frame corner


def center(frame, title_bar=28):
    """The middle of a window's content (the title bar would start the system's own drag)."""
    x, y, w, h = frame
    return x + w / 2, y + title_bar + (h - title_bar) / 2


def main():
    if '--build' in sys.argv:
        build_core_example(NAME)
    assert_idle()
    app = core_example(NAME)
    checks = Checks()
    app.launch(min_windows=2, flutter=False)
    skipped = False
    try:
        frames = dict(app.windows())
        dock = next(f for t, f in frames.items() if t.startswith('Dock'))
        panel = next(f for t, f in frames.items() if t.startswith('Panel'))

        # The example treats a focus change as the press: focus the dock first.
        app.click(center(dock), 200)
        pause(0.5)

        # 1. Drag the panel (pressed inside its content) onto the dock.
        start = center(panel)
        app.drag(start, (start[0] - 100, start[1] + 20, 200), (*center(dock), 400),
                 approach_ms=200)
        pause(0.8)
        titles = [t for t, _ in app.windows()]
        checks.check('1 panel window is gone once docked',
                     not any(t.startswith('Panel') for t in titles), titles)
        checks.check('1 dock says it holds the panel', any('docked' in t for t in titles), titles)

        # 2. Take the focus away, then press inside the dock and drag out: tear off.
        app.blur()
        dock = next(f for t, f in app.windows() if t.startswith('Dock'))
        start = (dock[0] + dock[2] / 3, center(dock)[1])
        end = (dock[0] + 300, max(60, dock[1] - 120))
        try:
            app.drag(start, (start[0] + 150, start[1] + 30, 250), (*end, 400),
                     approach_ms=200)
        except Abort as e:
            print(f'SKIP 2 tear-off: {e}', flush=True)
            skipped = True
        if not skipped:
            pause(0.8)
            panel = next((f for t, f in app.windows() if t.startswith('Panel')), None)
            checks.check('2 panel is a window again', panel is not None)
            if panel:
                checks.near('2 panel sits anchored under the cursor', panel[:2],
                            (end[0] - ANCHOR[0], end[1] - ANCHOR[1]), 2)
    except Abort as e:
        checks.check('ran to the end', False, e)
    finally:
        app.quit()
    output = app.output()
    checks.check('output: panel docked', 'Panel docked' in output)
    if not skipped:
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
