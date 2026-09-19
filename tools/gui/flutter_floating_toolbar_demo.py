#!/usr/bin/env python3
"""Plays floating_toolbar_example for a screen recording (macOS): a second Flutter window
- transparent, frameless, a child of the main one - that floats above the main window.

The story: the pill drives the main window (colours, Stamp: two windows, one isolate);
the main window is dragged by its title bar and resized from its corner, and the pill
comes along and re-centres; detached it stays behind, attached it snaps back; hidden and
shown again. It ends on the proof, the main window's own log and counter.

    tools/gui/flutter_floating_toolbar_demo.py [--record [OUT.mp4]] [--build]
                                               [--countdown N] [--pace F] [--keep-open]

With --record the main display is captured (cursor and clicks included) and saved as an
H.264 MP4 that fits within 1920x1200 - by default to
tools/gui/output/flutter_floating_toolbar_demo-macos.mp4. No keyboard input, no audio.

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

NAME = 'floating_toolbar_example'
MAIN = 'Floating toolbar'
TOOLBAR = 'Toolbar'
# Speed of the whole scenario (--pace): motions and pauses are scaled by it; pauses that
# wait for something to appear keep a floor.
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

    def paced_drag(self, start, *legs):
        super().drag(start, *[(x, y, scaled(ms, 150)) for x, y, ms in legs],
                     approach_ms=scaled(500))


def play(keep_open):
    app = PacedApp(example(NAME).executable, args=['-ApplePersistenceIgnoreState', 'YES'])
    app.keep_open = keep_open
    app.launch(min_windows=2)
    try:
        def view_of(text):
            return next(v for v in app.views() if v.has(text))

        def press(title, text, hold=0.8):
            view = view_of(text)
            x, y = app.to_screen(app.window(title), view, view.center(text))
            app.click((round(x), round(y)))
            beat(hold)

        def swatch(index, hold=0.9):
            """The colour circles carry no text: they sit left of the Stamp button, 38
            logical px apart (28 wide, 5 of padding each side), 10 before the button,
            whose label starts 38 px in (12 padding, 18 icon, 8 gap)."""
            view = view_of('Stamp')
            x, y, w, h = view.find('Stamp')
            button_left = x - 38
            cx = button_left - 10 - 38 * (4 - index) + 19
            px, py = app.to_screen(app.window(TOOLBAR), view, (cx, y + h / 2))
            app.click((round(px), round(py)))
            beat(hold)

        def drag_main(*offsets):
            """Drags the main window by its title bar along the offsets (dx, dy, ms)."""
            frame = app.window(MAIN)
            grab = (frame[0] + frame[2] // 2 + 120, frame[1] + 14)
            app.paced_drag(grab, *[(grab[0] + dx, grab[1] + dy, ms) for dx, dy, ms in offsets])
            beat(1.0)

        # A known starting point, with room above for the pill and around for the drags.
        app.set_frame(420, 300, 720, 552, title=MAIN)
        beat(1.2)

        # 1. The pill drives the main window: two windows, one isolate.
        for index in (1, 2, 3, 0):
            swatch(index)
        for _ in range(3):
            press(TOOLBAR, 'Stamp', hold=0.5)
        beat(1.0)

        # 2. The main window moves: the pill comes along.
        drag_main((60, 30, 350), (330, 170, 900))
        drag_main((-60, -20, 350), (-380, -90, 900))

        # 3. It is resized from its corner: the pill stays centred.
        frame = app.window(MAIN)
        corner = (frame[0] + frame[2] - 3, frame[1] + frame[3] - 3)
        app.paced_drag(corner, (corner[0] + 40, corner[1] + 20, 350),
                       (corner[0] + 260, corner[1] + 90, 800))
        beat(1.0)
        frame = app.window(MAIN)
        corner = (frame[0] + frame[2] - 3, frame[1] + frame[3] - 3)
        app.paced_drag(corner, (corner[0] - 40, corner[1] - 20, 350),
                       (corner[0] - 260, corner[1] - 90, 800))
        beat(1.0)

        # 4. Detached it stays behind; attached it snaps back.
        press(MAIN, 'Detach toolbar')
        drag_main((60, 30, 350), (300, 140, 800))
        press(MAIN, 'Attach toolbar', hold=1.4)

        # 5. Hidden, and not brought back by moving its parent; shown again.
        press(MAIN, 'Hide toolbar')
        drag_main((-60, -30, 350), (-300, -140, 800))
        press(MAIN, 'Show toolbar', hold=1.4)

        # End on the proof: the counter and the log in the main window.
        swatch(2)
        press(TOOLBAR, 'Stamp', hold=0.5)
        beat(2.4)
        main_view = view_of('Detach toolbar')
        print('proof:', [t for t, _ in main_view.texts if t.startswith('Stamps')],
              app.window(MAIN), app.window(TOOLBAR), flush=True)
    finally:
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
    args = parser.parse_args()
    PACE = args.pace

    if args.build:
        build_example(NAME)
    for i in range(args.countdown, 0, -1):
        print(f'Starting in {i}… (hands off the mouse)', flush=True)
        time.sleep(1)
    try:
        assert_idle()
    except Abort as e:
        raise SystemExit(f'Stopped: {e}')

    recorder = Recorder(args.record or output_path(__file__, 'macos')) \
        if args.record is not None else None
    if recorder:
        recorder.start()
        print('● recording', flush=True)
    failed = None
    try:
        play(args.keep_open)
        beat(1.0)
    except (Abort, LookupError, StopIteration) as e:
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
