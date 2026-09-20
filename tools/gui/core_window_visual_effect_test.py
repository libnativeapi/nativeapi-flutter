#!/usr/bin/env python3
"""GUI test (macOS) of core's window_visual_effect_example (C++): the example puts a
window over a plain red one and walks it through every VisualEffect; this looks at the
screen after each step. A material that blends with what is behind the window comes out
reddish, no effect does not, and a background color given while an effect was active is
what the window shows once the effect is removed.

    tools/gui/core_window_visual_effect_test.py [--build]

Built on the gui-test skill (.agents/skills). It sends no input; the example's two
windows are on screen for about 35 s.
"""

import sys
import time

from common import build_core_example, core_example, screen_color
from guiapp import Abort, Checks, pause

NAME = 'window_visual_effect_example'
WINDOW = 'Visual effect'
# Materials that show the windows behind. Mica (the window background material) and
# MicaAlt (the title bar's) are tinted by the desktop picture alone, so they are only
# expected to be accepted.
SEE_THROUGH = ['Blur', 'Acrylic', 'Hud', 'Popover', 'Menu']
WALLPAPER = ['Mica', 'MicaAlt']


def watch(app, timeout=60):
    """{step: (outcome, color)}: what the window looks like after each "STEP <name>
    <outcome>" line of the example. The example moves on by itself, so a look that a
    later step overtook does not count."""
    def steps():
        return [l.split()[1:3] for l in app.output().splitlines() if l.startswith('STEP ')]

    seen = {}
    deadline = time.time() + timeout
    while time.time() < deadline and app.proc.poll() is None:
        current = steps()
        if not current or current[-1][0] in seen:
            time.sleep(0.1)
            continue
        name, outcome = current[-1]
        pause(1.0)  # the step is on screen, and a material fades in
        x, y, w, h = app.window(WINDOW)
        color = screen_color(x + w / 2, y + h / 2 + 14)
        seen[name] = (outcome, color if steps()[-1][0] == name else None)
    return seen


def redness(color):
    return color[0] - max(color[1], color[2])


def main():
    if '--build' in sys.argv:
        build_core_example(NAME)
    app = core_example(NAME)
    checks = Checks()
    app.launch(min_windows=2, flutter=False)
    try:
        seen = watch(app)

        def color(name):
            outcome, color = seen.get(name, (None, None))
            if color is None:
                raise Abort(f'step {name} was not looked at in time: {seen}')
            return color

        checks.check('without an effect the window hides what is behind it',
                     redness(color('None')) < 30, color('None'))
        for name in SEE_THROUGH:
            checks.check(f'{name} is applied', seen.get(name, ('',))[0] == 'applied', seen.get(name))
            checks.check(f'{name} shows the red window behind', redness(color(name)) > 15,
                         color(name))
        for name in WALLPAPER:
            checks.check(f'{name} is applied', seen.get(name, ('',))[0] == 'applied', seen.get(name))
        checks.check('a background color set meanwhile does not replace the effect',
                     color('Background')[2] < 200 or color('Background')[0] > 60,
                     color('Background'))
        checks.check('removing the effect shows that background color',
                     color('Removed')[2] > 200 and max(color('Removed')[:2]) < 60,
                     color('Removed'))

        deadline = time.time() + 10
        while app.proc.poll() is None and time.time() < deadline:
            time.sleep(0.2)
        checks.check("the example's own expectations hold", app.proc.poll() == 0, app.proc.poll())
    except Abort as e:
        checks.check('ran to the end', False, e)
    finally:
        app.quit()
    for line in app.output().splitlines():
        print(f'app: {line}')
    print(f'{checks.failures} failure(s); app log: {app.log_path}')
    return 1 if checks.failures else 0


if __name__ == '__main__':
    sys.exit(main())
