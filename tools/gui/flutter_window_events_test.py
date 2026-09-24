#!/usr/bin/env python3
"""GUI test (macOS) of window_example: WindowManager's listener is called for the window
events the OS produces — focused when the app is activated, moved and resized when the
window's frame changes — and the payloads are what the window really has afterwards
(nativeapi-flutter#12: the listener never fired for anything but focus).

    tools/gui/flutter_window_events_test.py [--build] [--keep-open]

Built on the gui-test skill (.agents/skills). One click (the "Events" tab, so the log
is on screen); the frame is changed through Accessibility, with no input involved.
"""

import re
import sys

from common import build_example, example
from guiapp import Abort, Checks, assert_idle, pause

NAME = 'window_example'
TAB = 'Events'

# Two frames that differ in position and in size, both well inside a laptop screen.
FIRST = (120, 100, 900, 640)
SECOND = (220, 160, 1040, 720)


def log_lines(view):
    """The event log, newest first: "Window #<id> <what>" lines the view shows."""
    return [t for t, _ in view.texts if t.startswith('Window #')]


def main():
    if '--build' in sys.argv:
        build_example(NAME)
    assert_idle()
    app = example(NAME, args=['-ApplePersistenceIgnoreState', 'YES'])
    app.keep_open = '--keep-open' in sys.argv
    checks = Checks()
    app.launch(min_windows=1)
    try:
        title = app.windows()[0][0]

        def look():
            return app.window(title), next(v for v in app.views() if v.has(TAB))

        # Park the window first: the move and resize under test then start from a frame
        # this script knows, whatever the example's default is.
        app.set_frame(*FIRST)
        frame, view = look()
        app.click(app.to_screen(frame, view, view.center(TAB)))
        pause(1.0)

        _, view = look()
        before = log_lines(view)
        checks.check('focused was logged when the app was activated',
                     any(line.endswith(' focused') for line in before), before[:6])

        app.set_frame(*SECOND)
        pause(1.2)
        frame, view = look()
        lines = log_lines(view)

        moved = next((m for m in (re.search(r'moved to (-?\d+), (-?\d+)$', line)
                                  for line in lines) if m), None)
        resized = next((m for m in (re.search(r'resized to (\d+) x (\d+)$', line)
                                    for line in lines) if m), None)
        checks.check('a moved event reached the Dart listener', moved is not None, lines[:6])
        checks.check('a resized event reached the Dart listener', resized is not None, lines[:6])
        if moved:
            checks.near('moved reports where the window is now',
                        [int(v) for v in moved.groups()], frame[:2])
        if resized:
            checks.near('resized reports the size the window has now',
                        [int(v) for v in resized.groups()], frame[2:])
        checks.near('the window really is where it was sent', frame, SECOND)
    except Abort as e:
        checks.check('ran to the end', False, e)
    finally:
        app.quit()
    print(f'{checks.failures} failure(s); app log: {app.log_path}')
    return 1 if checks.failures else 0


if __name__ == '__main__':
    sys.exit(main())
