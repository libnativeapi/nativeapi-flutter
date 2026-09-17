#!/usr/bin/env python3
"""GUI test (macOS) of drag_drop_example: drag the note card (a file) and the text card
out of their DragOutArea onto the DropRegion of the same window, and check the region
lists what arrived, the source reports the operation, and the gesture state is clean
afterwards (a second drag works).

    tools/gui/flutter_drag_drop_test.py [--build] [--keep-open]

Built on the gui-test skill (.agents/skills). It takes over the mouse for ~15 s.
Dropping outside the window is not exercised: it would drop the note on another app.
"""

import sys

from common import build_example, example
from guiapp import Abort, Checks, assert_idle, pause

NAME = 'drag_drop_example'
TITLE = 'nativeapi · Drag and drop'
DROP = 'Drop files or text here'
NOTE = 'Drag this note'
TEXT = 'Drag this text'
FILE = 'nativeapi-drag-drop-note.txt'


def dropped_path(view):
    """The full path the drop list shows (the drag card only shows the file name)."""
    return next((t for t, _ in view.texts if t.endswith('/' + FILE)), None)


def main():
    if '--build' in sys.argv:
        build_example(NAME)
    assert_idle()
    app = example(NAME, args=['-ApplePersistenceIgnoreState', 'YES'])
    app.keep_open = '--keep-open' in sys.argv
    checks = Checks()
    app.launch(min_windows=1)
    try:
        def look():
            pause(0.3)
            frame = app.window(TITLE)
            view = next(v for v in app.views() if v.has('Drag out'))
            return frame, view

        def drag_card(card):
            frame, view = look()
            start = app.to_screen(frame, view, view.center(card))
            drop_area = view.find(DROP) or view.find('Release to drop')
            x, y, w, h = drop_area
            target = app.to_screen(frame, view, (x + w / 2, y + 120))
            app.drag(start, (start[0] - 30, start[1] + 10, 350),
                     (target[0] + 60, target[1], 700), (*target, 500), approach_ms=300)
            pause(1.2)

        frame, view = look()
        checks.check('both widgets report support',
                     sum(1 for t, _ in view.texts if t == 'Supported: true') == 2,
                     [t for t, _ in view.texts if t.startswith('Supported')])
        checks.check('nothing dropped yet', view.has('Drops: 0'))

        # 1. The note: a file.
        drag_card(NOTE)
        frame, view = look()
        checks.check('1 one drop', view.has('Drops: 1'),
                     [t for t, _ in view.texts if t.startswith('Drops')])
        checks.check('1 the note file arrived', dropped_path(view) is not None,
                     [t for t, _ in view.texts])
        checks.check('1 the source saw a copy', view.has('Last drag: copy'),
                     [t for t, _ in view.texts if t.startswith('Last drag')])
        checks.check('1 highlight is gone after the drop', view.has(DROP))

        # 2. The text: proves the first drag left no gesture stuck behind.
        drag_card(TEXT)
        frame, view = look()
        checks.check('2 second drop', view.has('Drops: 2'),
                     [t for t, _ in view.texts if t.startswith('Drops')])
        checks.check('2 the text arrived', view.has('Text: Hello from nativeapi'),
                     [t for t, _ in view.texts if t.startswith('Text')])
        checks.check('2 no file this time', dropped_path(view) is None)
        checks.check('2 the source saw a copy', view.has('Last drag: copy'))
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
