#!/usr/bin/env python3
"""Plays shaped_window_example for a screen recording (macOS): a Flutter window whose
native contour is a polygon, so the desktop shows through around it.

The story is the two things the feature is about: click through **every silhouette** in
the gallery, then walk the **contour shadow presets** (None, Soft, Float, Sharp, Glow)
on the last one. It ends on the final silhouette with its shadow and the example's own
log.

    tools/gui/flutter_window_shape_demo.py [--record [OUT.mp4]] [--build]
                                           [--countdown N] [--pace F] [--keep-open]
                                           [--only SCENE]

With --record the main display is captured (cursor and clicks included) and saved as an
H.264 MP4 that fits within 1920x1200 - by default to
tools/gui/output/flutter_window_shape_demo-macos.mp4. No keyboard input, no audio.

Scenes: shapes, shadow. --only runs one of them from a fresh launch (the rest of the
story is skipped) and is meant for iterating.

Built on the gui-test and record-demo skills (.agents/skills). Needs the example built
in debug mode (`--build` does it), and for the terminal that runs this, in System
Settings > Privacy & Security: Accessibility and, with --record, Screen Recording.
"""

import argparse
import sys
import time

from common import build_example, example, output_path
from guiapp import Abort, GuiApp, assert_idle, pause
from recorder import Recorder

NAME = 'shaped_window_example'
CONTROLS = 'Window shapes'
PREVIEW = 'Shape preview'
HANDLE = '\u283f  DRAG ME'  # the preview's drag handle (braille blank + two spaces)
# Speed of the whole scenario (--pace): motions and pauses are scaled by it; pauses that
# wait for something to appear keep a floor.
PACE = 0.5
# The gallery, in the order it is laid out (four per row, left to right).
SHAPES = ('circle', 'star', 'bubble', 'heart', 'flower', 'hexagon', 'squircle', 'blob',
          'burst', 'droplet', 'diamond', 'shield')
PRESETS = ('None', 'Soft', 'Float', 'Sharp', 'Glow')


def scaled(ms, floor=120):
    return max(floor, int(ms * PACE))


def beat(seconds):
    pause(max(seconds * PACE, 0.7 if seconds >= 1 else 0.2))


class PacedApp(GuiApp):
    def move(self, point, ms=600):
        super().move(point, scaled(ms))

    def click(self, point, ms=450):
        super().click(point, scaled(ms))


def play(keep_open, only, recorder=None):
    app = PacedApp(example(NAME).executable,
                   args=['-ApplePersistenceIgnoreState', 'YES'])
    app.keep_open = keep_open
    app.launch(min_windows=2)
    try:
        def controls():
            return next(v for v in app.views() if v.has('SHAPE PLAYGROUND'))

        def preview():
            # The drag handle is in every preview, shaped or rectangular.
            return next(v for v in app.views() if v.has(HANDLE))

        def place(title, x, y):
            """Moves a window without resizing it (the example's own sizes are right)."""
            _, _, w, h = app.window(title)
            app.set_frame(x, y, w, h, title=title)

        def at(view, point, title=CONTROLS):
            x, y = app.to_screen(app.window(title), view, point)
            return round(x), round(y)

        def press(view, point, hold=0.85, title=CONTROLS):
            app.click(at(view, point, title))
            beat(hold)

        def chip(label, hold=1.1):
            view = controls()
            press(view, view.center(label), hold)

        def card(name, hold=0.85):
            view = controls()
            press(view, view.center(name), hold)

        def status():
            return next(t for t, _ in controls().texts if 'shape active' in t
                        or t.startswith('Rectangle') or t.startswith('Could not'))

        def scene_shapes():
            # Every silhouette in the gallery, one after the other: the polygon the
            # native clip follows morphs over 450 ms and the label follows it.
            for name in SHAPES:
                card(name)
                assert preview().has(name) or name == 'circle', name
            print('shapes: ' + status(), flush=True)

        def scene_shadow():
            # None, Soft, Float, Sharp, Glow: the contour shadow follows the same
            # polygon, outside the shape, without taking clicks. The presets differ
            # subtly, so each one is held a little longer than a gallery click.
            for preset in PRESETS:
                chip(preset, hold=1.45)
                # The name readout sits in the SHADOW header row, above the chips.
                readout = min((r[1], t) for t, r in controls().texts if t in PRESETS)[1]
                assert readout == preset, (readout, preset)
            print('shadow: ' + readout, flush=True)

        scenes = [('shapes', scene_shapes), ('shadow', scene_shadow)]
        if only:
            scenes = [s for s in scenes if s[0] == only]
            if not scenes:
                raise SystemExit(f'unknown scene {only!r}; pick from ["shapes", "shadow"]')
        # The example puts the two windows on the primary display itself; move them
        # somewhere with room around the preview for the shadow.
        place(CONTROLS, 250, 130)
        place(PREVIEW, 820, 200)
        beat(1.2)
        if recorder:
            # The app is already up, so the take opens on it rather than on an empty
            # desktop: nothing is trimmed afterwards, and a cold launch costs seconds.
            recorder.start()
            print('\u25cf recording', flush=True)

        for _, scene in scenes:
            scene()

        beat(1.6)
        print('proof:', status(), '|', app.window(PREVIEW), flush=True)
        for line in [l for l in app.output().splitlines() if l.startswith('[shape]')][-4:]:
            print('  ', line, flush=True)
    finally:
        print(f'App log: {app.log_path}', flush=True)
        app.quit()


def main():
    global PACE
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--record', metavar='OUT.mp4', nargs='?', const='',
                        help='record the main display (default: tools/gui/output/'
                             '<script name>-macos.mp4)')
    parser.add_argument('--build', action='store_true', help='build the example first')
    parser.add_argument('--countdown', type=int, default=5)
    parser.add_argument('--pace', type=float, default=PACE,
                        help=f'speed factor for motions and pauses (default {PACE})')
    parser.add_argument('--keep-open', action='store_true',
                        help='leave the example running at the end')
    parser.add_argument('--only', help='run a single scene from a fresh launch')
    args = parser.parse_args()
    PACE = args.pace

    if args.build:
        build_example(NAME)
    for i in range(args.countdown, 0, -1):
        print(f'Starting in {i}\u2026 (hands off the mouse)', flush=True)
        time.sleep(1)
    try:
        assert_idle()
    except Abort as e:
        raise SystemExit(f'Stopped: {e}')

    recorder = Recorder(args.record or output_path(__file__, 'macos')) \
        if args.record is not None else None
    failed = None
    try:
        play(args.keep_open, args.only, recorder)  # starts the recorder once the app is up
        beat(1.0)
    except (Abort, LookupError, StopIteration, AssertionError) as e:
        failed = e
    finally:
        if recorder:
            recorder.stop()
    if failed:
        raise SystemExit(f'Stopped: {failed!r}')
    if recorder:
        recorder.convert()


if __name__ == '__main__':
    sys.exit(main())
