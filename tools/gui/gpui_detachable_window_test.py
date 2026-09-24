#!/usr/bin/env python3
"""GUI test (macOS) of gpui_detachable_window_example: tear a panel off, check its
window's size and that the header stays under the cursor, dock it back by dragging,
pop one out with the button and dock it by closing its window.

    tools/gui/gpui_detachable_window_test.py [--build]

GPUI has no UI probe, so points come from the example's fixed layout (8 px padding,
a 260 px sidebar, a 220 px bottom slot). Built on the gui-test skill (.agents/skills).
It takes over the mouse for ~15 s.
"""

import os
import subprocess
import sys

from common import EXAMPLES
from guiapp import Abort, Checks, GuiApp, assert_idle, pause

PROJECT = os.path.join(EXAMPLES, 'gpui_detachable_window_example')
EXECUTABLE = os.path.join(PROJECT, 'target', 'debug', 'gpui_detachable_window_example')
MAIN = 'Detachable Window'
CONTENT = (960, 640)                  # main window content size
SIDEBAR = (8, 8, 260, CONTENT[1] - 16)  # slot rect in content coordinates
HEADER = (40, 20)                     # a point on a panel header, relative to its slot


def main():
    if '--build' in sys.argv:
        subprocess.run(['cargo', 'build'], check=True, cwd=PROJECT)
    assert_idle()
    app = GuiApp(EXECUTABLE)
    checks = Checks()
    app.launch(flutter=False)
    try:
        def titles():
            return [t for t, _ in app.windows()]

        def content_origin(frame, content_height):
            x, y, _, h = frame
            return x, y + h - content_height

        main_frame = app.window(MAIN)
        title_bar = main_frame[3] - CONTENT[1]
        mx, my = content_origin(main_frame, CONTENT[1])
        header = (mx + SIDEBAR[0] + HEADER[0], my + SIDEBAR[1] + HEADER[1])

        # 1. A click on the header is not a drag.
        app.click(header)
        pause(0.8)
        checks.check('a click opens no window', titles() == [MAIN], titles())

        # 2. Tear the Inspector off; drop it over the main content so it keeps floating.
        drop = (mx + 520, my + 200)
        app.drag(header, (header[0] + 60, header[1] + 40, 400), (*drop, 500), approach_ms=300)
        pause(1.0)
        checks.check('Inspector became its own window', 'Inspector' in titles(), titles())
        if 'Inspector' in titles():
            frame = app.window('Inspector')
            size = (frame[2], frame[3] - title_bar)
            checks.near('floating content is the slot size', size, SIDEBAR[2:], 1)
            fx, fy = content_origin(frame, size[1])
            checks.near('header still under the cursor', (fx + HEADER[0], fy + HEADER[1]), drop, 3)

            # 3. Drag it back over the empty sidebar slot: it docks and its window closes.
            grabbed = (fx + HEADER[0], fy + HEADER[1])
            target = (mx + SIDEBAR[0] + SIDEBAR[2] // 2, my + SIDEBAR[1] + SIDEBAR[3] // 2)
            app.drag(grabbed, (grabbed[0] - 60, grabbed[1] + 30, 400), (*target, 600),
                     approach_ms=300)
            pause(1.0)
            checks.check('docking closed the floating window', 'Inspector' not in titles(),
                         titles())

        # 4. Pop the Stopwatch out with its button, then close its window: it docks back.
        bottom_right = (mx + CONTENT[0] - 8, my + CONTENT[1] - 8 - 220)
        app.click((bottom_right[0] - 45, bottom_right[1] + 20))
        pause(1.0)
        checks.check('Pop out opened the Stopwatch window', 'Stopwatch' in titles(), titles())
        if 'Stopwatch' in titles():
            frame = app.window('Stopwatch')
            app.click((frame[0] + 20, frame[1] + title_bar // 2))  # the close button
            pause(1.0)
            checks.check('closing the window docked the Stopwatch', titles() == [MAIN], titles())
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
