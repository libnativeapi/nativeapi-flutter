#!/usr/bin/env python3
"""GUI test (macOS) of window_drag_areas_example: DragToMoveArea moves the window and
toggles maximization on a double click; DragToResizeArea resizes from all eight handles,
keeps the opposite edge anchored, respects the minimum size and the enabled-edge list,
and lets the pointer through in the middle.

    tools/gui/flutter_window_drag_areas_test.py [--build] [--keep-open]

Built on the gui-test skill (.agents/skills). It takes over the mouse for ~75 s.
"""

import sys

from common import build_example, example
from guiapp import Abort, Checks, assert_idle, pause

NAME = 'window_drag_areas_example'
TITLE = 'nativeapi · Drag areas'
BAR = 'Drag here to move'

# kResizeEdgeInset + kResizeEdgeSize / 2 of the example: the middle of a handle band,
# measured from the window edge.
BAND = 16 + 12 / 2
MIN_SIZE = (480, 320)  # window.minimumSize of the example

# A resize follows the mouse to the pixel; a move starts a few pixels after the press (the
# pan slop), so the window travels slightly less than the gesture is long (3 px measured).
SLOP = 5

# handle: (where it is, as fractions of the view; mouse travel; the frame edges that follow
# the mouse: l, t, r, b). The edges travel outwards with an off-axis component that must be
# ignored; the corners travel back inwards, so the window ends as big as it started.
HANDLES = {
    'left': ((0, .5), (-60, 25), 'l'),
    'right': ((1, .5), (60, -25), 'r'),
    'top': ((.5, 0), (25, -40), 't'),
    'bottom': ((.5, 1), (-25, 40), 'b'),
    'topLeft': ((0, 0), (30, 20), 'lt'),
    'topRight': ((1, 0), (-30, 20), 'rt'),
    'bottomLeft': ((0, 1), (30, -20), 'lb'),
    'bottomRight': ((1, 1), (-30, -20), 'rb'),
}


def edges(frame):
    x, y, w, h = frame
    return {'l': x, 't': y, 'r': x + w, 'b': y + h}


