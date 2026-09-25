#!/usr/bin/env python3
"""GUI test (macOS) of gpui_floating_toolbar_example: the toolbar window (attached with
Window::set_parent_window) starts centred 10 px above the main window and follows it
when the main window is dragged by its title bar and resized from its corner.

    tools/gui/gpui_floating_toolbar_test.py [--build]

Built on the gui-test skill (.agents/skills). It takes over the mouse for ~10 s.
"""

import sys
import time

from common import build_gpui_example, gpui_example
from guiapp import Abort, Checks, assert_idle, pause

NAME = 'floating_toolbar_example'
MAIN = 'Floating toolbar'
TOOLBAR = 'Toolbar'
TOOLBAR_SIZE = (380, 64)
GAP = 10


def expected(main):
    x, y, w, _ = main
    return (x + (w - TOOLBAR_SIZE[0]) // 2, y - GAP - TOOLBAR_SIZE[1], *TOOLBAR_SIZE)


def main():
    if '--build' in sys.argv:
        build_gpui_example(NAME)
    assert_idle()
    app = gpui_example(NAME, args=['-ApplePersistenceIgnoreState', 'YES'])
    checks = Checks()
    app.launch(min_windows=2, flutter=False)
    try:
        def settled():
            frames, deadline = app.windows(), time.time() + 3
            while time.time() < deadline:
                pause(0.2)
                last, frames = frames, app.windows()
                if frames == last:
                    break
            return dict(frames)

        frames = settled()
        checks.near('toolbar starts centred above', frames[TOOLBAR], expected(frames[MAIN]), 2)

        # 1. Drag the main window by its title bar (right of the title text).
        x, y, w, h = frames[MAIN]
        grab = (x + w - 120, y + 14)
        app.drag(grab, (grab[0] - 30, grab[1] + 20, 300), (grab[0] - 140, grab[1] + 70, 500))
        frames = settled()
        checks.near('main window moved', frames[MAIN][:2], (x - 140, y + 70), 3)
        checks.near('toolbar followed the move', frames[TOOLBAR], expected(frames[MAIN]), 2)

        # 2. Resize the main window from its bottom-right corner.
        x, y, w, h = frames[MAIN]
        corner = (x + w - 3, y + h - 3)
        app.drag(corner, (corner[0] + 20, corner[1] + 10, 300), (corner[0] + 90, corner[1] + 40, 500))
        frames = settled()
        checks.near('main window resized', frames[MAIN][2:], (w + 90, h + 40), 3)
        checks.near('toolbar re-centred after the resize', frames[TOOLBAR],
                    expected(frames[MAIN]), 2)
    except Abort as e:
        checks.check('ran to the end', False, e)
    finally:
        app.quit()
    print(f'{checks.failures} failure(s); app log: {app.log_path}')
    return 1 if checks.failures else 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except Abort as e:  # before the app was launched: machine in use
        sys.exit(f'Stopped: {e}')
