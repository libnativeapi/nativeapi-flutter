#!/usr/bin/env python3
"""GUI test (macOS) of visual_effect_example: a Flutter window really shows the material
set with Window.setVisualEffect. Started with VISUAL_EFFECT_AUTOPLAY=1 the example puts a
plain red window behind itself and walks through the effects on its own; this looks at
the screen after each step. A material that blends with what is behind the window comes
out reddish where Flutter paints nothing, and with the effect removed the Flutter view
is as opaque as it was before.

    tools/gui/flutter_visual_effect_test.py [--build]

Built on the gui-test skill (.agents/skills). It sends no input; the example's two
windows are on screen for about 30 s.
"""

import os
import sys
import time

from common import build_example, example, screen_color
from guiapp import Abort, Checks, pause

NAME = 'visual_effect_example'
WINDOW = 'Visual effect'
# Materials that show the windows behind; mica and micaAlt take their tint from the
# desktop picture alone, so they are only expected to be accepted.
SEE_THROUGH = ['blur', 'acrylic', 'hud', 'popover', 'menu']
WALLPAPER = ['mica', 'micaAlt']
LAST = 'none'


def redness(color):
    return color[0] - max(color[1], color[2])


def watch(app, timeout=60):
    """{step: (outcome, color)}: the screen where the example paints nothing (right of the
    chips, above the note) after each "STEP <name> <outcome>" line. The example moves on
    by itself, so a look that a later step overtook does not count."""
    def steps():
        return [l.split('STEP ', 1)[1].split()[:2] for l in app.output().splitlines()
                if 'STEP ' in l]

    seen = {}
    deadline = time.time() + timeout
    while time.time() < deadline and app.proc.poll() is None and LAST not in seen:
        current = steps()
        if not current or current[-1][0] in seen:
            time.sleep(0.1)
            continue
        name, outcome = current[-1]
        pause(1.2)  # the step is on screen, and a material fades in
        x, y, w, h = app.window(WINDOW)
        color = screen_color(x + w * 0.8, y + h * 0.75)
        beside = screen_color(x - 30, y + h * 0.75)
        seen[name] = (outcome, color if steps()[-1][0] == name else None, beside)
    return seen


def main():
    if '--build' in sys.argv:
        build_example(NAME)
    os.environ['VISUAL_EFFECT_AUTOPLAY'] = '1'
    app = example(NAME, args=['-ApplePersistenceIgnoreState', 'YES'])
    checks = Checks()
    app.launch(min_windows=1)
    try:
        seen = watch(app)

        def color(name):
            if seen.get(name, (None, None))[1] is None:
                raise Abort(f'step {name} was not looked at in time: {seen}')
            return seen[name][1]

        plain = color('backdrop')
        checks.check('the backdrop is red around the example',
                     redness(seen['backdrop'][2]) > 150, seen['backdrop'][2])
        checks.check('without an effect the Flutter view hides what is behind it',
                     redness(plain) < 30, plain)
        for name in SEE_THROUGH:
            checks.check(f'{name} is applied', seen[name][0] == 'applied', seen[name][0])
            checks.check(f'{name} shows the red window through the Flutter view',
                         redness(color(name)) > 15, color(name))
        for name in WALLPAPER:
            checks.check(f'{name} is applied', seen.get(name, ('',))[0] == 'applied',
                         seen.get(name))
        checks.check('the effect can be removed', seen[LAST][0] == 'applied', seen[LAST][0])
        checks.check('and the Flutter view has the backing it had before',
                     max(abs(a - b) for a, b in zip(color(LAST), plain)) <= 8,
                     f'{plain} -> {color(LAST)}')
    except Abort as e:
        checks.check('ran to the end', False, e)
    finally:
        app.quit()
    print(f'{checks.failures} failure(s); app log: {app.log_path}')
    return 1 if checks.failures else 0


if __name__ == '__main__':
    sys.exit(main())
