#!/usr/bin/env python3
"""Plays the detachable window and browser tabs examples for a screen recording (macOS).

Each example is launched, driven with smooth synthetic mouse input, and quit
before the next one starts. Keep your hands off the mouse until it finishes.

    tools/gui/flutter_detachable_window_and_browser_tabs_demo.py [--record [OUT.mp4]] [--build]
                             [--countdown N] [--only detachable|tabs] [--keep-open]

With --record the main display is captured (cursor and clicks included) and
saved as an H.264 MP4 that fits within 1920x1200, ready to post on X — by default
to tools/gui/output/<this script's name>-macos.mp4 (…-<only>-macos.mp4 with --only).
Otherwise start your own screen recorder first. No keyboard input, no audio.

Built on the gui-test and record-demo skills (.agents/skills). Needs the examples
built in debug mode (`--build` does it), and for the terminal that runs this, in
System Settings > Privacy & Security: Accessibility (to post mouse events) and,
with --record, Screen Recording.
"""

import argparse
import sys
import time

from common import build_example, example, output_path
from guiapp import Abort, GuiApp, assert_idle, pause
from recorder import Recorder

KEEP_OPEN = False
LAST_LOG = None
# Speed of the whole scenario (--pace): 1.0 is the original, slow pacing. Mouse motions
# and pauses are scaled by it; pauses that let windows appear keep a floor.
PACE = 0.5


def scaled(ms, floor=120):
    return max(floor, int(ms * PACE))


def beat(seconds):
    pause(max(seconds * PACE, 0.7 if seconds >= 1 else 0.2))


class PacedApp(GuiApp):
    def move(self, point, ms=600):
        super().move(point, scaled(ms))

    def click(self, point, ms=450):
        super().click(point, scaled(ms))

    def drag(self, start, *legs, approach_ms=500):
        super().drag(start, *[(x, y, scaled(ms, 150)) for x, y, ms in legs],
                     approach_ms=scaled(approach_ms))


def launchable(name):
    app = PacedApp(example(name).executable)
    app.keep_open = KEEP_OPEN
    return app


def finish(app):
    global LAST_LOG
    LAST_LOG = app.log_path
    app.quit()


# ---------------------------------------------------------------------------
# Detachable windows

def detachable():
    ex = launchable('detachable_window_example')
    ex.launch(min_windows=2)
    try:
        def state():
            wins = dict(ex.windows())
            views = ex.views()
            view_a = next(v for v in views if v.has('Window A'))
            view_b = next(v for v in views if v.has('Window B'))
            floating = [v for v in views if v not in (view_a, view_b)]
            return wins, view_a, view_b, floating

        def at(frame, view, text, prefix=False):
            return ex.to_screen(frame, view, view.center(text, prefix))

        wins, va, vb, _ = state()
        fa, fb = wins['nativeapi · Window A'], wins['nativeapi · Window B']
        beat(1.0)

        # Give the panels some state worth keeping.
        plus = at(fa, va, '+1')
        for _ in range(3):
            ex.click(plus, 350)
            beat(0.25)
        ex.scroll(at(fa, va, 'Layer 1'), 3)
        beat(0.5)
        lap = at(fa, va, 'Lap')
        for _ in range(2):
            ex.click(lap, 400)
            beat(0.5)
        beat(0.8)

        # Tear the Inspector off and drop it over the workspace: it stays a window.
        start = at(fa, va, 'Inspector')
        ex.drag(start,
                (start[0] + 60, start[1] + 40, 350),
                (fa[0] + 470, fa[1] + 160, 900))
        beat(1.2)

        # Dock it into Window B's wide sidebar.
        wins, va, vb, floating = state()
        fi = wins['Inspector']
        start = at(fi, floating[0], 'Inspector')
        target = at(fb, vb, 'Wide sidebar')
        ex.drag(start,
                (start[0] + 250, start[1] + 60, 700),
                (target[0], target[1], 900))
        beat(1.5)

        # Move the Stopwatch from Window A's bottom panel to Window B's top strip.
        wins, va, vb, _ = state()
        start = at(fa, va, 'Stopwatch')
        target = at(fb, vb, 'Top strip')
        ex.drag(start,
                (start[0] + 40, start[1] - 80, 400),
                (target[0], target[1], 1100))
        beat(1.5)

        # And back again, swapping places.
        wins, va, vb, _ = state()
        start = at(fb, vb, 'Inspector')
        target = at(fa, va, 'Bottom panel')
        ex.drag(start,
                (start[0] - 120, start[1] + 60, 500),
                (target[0], target[1], 1100))
        beat(1.3)
        wins, va, vb, _ = state()
        start = at(fb, vb, 'Stopwatch')
        target = at(fa, va, 'Sidebar')
        ex.drag(start,
                (start[0] - 200, start[1] + 120, 500),
                (target[0], target[1], 1100))
        beat(2.0)

        # Same state all along: clicks, laps, scroll position.
        wins, va, vb, _ = state()
        ex.move(at(fa, va, 'Inspector'), 700)
        beat(2.5)
    finally:
        finish(ex)


# ---------------------------------------------------------------------------
# Browser tabs

