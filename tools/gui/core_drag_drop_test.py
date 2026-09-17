#!/usr/bin/env python3
"""GUI test (macOS) of core's drag_drop_example (C++): drag the example's file out of
the "Drag me" window onto the "Drop here" window (DragSource and DropTarget in one
gesture), then start a drag and release it where nothing accepts it.

    tools/gui/core_drag_drop_test.py [--build]

Built on the gui-test skill (.agents/skills). It takes over the mouse for ~15 s.
"""

import sys

from common import build_core_example, core_example
from guiapp import Abort, Checks, assert_idle, pause

NAME = 'drag_drop_example'
TITLE_BAR = 28  # enough to press below the title bar; positions use the real content origin


def center(frame):
    """The middle of a window's content (the title bar would start the system's own drag)."""
    x, y, w, h = frame
    return x + w / 2, y + TITLE_BAR + (h - TITLE_BAR) / 2


def frames(app):
    found = dict(app.windows())
    return found['Drop here'], found['Drag me']


def main():
    if '--build' in sys.argv:
        build_core_example(NAME)
    assert_idle()
    app = core_example(NAME)
    checks = Checks()
    app.launch(min_windows=2, flutter=False)
    try:
        drop, source = frames(app)

        # The example starts a drag when "Drag me" becomes focused: focus the other first.
        app.click(center(drop), 200)
        pause(0.5)

        # 1. Press in "Drag me", drag onto "Drop here", release there.
        start = center(source)
        target = center(drop)
        app.drag(start, (start[0] - 40, start[1] + 20, 400), (target[0] - 60, target[1], 700),
                 (*target, 500), approach_ms=300)
        pause(1.2)
        out = app.output()
        checks.check('1 drag started', 'Dragging ' in out)
        checks.check('1 target saw the drag enter', 'Entered at' in out)
        checks.check('1 target saw it move', 'Moved to' in out)
        checks.check('1 file dropped', 'file: ' in out and 'nativeapi-drag-drop-example.txt' in out)
        checks.check('1 text dropped', 'text: Hello from drag_drop_example' in out)
        checks.check('1 source reports a copy', 'Drag ended: copy' in out)
        lines = out.splitlines()
        dropped = next((l for l in lines if l.startswith('Dropped at')), '')
        # Position is relative to the content area: the drop point minus the content origin.
        origin = next((l for l in lines if l.startswith('Drop content at')), '')
        try:
            x, y = (float(v) for v in dropped[len('Dropped at ('):-1].split(', '))
            cx, cy = (float(v) for v in origin[len('Drop content at ('):-1].split(', '))
            expected = (target[0] - cx, target[1] - cy)
            checks.near('1 drop position is in content coordinates', (x, y), expected, 3)
        except ValueError:
            checks.check('1 drop position reported', False, dropped)

        # 2. Press in "Drag me", pass over "Drop here", come back and release on "Drag me",
        #    which accepts nothing.
        app.click(center(drop), 200)
        pause(0.5)
        drop, source = frames(app)
        before = len(app.output().splitlines())
        start = center(source)
        target = center(drop)
        app.drag(start, (start[0] - 40, start[1] + 20, 400), (*target, 700),
                 (start[0], start[1] + 30, 700), approach_ms=300)
        pause(1.5)  # AppKit animates the refused items back
        new = [l for l in app.output().splitlines()[before:] if not l.startswith('Moved to')]
        checks.check('2 target saw the drag enter and exit',
                     'Exited' in new and any(l.startswith('Entered at') for l in new), new)
        checks.check('2 nothing dropped', not any(l.startswith('Dropped at') for l in new), new)
        checks.check('2 source reports no operation', 'Drag ended: none' in new, new)

        # 3. The source window still takes clicks afterwards (the drag ended its gesture).
        app.click(center(drop), 200)
        pause(0.5)
        checks.check('3 app still responds', app.proc.poll() is None)
    except Abort as e:
        checks.check('ran to the end', False, e)
    finally:
        app.quit()
    for line in app.output().splitlines():
        if not line.startswith('Moved to'):
            print(f'app: {line}')
    print(f'{checks.failures} failure(s); app log: {app.log_path}')
    return 1 if checks.failures else 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except Abort as e:  # before the app was launched: machine in use
        sys.exit(f'Stopped: {e}')
