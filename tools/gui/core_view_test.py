#!/usr/bin/env python3
"""GUI test (macOS) of core's view_example (C++): a sign-in form made of native
controls (Label, TextField, Button) laid out by a Column and a Row. It checks the
layout numbers the example prints, clicks the real buttons and asserts on the status
lines, and resizes the window to see the Row re-flow.

    tools/gui/core_view_test.py [--build]

Built on the gui-test skill (.agents/skills). It takes over the mouse for ~10 s and
sends no keyboard input.
"""

import re
import sys

from common import build_core_example, core_example
from guiapp import Abort, Checks, assert_idle, pause

NAME = 'view_example'
WINDOW = 'Sign in'
CONTENT = (360, 220)
PADDING, SPACING = 16, 8


def layouts(app):
    """{label: (x, y, w, h)} from the LAST "[view] layout" block the example printed."""
    out = {}
    for line in app.output().splitlines():
        m = re.match(r'\[view\] layout (\w+) (\S+) (\S+) (\S+) (\S+)', line)
        if m:
            if m.group(1) == 'root':
                out = {}
            out[m.group(1)] = tuple(float(v) for v in m.group(2, 3, 4, 5))
    return out


def statuses(app):
    return [l.split(': ', 1)[1] for l in app.output().splitlines() if l.startswith('[view] status: ')]


def near(checks, what, actual, expected, tolerance=2):
    checks.check(what, abs(actual - expected) <= tolerance, f'{actual} vs {expected}')


def to_screen(frame, layout, control):
    """Screen centre of a control from its root-relative frame; the content sits at the
    bottom of the window frame."""
    x, y, w, h = frame
    _, _, rw, rh = layout['root']
    cx, cy, cw, ch = layout[control]
    return x + cx + cw / 2, y + (h - rh) + cy + ch / 2


def main():
    if '--build' in sys.argv:
        build_core_example(NAME)
    assert_idle()
    app = core_example(NAME)
    checks = Checks()
    app.launch(min_windows=1, flutter=False)
    try:
        pause(0.5)
        layout = layouts(app)
        checks.check('layout printed for every control',
                     {'root', 'heading', 'name', 'password', 'status', 'actions', 'clear',
                      'sign_in'} <= set(layout), sorted(layout))
        near(checks, 'root is the content area (w)', layout['root'][2], CONTENT[0])
        near(checks, 'root is the content area (h)', layout['root'][3], CONTENT[1])

        # Column: padding, then each row under the previous one plus the spacing;
        # Stretch fills the padded width.
        near(checks, 'heading starts at the padding', layout['heading'][1], PADDING)
        near(checks, 'heading spans the padded width', layout['heading'][2],
                    CONTENT[0] - 2 * PADDING)
        h = layout['heading']
        near(checks, 'name follows the heading', layout['name'][1], h[1] + h[3] + SPACING)
        n = layout['name']
        near(checks, 'password follows name', layout['password'][1], n[1] + n[3] + SPACING)
        checks.check('a text field has a height', layout['name'][3] > 10, layout['name'][3])
        # Row: the spacer takes the leftover, so the buttons hug the trailing edge.
        a = layout['actions']
        near(checks, 'actions row is 32 high (preferred size)', a[3], 32)
        s = layout['sign_in']
        near(checks, 'sign in hugs the trailing edge', s[0] + s[2], CONTENT[0] - PADDING)
        c = layout['clear']
        near(checks, 'clear sits before sign in, spaced', c[0] + c[2] + SPACING, s[0])
        checks.check('buttons have an intrinsic width', 40 < s[2] < 140, s[2])

        # Act: click "Sign in" with an empty username, then "Clear".
        frame = app.window(WINDOW)
        app.click(to_screen(frame, layout, 'sign_in'))
        pause(1.0)
        checks.check('empty sign-in is refused', statuses(app)[-1:] == ['A username is required.'],
                     statuses(app))
        checks.check('the refused sign-in focused the username field',
                     '[view] focused: name' in app.output())

        frame = app.window(WINDOW)
        app.click(to_screen(frame, layouts(app), 'clear'))
        pause(1.0)
        checks.check('clear resets the status',
                     statuses(app)[-1:] == ['Enter your credentials.'], statuses(app))

        # Resize: the Column and the Row re-flow to the new width.
        x, y, w, h = frame
        app.set_frame(x, y, w + 120, h + 60, WINDOW)
        pause(1.0)
        after = layouts(app)
        near(checks, 'root grew with the window (w)', after['root'][2], CONTENT[0] + 120)
        near(checks, 'root grew with the window (h)', after['root'][3], CONTENT[1] + 60)
        near(checks, 'heading re-stretched', after['heading'][2], CONTENT[0] + 120 - 2 * PADDING)
        s2 = after['sign_in']
        near(checks, 'sign in followed the trailing edge', s2[0] + s2[2],
                    CONTENT[0] + 120 - PADDING)
        near(checks, 'button width unchanged by the resize', s2[2], s[2])
    except Abort as e:
        checks.check('ran to the end', False, e)
    finally:
        app.quit()
    print(f'{checks.failures} failure(s); app log: {app.log_path}')
    return 1 if checks.failures else 0


if __name__ == '__main__':
    sys.exit(main())
