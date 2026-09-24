#!/usr/bin/env python3
"""GUI test (macOS) of detachable_window_example: tear a panel off, dock it into the
other window, check size, position and preserved state.

    tools/gui/flutter_detachable_window_test.py [--build]

Built on the gui-test skill (.agents/skills). It takes over the mouse for ~20 s.
"""

import sys

from common import build_example, example
from guiapp import Abort, Checks, assert_idle, pause

NAME = 'detachable_window_example'


def main():
    if '--build' in sys.argv:
        build_example(NAME)
    assert_idle()
    app = example(NAME)
    checks = Checks()
    app.launch(min_windows=2)
    try:
        def look():
            views = app.views()
            return (next(v for v in views if v.has('Window A')),
                    next(v for v in views if v.has('Window B')),
                    [v for v in views if not v.has('Window A') and not v.has('Window B')])

        frame_a = app.window('nativeapi · Window A')
        frame_b = app.window('nativeapi · Window B')
        view_a, view_b, _ = look()

        # State that has to survive the moves.
        plus = app.to_screen(frame_a, view_a, view_a.center('+1'))
        for _ in range(3):
            app.click(plus, 150)
            pause(0.15)

        # 1. Tear the Inspector off; drop it over the workspace so it stays a window.
        slot = view_a.find('Inspector')
        start = app.to_screen(frame_a, view_a, view_a.center('Inspector'))
        drop = (frame_a[0] + 470, frame_a[1] + 160)
        app.drag(start, (start[0] + 60, start[1] + 40, 150), (*drop, 400), approach_ms=200)
        pause(0.8)
        titles = [t for t, _ in app.windows()]
        checks.check('Inspector became its own window', 'Inspector' in titles, titles)
        view_a, view_b, floating = look()
        checks.check('one floating view', len(floating) == 1, len(floating))
        if floating:
            # The floating window's content is exactly as big as the slot it left (240 wide).
            checks.near('floating content width', floating[0].size[:1], (240,), 1)
            # The grabbed point stays under the cursor.
            frame_i = app.window('Inspector')
            grabbed = app.to_screen(frame_i, floating[0], floating[0].center('Inspector'))
            checks.near('header still under the cursor', grabbed, drop, 3)

            # 2. Dock it into Window B's wide sidebar.
            target = app.to_screen(frame_b, view_b, view_b.center('Wide sidebar'))
            app.drag(grabbed, (grabbed[0] + 200, grabbed[1] + 60, 300), (*target, 400),
                     approach_ms=200)
            pause(0.8)
            titles = [t for t, _ in app.windows()]
            checks.check('floating window is gone after docking', 'Inspector' not in titles, titles)
            view_a, view_b, floating = look()
            checks.check('Inspector now lives in Window B', view_b.has('Inspector'))

        # 3. The State object moved with it: same clicks, not a fresh panel.
        texts = [t for v in app.views() for t, _ in v.texts]
        checks.check('click count survived', any(t.startswith('Clicks') and '3' in t for t in texts),
                     [t for t in texts if t.startswith(('Clicks', 'State #'))])
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
