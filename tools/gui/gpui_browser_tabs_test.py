#!/usr/bin/env python3
"""GUI test (macOS) of gpui_browser_tabs_example: tear a tab off into a window of its
own, move that window by its empty strip, merge its tab into the other window's strip.

    tools/gui/gpui_browser_tabs_test.py [--build]

GPUI has no UI probe, so points come from the example's strip layout (content under
the title bar; tabs from x 78, 40 px strip, width clamp((W - 126) / n, 72, 220)).
Built on the gui-test skill (.agents/skills). It takes over the mouse for ~15 s.
"""

import sys
import time

from common import build_gpui_example, gpui_example
from guiapp import Abort, Checks, assert_idle, pause

NAME = 'browser_tabs_example'
TITLE = 'Browser'
LEADING, TRAILING_RESERVE, NEW_TAB = 78, 126, 40
TAB_Y = 23  # middle of a tab


def tab_width(window_width, tabs):
    return max(72, min(220, (window_width - TRAILING_RESERVE) / tabs))


def tab_center(frame, tabs, index):
    x, y, w, _ = frame
    width = tab_width(w, tabs)
    return (x + LEADING + width * (index + 0.5), y + TAB_Y)


def main():
    if '--build' in sys.argv:
        build_gpui_example(NAME)
    assert_idle()
    app = gpui_example(NAME, args=['-ApplePersistenceIgnoreState', 'YES'])
    checks = Checks()
    app.launch(min_windows=2, flutter=False)
    try:
        def frames():
            result, deadline = app.windows(), time.time() + 3
            while time.time() < deadline:
                pause(0.2)
                last, result = result, app.windows()
                if result == last:
                    break
            return sorted(f for t, f in result if t == TITLE)

        first, second = frames()  # sorted by x: the 4-tab window is on the left

        # 1. Tear the last tab of the 4-tab window off, well below the strip.
        start = tab_center(first, 4, 3)
        drop = (start[0] + 40, start[1] + 220)
        app.drag(start, (start[0], start[1] + 30, 300), (*drop, 600))
        after = frames()
        checks.check('tear-off opened a third window', len(after) == 3, after)
        torn = [f for f in after if f not in (first, second)]
        if len(torn) == 1:
            torn = torn[0]
            grabbed = tab_center(torn, 1, 0)
            checks.near('the torn tab is under the cursor', grabbed, drop,
                        tab_width(torn[2], 1) / 2)

            # 2. Move the torn-off window by the empty part of its strip.
            strip = (torn[0] + LEADING + tab_width(torn[2], 1) + NEW_TAB + 80, torn[1] + 20)
            app.drag(strip, (strip[0] + 20, strip[1] + 10, 300), (strip[0] + 100, strip[1] + 60, 500))
            moved = [f for f in frames() if f not in (first, second)]
            checks.check('strip drag moved the window',
                         len(moved) == 1 and abs(moved[0][0] - torn[0] - 100) <= 3
                         and abs(moved[0][1] - torn[1] - 60) <= 3, moved)

            # 3. Merge its only tab into the 2-tab window's strip.
            if len(moved) == 1:
                start = tab_center(moved[0], 1, 0)
                target = tab_center(second, 2, 1)
                app.drag(start, (start[0] + 20, start[1] + 20, 300),
                         (target[0], target[1] + 60, 500), (target[0] + 10, target[1], 500))
                after = frames()
                checks.check('merging closed the torn-off window', len(after) == 2, after)
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
