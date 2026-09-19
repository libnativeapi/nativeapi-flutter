#!/usr/bin/env python3
"""GUI test (macOS) of the window_manager example: the 0.5.x compatible API on top of
nativeapi really resizes, moves, maximizes, renames and drags the window, and reads the
same numbers back that the OS reports.

    tools/gui/flutter_window_manager_test.py [--build] [--keep-open]

Built on the gui-test skill (.agents/skills). It takes over the mouse for ~30 s.
"""

import os
import re
import sys

from common import WORKSPACE
from guiapp import Abort, Checks, GuiApp, assert_idle, build_flutter, flutter_executable, pause

PROJECT = os.path.join(WORKSPACE, 'bindings', 'flutter', 'packages',
                       'window_manager', 'example')
NAME = 'window_manager_example'

# What main() asks waitUntilReadyToShow for, and what the chips ask for afterwards.
INITIAL = (820, 720)
RESIZED = (1000, 800)
DRAG_BY = (180, 120)


def main():
    if '--build' in sys.argv:
        build_flutter(PROJECT)
    assert_idle()
    app = GuiApp(flutter_executable(PROJECT, name=NAME),
                 args=['-ApplePersistenceIgnoreState', 'YES'])
    app.keep_open = '--keep-open' in sys.argv
    checks = Checks()
    app.launch(min_windows=1)
    try:
        def look():
            title = app.windows()[0][0]
            return title, app.window(title), next(
                v for v in app.views() if v.has('Full screen'))

        def reported():
            """What the state block says getBounds() answered: x, y, w, h."""
            _, _, view = look()
            line = next(t for t, _ in view.texts if t.startswith('getBounds()'))
            return [int(n) for n in re.findall(r'-?\d+', line)]

        def flag(name):
            _, _, view = look()
            return next(t for t, _ in view.texts if t.startswith(f'{name} ')) == f'{name} true'

        def press(label, settle=1.2):
            _, frame, view = look()
            x, y = app.to_screen(frame, view, view.center(label))
            app.click((round(x), round(y)))
            pause(settle)

        title, frame, _ = look()
        checks.near('waitUntilReadyToShow applied the size it was given',
                    frame[2:], INITIAL, tolerance=2)
        checks.check('and the title', title == 'window_manager example', title)

        press('1000 × 800')
        _, frame, _ = look()
        checks.near('setSize resized the real window', frame[2:], RESIZED, tolerance=2)
        checks.near('getBounds reads the same size back', reported()[2:], frame[2:], tolerance=2)

        press('top left')
        _, frame, _ = look()
        checks.near('getBounds reads the same position back', reported()[:2], frame[:2], tolerance=2)
        checks.check('setAlignment moved the window to the left of the screen',
                     frame[0] < 200, frame)

        press('center()')
        _, centered, _ = look()
        checks.check('center() moved it back towards the middle',
                     centered[0] > frame[0] + 100, (frame, centered))

        press('Maximize', settle=1.5)
        _, maximized, _ = look()
        checks.check('maximize enlarged the window',
                     maximized[2] > centered[2] and maximized[3] > centered[3],
                     (centered, maximized))
        checks.check('and isMaximized says so', flag('isMaximized'), maximized)

        press('Maximize', settle=1.5)
        checks.check('unmaximize is reported too', not flag('isMaximized'))

        press('你好')
        title, frame, _ = look()
        checks.check('setTitle renamed the real window', title == '你好', title)

        # The drag strip is nativeapi's DragToMoveArea: pressing it must move the window.
        _, frame, view = look()
        start = app.to_screen(frame, view, view.center('DragToMoveArea', prefix=True))
        target = (start[0] + DRAG_BY[0], start[1] + DRAG_BY[1])
        app.drag(start, (start[0] + 50, start[1] + 30, 400), (*target, 800))
        pause(1.5)
        _, moved, _ = look()
        checks.near('DragToMoveArea dragged the window',
                    moved[:2], (frame[0] + DRAG_BY[0], frame[1] + DRAG_BY[1]), tolerance=8)
        checks.near('and getBounds follows it', reported()[:2], moved[:2], tolerance=8)
    except Abort as e:
        checks.check('ran to the end', False, e)
    finally:
        app.quit()
    print(f'{checks.failures} failure(s); app log: {app.log_path}')
    return 1 if checks.failures else 0


if __name__ == '__main__':
    sys.exit(main())
