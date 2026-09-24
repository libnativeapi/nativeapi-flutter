#!/usr/bin/env python3
"""Plays tray_icon_example for a screen recording (macOS): animated tray icons rendered
by Flutter, frame by frame.

The example first moves its own window next to its tray icon ("Window to icon": below the
icon on macOS, above it on Windows), so the real icon and the magnified preview of the very
same frames are in the picture together. Then:
the animation gallery, a live widget captured into the tray, the rate going up to
60 fps, the Download and Recording scenes (the title follows the animation), three icons
animating at once, and the context menu opened and closed from code.

    tools/gui/flutter_tray_icon_demo.py [--record [OUT.mp4]] [--build] [--countdown N]
                                        [--pace F] [--keep-open]

With --record the main display is captured (cursor and clicks included) and saved as an
H.264 MP4 that fits within 1920x1200 — by default to
tools/gui/output/flutter_tray_icon_demo-macos.mp4. No keyboard input, no audio.

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

NAME = 'tray_icon_example'
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


def play(keep_open):
    app = PacedApp(example(NAME).executable, args=['-ApplePersistenceIgnoreState', 'YES'])
    app.keep_open = keep_open
    app.launch(min_windows=1)
    try:
        title = app.windows()[0][0]

        def press(label, hold=1.0, prefix=False):
            if app.menu_items():
                raise Abort('a menu is still open; refusing to probe')
            frame = app.window(title)
            view = next(v for v in app.views() if v.has('Tray icons'))
            px, py = app.to_screen(frame, view, view.center(label, prefix=prefix))
            app.click((round(px), round(py)))
            beat(hold)

        # 0. Next to the tray icon, wherever this platform keeps it.
        press('Properties', hold=0.8)
        press('Window to icon', hold=1.5)
        press('Animate', hold=0.8)

        # 1. The gallery: every tile plays in the tray and in the preview at once.
        for tile in ('Spinner', 'Wave', 'Rotate', 'Clock'):
            press(tile, hold=3.0)
        press('Any widget', hold=4.0)  # a live Flutter widget, screenshotted per frame

        # 2. Rate and resolution, on a shape where it shows.
        press('Progress', hold=2.0)
        press('10 fps', hold=3.0)
        press('60 fps', hold=4.0)
        press('30 fps', hold=1.0)
        press('Pause', hold=1.2)
        for _ in range(3):
            press('Step', hold=0.8)
        press('Resume', hold=1.5)

        # 3. Scenes: the title in the menu bar follows the animation.
        press('Download', hold=6.0)
        press('Recording', hold=5.0)
        press('Syncing', hold=4.0)

        # 4. Three icons, three animations, all running.
        press('Three icons', hold=7.0)

        # 5. The menu, opened and closed from code.
        press('Properties', hold=1.5)
        press('Open, close in 2 s', hold=0.3)
        if not app.wait_menu():
            raise Abort('the context menu did not open')
        if not app.wait_menu(is_open=False, timeout=6):
            raise Abort('the context menu stayed open; leaving it for a person to close')
        beat(2.0)

        # End on the proof: what the example verified by itself.
        press('Checklist ', hold=4.0, prefix=True)  # the tab reads "Checklist 9/22"
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
    except Abort as e:
        failed = e
    finally:
        if recorder:
            recorder.stop()
    if failed:
        raise SystemExit(f'Stopped: {failed}')
    if recorder:
        recorder.convert()


if __name__ == '__main__':
    sys.exit(main())