def main():
    if '--build' in sys.argv:
        build_example(NAME)
    assert_idle()
    # AppKit would otherwise reopen the window with the frame the previous run left behind.
    app = example(NAME, args=['-ApplePersistenceIgnoreState', 'YES'])
    app.keep_open = '--keep-open' in sys.argv
    checks = Checks()
    app.launch(min_windows=1)
    try:
        def look():
            """(frame, view) as they are now; never reuse them across a gesture."""
            return app.window(TITLE), next(v for v in app.views() if v.has(BAR))

        def handle_point(frame, view, where):
            w, h = view.size
            fx, fy = where
            point = (BAND + fx * (w - 2 * BAND), BAND + fy * (h - 2 * BAND))
            return app.to_screen(frame, view, point)

        def drag_by(start, dx, dy):
            """Two legs: a short one past the drag threshold, then the rest."""
            app.drag(start, (start[0] + dx / 4, start[1] + dy / 4, 350),
                     (start[0] + dx, start[1] + dy, 700))
            pause(1.2)

        def shows_size(view, frame):
            return view.has(f'Size: {frame[2]} x {frame[3]}')

        frame, view = look()
        # Hidden title bar: the Flutter view is the whole window, at the size the example asked for.
        checks.near('window opens at 720 x 480 without a title bar', view.size, frame[2:], 1)
        checks.near('content size', frame[2:], (720, 480), 1)

        # 1. The middle of the resize area lets the pointer through to the child.
        for _ in range(2):
            app.click(app.to_screen(frame, view, view.center('+1')), 350)
            pause(0.4)
        frame, view = look()
        checks.check('clicks reach the child through the resize area', view.has('Clicks: 2'),
                     [t for t, _ in view.texts if t.startswith('Clicks')])

        # 2. Every handle resizes its own edge(s) and nothing else.
        for name, (where, travel, moving) in HANDLES.items():
            before, view = look()
            drag_by(handle_point(before, view, where), *travel)
            after, view = look()
            was, now = edges(before), edges(after)
            for edge in 'ltrb':
                if edge in moving:
                    checks.near(f'{name}: {edge} edge follows the mouse', (now[edge],),
                                (was[edge] + travel[edge in 'tb'],), SLOP)
                else:  # not an inch, whatever the mouse did off-axis
                    checks.near(f'{name}: {edge} edge stays put', (now[edge],), (was[edge],), 1)
            checks.check(f'{name}: Flutter relaid out at the new size', shows_size(view, after),
                         [t for t, _ in view.texts if t.startswith('Size')])

        # 3. The minimum size stops the resize, and the anchored edge still does not move.
        before, view = look()
        drag_by(handle_point(before, view, HANDLES['right'][0]), -(before[2] - MIN_SIZE[0] + 150), 0)
        after, view = look()
        checks.near('right: stops at the minimum width', after, (*before[:2], MIN_SIZE[0], before[3]), 1)
        drag_by(handle_point(after, view, HANDLES['right'][0]), 240, 0)
        after, view = look()
        checks.near('right: grows back from the minimum', after, (*before[:2], MIN_SIZE[0] + 240, before[3]), SLOP)

        # 4. enableResizeEdges: a disabled handle is gone, an enabled one still works.
        app.click(app.to_screen(after, view, view.center('Edges: all')), 400)
        pause(0.6)
        before, view = look()
        checks.check('edge list switched', view.has('Edges: right and bottom'))
        drag_by(handle_point(before, view, HANDLES['left'][0]), -60, 0)
        after, view = look()
        checks.near('left (disabled): nothing happens', after, before, 0)
        drag_by(handle_point(after, view, HANDLES['bottomRight'][0]), 40, 30)
        before = after
        after, view = look()
        checks.near('bottomRight (still enabled): resizes', after,
                    (before[0], before[1], before[2] + 40, before[3] + 30), SLOP)

        # 5. DragToMoveArea: the window follows the mouse, its size untouched.
        before, view = look()
        start = app.to_screen(before, view, view.center(BAR))
        travel = (120, -80)
        drag_by(start, *travel)
        after, view = look()
        checks.near('move: window follows the mouse', after[:2],
                    (before[0] + travel[0], before[1] + travel[1]), SLOP)
        checks.near('move: size unchanged', after[2:], before[2:], 0)
        grabbed = app.to_screen(after, view, view.center(BAR))
        checks.near('move: the grabbed point is still under the cursor', grabbed,
                    (start[0] + travel[0], start[1] + travel[1]), SLOP)

        # 6. A plain click must not start a drag: move away afterwards without a button.
        before, view = look()
        bar = app.to_screen(before, view, view.center(BAR))
        app.click(bar)
        pause(0.8)  # past the double-tap window, so the next test starts from scratch
        app.move((bar[0] + 140, bar[1] + 90), 600)
        pause(0.8)
        after, view = look()
        checks.near('click: window does not move or stick to the cursor', after, before, 0)

        # 7. A double click maximizes; another one restores the frame it had.
        before, view = look()
        app.double_click(app.to_screen(before, view, view.center(BAR)))
        pause(1.5)  # zoom animation
        zoomed, view = look()
        checks.check('double click: maximized', zoomed[2] > before[2] and zoomed[3] > before[3],
                     f'{before} -> {zoomed}')
        checks.check('double click: Flutter relaid out at the new size', shows_size(view, zoomed),
                     [t for t, _ in view.texts if t.startswith('Size')])
        app.double_click(app.to_screen(zoomed, view, view.center(BAR)))
        pause(1.5)
        after, view = look()
        checks.near('double click again: restored', after, before, 1)

        checks.check('state untouched by all of it', view.has('Clicks: 2'),
                     [t for t, _ in view.texts if t.startswith('Clicks')])
    except (Abort, LookupError, StopIteration) as e:
        checks.check('ran to the end', False, repr(e))
    finally:
        app.quit()
    print(f'{checks.failures} failure(s); app log: {app.log_path}')
    return 1 if checks.failures else 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except Abort as e:  # before the app was launched: machine in use
        sys.exit(f'Stopped: {e}')
