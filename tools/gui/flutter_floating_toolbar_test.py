#!/usr/bin/env python3
"""GUI test (macOS) of floating_toolbar_example: a second Flutter window, made a child of
the main one with Window.setParentWindow, stays centred above it — when the main window
is moved and resized through Accessibility, and when it is dragged by its title bar with
the real mouse — stops following once detached, is not brought back while hidden, and
shares state with the main window (a press in the toolbar counts up in the main window).

    tools/gui/flutter_floating_toolbar_test.py [--build] [--no-input] [--keep-open]

Built on the gui-test skill (.agents/skills). --no-input runs only the part that needs no
mouse: placement, following a move and a resize.
"""

import sys

from common import build_example, example, screen_color
from guiapp import Abort, Checks, assert_idle, pause

NAME = 'floating_toolbar_example'
MAIN = 'Floating toolbar'
TOOLBAR = 'Toolbar'
GAP = 10  # _toolbarGap in the example

FIRST = (300, 260, 720, 552)
MOVED = (420, 330, 720, 552)
RESIZED = (420, 330, 900, 620)


def expected_toolbar(main, toolbar):
    """Where the toolbar belongs: centred above the main window."""
    return [main[0] + (main[2] - toolbar[2]) / 2, main[1] - toolbar[3] - GAP]


def main():
    if '--build' in sys.argv:
        build_example(NAME)
    use_input = '--no-input' not in sys.argv
    if use_input:
        assert_idle()
    app = example(NAME, args=['-ApplePersistenceIgnoreState', 'YES'])
    app.keep_open = '--keep-open' in sys.argv
    checks = Checks()
    app.launch(min_windows=2)
    try:
        def placed(what):
            main_frame, toolbar = app.window(MAIN), app.window(TOOLBAR)
            checks.near(what, toolbar[:2], expected_toolbar(main_frame, toolbar), 3)

        def view_of(text):
            return next(v for v in app.views() if v.has(text))

        def press(title, text):
            view = view_of(text)
            app.click(app.to_screen(app.window(title), view, view.center(text)))
            pause(1.0)

        placed('the toolbar starts centred above the main window')
        checks.check('the toolbar is as small as it was asked to be',
                     app.window(TOOLBAR)[2:] == (380, 64), app.window(TOOLBAR))

        # Transparent: the corner of the toolbar window, outside the rounded pill, shows
        # what is behind the window - the same as just outside of it - not a black backing.
        x, y, w, h = app.window(TOOLBAR)
        inside, outside = screen_color(x + 3, y + 3), screen_color(x - 8, y + 3)
        checks.check('the toolbar window is see-through around the pill',
                     max(abs(a - b) for a, b in zip(inside, outside)) <= 24,
                     f'corner {inside}, just outside {outside}')

        app.set_frame(*FIRST, title=MAIN)
        pause(0.8)
        checks.near('the main window went where it was sent', app.window(MAIN)[:2], FIRST[:2])
        placed('the toolbar followed a move')

        app.set_frame(*RESIZED, title=MAIN)
        pause(0.8)
        placed('the toolbar is centred again after a move and a resize')

        if use_input:
            checks.check('the main window starts at zero', view_of('Stamps: 0') is not None)
            press(TOOLBAR, 'Stamp')
            checks.check('a press in the toolbar window counts in the main window',
                         any(v.has('Stamps: 1') for v in app.views()))

            # The real thing: the user drags the main window by its title bar.
            frame = app.window(MAIN)
            grab = (frame[0] + frame[2] // 2, frame[1] + 14)
            app.drag(grab, (grab[0] + 40, grab[1] + 20, 400), (grab[0] - 170, grab[1] + 90, 600))
            pause(1.2)
            after = app.window(MAIN)
            checks.near('the main window was dragged', after[:2], [frame[0] - 170, frame[1] + 90], 4)
            placed('the toolbar followed a drag of the title bar')

            press(MAIN, 'Detach toolbar')
            before = app.window(TOOLBAR)
            app.set_frame(*MOVED, title=MAIN)
            pause(0.8)
            checks.near('a detached toolbar stays where it is', app.window(TOOLBAR)[:2], before[:2])
            press(MAIN, 'Attach toolbar')
            placed('attaching brings the toolbar back above the main window')

            press(MAIN, 'Hide toolbar')
            titles = [t for t, _ in app.windows()]
            checks.check('the hidden toolbar is gone', TOOLBAR not in titles, titles)
            app.set_frame(*FIRST, title=MAIN)
            pause(0.8)
            titles = [t for t, _ in app.windows()]
            checks.check('moving its parent does not bring a hidden toolbar back',
                         TOOLBAR not in titles, titles)
            press(MAIN, 'Show toolbar')
            placed('the toolbar shown again is above the main window')
            app.set_frame(*MOVED, title=MAIN)
            pause(0.8)
            placed('and follows again')
    except (Abort, LookupError, StopIteration) as e:
        checks.check('ran to the end', False, repr(e))
    finally:
        app.quit()
    print(f'{checks.failures} failure(s); app log: {app.log_path}')
    return 1 if checks.failures else 0


if __name__ == '__main__':
    sys.exit(main())