def browser_tabs():
    ex = launchable('browser_tabs_example')
    ex.launch(min_windows=2)
    try:
        views = ex.views()
        frames = sorted((f for _, f in ex.windows()), key=lambda f: f[0])
        first = next(v for v in views if v.has('Tab 4'))
        second = next(v for v in views if v.has('Tab 5'))
        # Views keep their identity; windows are told apart by position.
        frame_of = {first.name: frames[0], second.name: frames[1]}

        def refresh():
            """Views by name, and frames of windows, matching new ones up."""
            current = {v.name: v for v in ex.views()}
            known = set(frame_of.values())
            new_frames = [f for _, f in ex.windows() if f not in known]
            for name in current:
                if name not in frame_of and new_frames:
                    frame_of[name] = new_frames.pop(0)
            return current

        def tab(view, title):
            """The tab chip (in the strip, not the page heading)."""
            for text, (x, y, w, h) in view.texts:
                if text == title and y < 40:
                    return ex.to_screen(frame_of[view.name], view, (x + w / 2, y + h / 2))
            raise LookupError(title)

        def on_page(view, text, prefix=False):
            return ex.to_screen(frame_of[view.name], view, view.center(text, prefix))

        beat(1.0)

        # Open Tab 4 and give its page some state.
        ex.click(tab(first, 'Tab 4'))
        beat(0.6)
        views = refresh()
        first = views[first.name]
        like = on_page(first, 'Like', prefix=True)
        for _ in range(3):
            ex.click(like, 350)
            beat(0.25)
        beat(0.8)

        # Reorder: Tab 1 slides past its neighbours.
        start = tab(first, 'Tab 1')
        ex.drag(start, (start[0] + 330, start[1] + 2, 1400))
        beat(1.0)

        # Tear Tab 4 off into its own window.
        views = refresh()
        first = views[first.name]
        start = tab(first, 'Tab 4')
        ex.drag(start,
                (start[0] - 40, start[1] + 120, 500),
                (start[0] - 160, start[1] + 330, 800))
        beat(1.4)

        # Drag that window by its tab onto the other window's strip: it merges
        # while still dragging, and can be positioned between the tabs.
        views = refresh()
        torn = next(v for n, v in views.items() if n not in (first.name, second.name))
        second = views[second.name]
        start = tab(torn, 'Tab 4')
        t5 = tab(second, 'Tab 5')
        ex.drag(start,
                (start[0] + 200, start[1] - 150, 700),
                (t5[0] + 60, t5[1], 900),
                (t5[0] + 150, t5[1], 700))
        beat(1.4)

        # Pull Tab 6 out of that window and straight into the first one.
        views = refresh()
        first, second = views[first.name], views[second.name]
        start = tab(second, 'Tab 6')
        t1 = tab(first, 'Tab 1')
        ex.drag(start,
                (start[0], start[1] + 180, 600),
                (t1[0] + 80, t1[1] + 60, 1000),
                (t1[0] + 40, t1[1], 500))
        beat(1.4)

        # Move a window by the empty part of its strip.
        views = refresh()
        fx, fy, fw, _ = frame_of[second.name]
        grip = (fx + fw - 80, fy + 20)
        ex.drag(grip, (grip[0] - 60, grip[1] + 50, 800))
        frame_of[second.name] = (fx - 60, fy + 50, fw, frame_of[second.name][3])
        beat(1.0)

        # Tab 4's page kept its likes through both moves.
        views = refresh()
        second = views[second.name]
        ex.click(tab(second, 'Tab 4'))
        beat(2.5)
    finally:
        finish(ex)


def main():
    global KEEP_OPEN, PACE
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--record', metavar='OUT.mp4', nargs='?', const='',
                        help='record the main display (default: tools/gui/output/'
                             '<script name>-macos.mp4)')
    parser.add_argument('--build', action='store_true', help='build the examples first')
    parser.add_argument('--countdown', type=int, default=5)
    parser.add_argument('--pace', type=float, default=PACE,
                        help=f'speed factor for motions and pauses (1.0 = slow original; default {PACE})')
    parser.add_argument('--only', choices=['detachable', 'tabs'])
    parser.add_argument('--keep-open', action='store_true',
                        help='leave the example running at the end (with --only)')
    args = parser.parse_args()
    KEEP_OPEN = args.keep_open and args.only is not None
    PACE = args.pace

    scenarios = [('detachable', detachable), ('tabs', browser_tabs)]
    if args.only:
        scenarios = [s for s in scenarios if s[0] == args.only]
    if args.build:
        for name in ('detachable_window_example', 'browser_tabs_example'):
            build_example(name)

    for i in range(args.countdown, 0, -1):
        print(f'Starting in {i}… (hands off the mouse)', flush=True)
        time.sleep(1)
    try:
        assert_idle()
    except Abort as e:
        raise SystemExit(f'Stopped: {e}')
    recorder = None
    if args.record is not None:
        recorder = Recorder(args.record or output_path(__file__, 'macos', variant=args.only))
    if recorder:
        recorder.start()
        print('● recording', flush=True)
    try:
        for index, (name, run) in enumerate(scenarios):
            if index:
                beat(1.5)
            print(f'▶ {name}', flush=True)
            run()
        beat(1.0)
    except Abort as e:
        raise SystemExit(f'Stopped: {e}')
    finally:
        if recorder:
            recorder.stop()
    if recorder:
        print('Converting…', flush=True)
        recorder.convert()
    print('Done.')
    if KEEP_OPEN:
        print(f'Left running; app log: {LAST_LOG}')


if __name__ == '__main__':
    main()
