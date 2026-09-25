#!/usr/bin/env python3
"""GUI test (macOS) of gpui_window_drag_areas_example: the bar moves the window
(Window::start_dragging) and a click on it does not, a double click maximizes and
restores, and the resize handles (Window::start_resizing) move exactly the edges they
own.

    tools/gui/gpui_window_drag_areas_test.py [--build]

GPUI has no UI probe, so points come from the example's fixed layout: no title bar,
handle bands 12 px wide inset 16 px, the bar at y 28..72. Built on the gui-test skill
(.agents/skills). It takes over the mouse for ~20 s.
"""

import sys
import time

from common import build_gpui_example, gpui_example
from guiapp import Abort, Checks, assert_idle, pause

NAME = 'window_drag_areas_example'
TITLE = 'nativeapi · Drag areas'
BAND = 16 + 12 / 2  # middle of a handle band, from the window edge
BAR_Y = 50          # middle of the move bar
# A drag or resize starts once the pointer has moved 2 px with the button down, so the
# window trails the gesture by that much.
SLOP = 3


def main():
    if '--build' in sys.argv:
        build_gpui_example(NAME)
    assert_idle()
    app = gpui_example(NAME, args=['-ApplePersistenceIgnoreState', 'YES'])
    checks = Checks()
    app.launch(flutter=False)
    try:
        def look():
            """The frame once it has stopped changing (a maximize animates)."""
            frame, still, deadline = app.window(TITLE), 0, time.time() + 3
            while still < 3 and time.time() < deadline:
                pause(0.1)
                last, frame = frame, app.window(TITLE)
                still = still + 1 if frame == last else 0
            return frame

        # 1. A click on the bar does not move the window.
        x, y, w, h = look()
        bar = (x + w / 2, y + BAR_Y)
        app.click(bar)
        checks.check('a click on the bar does not move the window', look() == (x, y, w, h),
                     look())

        # 2. Dragging the bar moves the window by the same amount; the size stays.
        app.drag(bar, (bar[0] + 20, bar[1] + 10, 300), (bar[0] + 90, bar[1] + 50, 500))
        moved = look()
        checks.near('bar drag moves the window', moved[:2], (x + 90, y + 50), SLOP)
        checks.near('bar drag keeps the size', moved[2:], (w, h), 1)

        # 3. Bottom-right handle: only the right and bottom edges follow.
        x, y, w, h = moved
        corner = (x + w - BAND, y + h - BAND)
        app.drag(corner, (corner[0] + 20, corner[1] + 10, 300), (corner[0] + 60, corner[1] + 40, 500))
        grown = look()
        checks.near('bottom-right handle: origin stays', grown[:2], (x, y), 1)
        checks.near('bottom-right handle: size follows', grown[2:], (w + 60, h + 40), SLOP)

        # 4. Left handle: the left edge follows, the right edge stays.
        x, y, w, h = grown
        left = (x + BAND, y + h / 2)
        app.drag(left, (left[0] - 20, left[1], 300), (left[0] - 50, left[1] + 20, 500))
        wider = look()
        checks.near('left handle: left edge follows', wider[:1], (x - 50,), SLOP)
        checks.near('left handle: right edge stays', (wider[0] + wider[2],), (x + w,), 1)
        checks.near('left handle: top and height stay', (wider[1], wider[3]), (y, h), 1)

        # 5. A double click on the bar maximizes, a second one restores.
        before = wider
        bar = (before[0] + before[2] / 2, before[1] + BAR_Y)
        app.double_click(bar)
        maximized = look()
        visible = app.visible_frame(bar)
        checks.check('double click maximizes',
                     maximized[2] >= visible[2] - 2 and maximized[3] >= visible[3] - 2,
                     f'{maximized} in {visible}')
        app.double_click((maximized[0] + maximized[2] / 2, maximized[1] + BAR_Y))
        checks.near('second double click restores', look(), before, 2)
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
