#!/usr/bin/env python3
"""Plays shaped_window_example for a screen recording (Linux / GNOME Wayland): a Flutter
window whose silhouette is a polygon, so the desktop shows through around it.

The story is the two things the feature is about: click through **every silhouette** in the
gallery, then walk the **contour shadow presets** (None, Soft, Float, Sharp, Glow) on the last
one. It ends on the final silhouette with its shadow and the example's own log.

    tools/gui/flutter_window_shape_demo_linux.py [--record [OUT.mp4]] [--build] [--pace F]
                                                [--keep-open] [--only SCENE]

Run it on the host through the remote-hosts skill, which puts the example, the harness and
the reader in one flat scratch directory:

    R=.agents/skills/remote-hosts/scripts/remote.sh
    $R linux desktop tools/gui/flutter_window_shape_demo_linux.py 240                 # dry run
    .agents/skills/record-demo/scripts/record_remote_linux.sh linux \\
        tools/gui/flutter_window_shape_demo_linux.py tools/gui/output                  # the take

The example has to run as a **Wayland client** here (the GNOME/Xwayland path dies with a
Flutter multi-window GLX BadAccess), and Wayland hands a client no window geometry at all —
`position` is ignored, Xlib sees none of these windows, and `org.gnome.Shell.Eval` /
`Introspect.GetWindows` are closed. So this script aims the mouse the way the capture-locate
route does:

* one frame from Mutter's ScreenCast path (`recorder.grab`) is read with PIL — the control
  window is the 480x680 panel whose 48 px header starts at the gradient colour 0x201C45,
  the preview is the only blob thick enough to survive an erosion of the colourful mask;
* the gallery card centres and the preset chips come from the known content layout, with the
  shape-name labels from the Flutter probe (`uiprobe`) as the sanity check;
* GNOME places the transient preview on top of the gallery, where its silhouette would swallow
  clicks meant for five cards, so before the recorder starts the preview is **dragged clear by
  its own 'DRAG ME' handle** — the one gesture in this script that is not part of the story,
  and the only way to move a Wayland window (nothing in the script touches the keyboard);
* every press is refused unless the point is inside the located control window and clear of
  the preview's silhouette, and every click is proved by the probe reporting the new shape.

No keyboard input, no audio, no trimming. Scenes: shapes, shadow. `--only` runs one of them
from a fresh launch (the rest of the story is skipped) and is meant for iterating. Without
`--record` the whole thing is a dry run; `--keep-open` leaves the example running.
"""

import argparse
import os
import sys
import time
import traceback
from pathlib import Path

SCRATCH = Path(os.environ.get('REMOTE_SCRATCH', Path(__file__).resolve().parent))
# The remote-hosts kit is pushed flat: guiapp.py, xinput.py, uiprobe.py, recorder.py sit here.
sys.path[:0] = [str(SCRATCH)]

from PIL import Image, ImageChops, ImageFilter  # noqa: E402

from guiapp import Abort, GuiApp, assert_idle, build_flutter, flutter_executable, pause  # noqa: E402
from recorder import Recorder, grab  # noqa: E402
from xinput import BTN_LEFT  # noqa: E402

NAME = 'shaped_window_example'
CONTROLS = 'Window shapes'
PREVIEW = 'Shape preview'
HEADER = 'Outside the box.'
# The control window's content, from the example itself (RegularWindowController size).
CONTROL_SIZE = (480, 680)
HEADER_HEIGHT = 48
# The gradient in the control window's header starts at this colour.
HEADER_COLOUR = (0x20, 0x1C, 0x45)
# The preview's content square and the '⠿  DRAG ME' handle inside it (from the probe).
PREVIEW_SIZE = 320
HANDLE = (160, 107)
# Gallery grid inside the content: 12 px side padding, four columns, 8 px gaps.
GALLERY_LEFT, COLUMNS, GAP = 12, 4, 8
COLUMN_WIDTH = (CONTROL_SIZE[0] - 2 * GALLERY_LEFT - (COLUMNS - 1) * GAP) // COLUMNS
# A card is 130.3 px tall in a 138.3 px row; the 46 px thumbnail is centred, the label sits
# 18.5 px below the card's centre. Derived from the layout, checked against the probe.
CARD_CENTRE_ABOVE_LABEL = 18.5
# Speed of the whole scenario (--pace): motions and pauses are scaled by it; pauses that wait
# for something to appear keep a floor.
PACE = 1.0
# The gallery, in the order it is laid out (four per row, left to right).
SHAPES = ('circle', 'star', 'bubble', 'heart', 'flower', 'hexagon', 'squircle', 'blob',
          'burst', 'droplet', 'diamond', 'shield')
PRESETS = ('None', 'Soft', 'Float', 'Sharp', 'Glow')
# Where the preview is put before recording: clear of the control window, both fully visible.
PREVIEW_GAP = (100, 120)


def scaled(ms, floor=120):
    return max(floor, int(ms * PACE))


def beat(seconds):
    pause(max(seconds * PACE, 0.2))


# -- reading a captured frame --------------------------------------------------

def _proximity(im, colour, tol):
    """255 where every channel is within `tol` of `colour`."""
    masks = [c.point(lambda v, t=t: 255 if abs(v - t) <= tol else 0)
             for c, t in zip(im.split(), colour)]
    return ImageChops.multiply(ImageChops.multiply(masks[0], masks[1]), masks[2])


def _colourful(im):
    """Bright and saturated: one of the example's gradients, not the wallpaper or the panel."""
    r, g, b = im.split()
    high = ImageChops.lighter(ImageChops.lighter(r, g), b)
    low = ImageChops.darker(ImageChops.darker(r, g), b)
    return ImageChops.multiply(high.point(lambda v: 255 if v > 170 else 0),
                               ImageChops.subtract(high, low).point(
                                   lambda v: 255 if v > 40 else 0))


def _blobs(mask):
    """[(area, (x0, y0, x1, y1))] of the mask's connected regions, largest first."""
    width, height = mask.size
    data = bytearray(mask.tobytes())
    found = []
    for start in range(width * height):
        if data[start] != 255:
            continue
        data[start] = 1
        queue, area = [start], 0
        x0 = y0 = 10 ** 9
        x1 = y1 = -1
        while queue:
            i = queue.pop()
            x, y = i % width, i // width
            area += 1
            x0, y0, x1, y1 = min(x0, x), min(y0, y), max(x1, x), max(y1, y)
            for j in (i - 1, i + 1, i - width, i + width):
                if 0 <= j < width * height and data[j] == 255 and abs(j % width - x) <= 1:
                    data[j] = 1
                    queue.append(j)
        found.append((area, (x0, y0, x1 + 1, y1 + 1)))
    return sorted(found, reverse=True)


def find_controls(im, size=CONTROL_SIZE):
    """The control window's content rect in the frame, or None.

    The 48 px header's gradient starts at HEADER_COLOUR, so the band of those pixels gives
    the content's top-left; the panel's plain white background has to be there at both
    ends of a `size`-wide row just below the header, which is what makes this the header and not some other
    dark-purple thing on the desktop.
    """
    width, height = size
    w, h = im.size
    purple = _proximity(im, HEADER_COLOUR, 10).tobytes()
    rows = [y for y in range(h) if purple[y * w:(y + 1) * w].count(255) > 8]
    bands = []
    for y in rows:
        if bands and y - bands[-1][-1] <= 3:
            bands[-1].append(y)
        else:
            bands.append([y])
    body = ImageChops.darker(ImageChops.darker(*im.split()[:2]), im.split()[2])
    white = body.point(lambda v: 255 if v >= 250 else 0).tobytes()

    def blank(x, y):
        # Only the two ends of the row: GNOME may place the preview over the middle of it.
        row = white[y * w:(y + 1) * w]
        return (row[x:x + 40].count(255) == 40
                and row[x + width - 40:x + width].count(255) == 40)

    for band in bands:
        if not 40 <= len(band) <= 60:
            continue
        top = band[0]
        left = min((purple[y * w:(y + 1) * w].find(255) for y in band), default=-1)
        if left < 0 or left + width > w or top + height > h:
            continue
        if blank(left, top + HEADER_HEIGHT + 5) and blank(left, top + HEADER_HEIGHT + 9):
            return (left, top, width, height)
    return None


def _reach(data, w, h, cx, cy, dx, dy, start, limit):
    """How far the mask reaches from `start` steps out along (dx, dy), plus `start`."""
    n = start
    while n < limit:
        x, y = cx + dx * (n + 1), cy + dy * (n + 1)
        if not (0 <= x < w and 0 <= y < h) or data[y * w + x] != 255:
            break
        n += 1
    return n


def find_preview(im, size=PREVIEW_SIZE):
    """The preview window's silhouette centre, or None.

    The silhouette is the only thing on this desktop thick enough to survive an 8x downscale
    and a 9 px erosion of the colourful mask: the gallery's 46 px thumbnails and the 48 px
    header band are gone, and the wallpaper is not bright and saturated at once. The four
    radii are measured (off the white text, which is not saturated) so a blob that is not the
    shape's square is rejected; one of them may run on into the header it touches.
    """
    w, h = im.size
    mask = _colourful(im)
    data = mask.tobytes()
    coarse = (mask.resize((w // 8, h // 8), Image.BOX)
                  .point(lambda v: 255 if v >= 200 else 0)
                  .filter(ImageFilter.MinFilter(9)))
    for area, (x0, y0, x1, y1) in _blobs(coarse):
        bw, bh = x1 - x0, y1 - y0
        if area < 120 or not 0.6 <= bw / max(bh, 1) <= 1.7:
            continue
        cx, cy = (x0 + x1) * 8 // 2, (y0 + y1) * 8 // 2
        inside = [(cx, cy), (cx - 120, cy), (cx + 120, cy), (cx, cy - 120), (cx, cy + 120)]
        outside = [(cx + dx, cy + dy) for dx in (-200, 200) for dy in (-200, 200)]
        if not all(data[y * w + x] == 255 for x, y in inside):
            continue
        # One corner may land on something else colourful: GNOME can place the preview
        # against the control window's header, whose right end is a bright violet.
        if sum(data[y * w + x] == 255 for x, y in outside) > 1:
            continue
        radii = [_reach(data, w, h, cx, cy, 0, 1, 60, 400), _reach(data, w, h, cx, cy, 0, -1, 60, 400),
                 _reach(data, w, h, cx, cy, -1, 0, 60, 400), _reach(data, w, h, cx, cy, 1, 0, 60, 400)]
        if sum(abs(r - size // 2) <= 10 for r in radii) >= 3:
            return (cx, cy), tuple(radii)
    return None


# -- the app -------------------------------------------------------------------

class PacedApp(GuiApp):
    """GuiApp with the scenario's pace, launched as the Wayland client the example needs.

    The Xlib half of GuiApp (`window`, `to_screen`, the owner check in `click`) is useless
    here — these windows are not X11 windows — so this script looks with the frame reader and
    acts with the harness's own real-input session (`self.input`).
    """

    def move(self, point, ms=260):
        super().move(point, scaled(ms))


class Shots:
    """One live frame of the screen at a time, read through the ScreenCast path.

    The frames come off the PipeWire node the input session already owns, so there is exactly
    one stream: on a host with no monitor attached that stream is Mutter's virtual monitor,
    and opening a second one would add a second monitor and move the windows under us.
    """

    def __init__(self, directory, name='look', node=None):
        self.path = os.path.join(str(directory), f'{name}.png')
        self.node = node

    def grab(self):
        # The first buffer read off the shared node is often torn (white below a band at the
        # top) on a real monitor, where a short-lived session of its own is safe and clean.
        grab(self.path, node=self.node)
        return Image.open(self.path).convert('RGB')


class _BoundCast:
    """A ScreenCast view of the stream the input session already opened.

    The recorder only needs `open()` / `virtual` / the size, and must not close a session that
    belongs to the app harness — the virtual monitor has to outlive the recording.
    """

    def __init__(self, session):
        self.node = session.node
        self.virtual = session.virtual
        self.width, self.height = session.size

    def open(self, timeout=20):
        return self.node

    def close(self):
        pass


def status(view):
    """The example's own status line (it names the shape and the backend it used)."""
    for text, _ in view.texts:
        if 'Flutter clip' in text or text.startswith('Could not'):
            return text
    return ''


def chips(view):
    """The five shadow preset chips, left to right.

    'Soft' also appears in the SHADOW row's readout above them, so the row is anchored on
    'None', which only the chip row has, instead of on the first match by name.
    """
    anchor = view.find('None')
    if anchor is None:
        raise Abort('the shadow preset chips are not in the control window')
    row = [(rect[0], text, rect) for text, rect in view.texts
           if abs(rect[1] - anchor[1]) <= 4]
    row.sort()
    labels = [text for _, text, _ in row]
    if labels != list(PRESETS):
        raise Abort(f'expected the preset chips {PRESETS}, found {labels}')
    return {text: rect for _, text, rect in row}


def play(keep_open, only, output=None):
    project = Path(os.environ.get('SHAPE_EXAMPLE_DIR',
                                  SCRATCH / 'shape-flutter-linux/examples/shaped_window_example'))
    app = PacedApp(flutter_executable(str(project)), backend='wayland')
    app.keep_open = keep_open
    # GuiApp's input session is created here, before the app launches: it owns the one
    # ScreenCast stream both the frames and the recording come from, and when the host has no
    # monitor attached that stream is Mutter's virtual monitor, which has to exist before the
    # windows are placed or they land nowhere.
    shots = Shots(SCRATCH, 'shape-demo-look',
                  node=app.input.node if app.input.virtual else None)
    # The recording reads the same stream, through its own cast view of it, so that a
    # virtual-monitor session is not created a second time.
    # On a real monitor that shared node yields torn or no frames, so the recording opens a
    # ScreenCast session of its own there (with the cursor painted in).
    cast = _BoundCast(app.input) if app.input.virtual else None
    recorder = Recorder(output, cast=cast) if output else None
    app.launch(min_windows=0)
    try:
        def controls():
            # The control window is the view that shows its own header.
            return next(v for v in app.views() if v.has(HEADER))

        def preview():
            # The drag handle is in every preview, shaped or rectangular.
            return next(v for v in app.views() if v.has('\u283f  DRAG ME'))

        def look():
            """(frame, control rect, preview centre) — everything from one live frame."""
            # A grab now and then returns a torn frame (white below a band at the top), so a
            # miss is retried before it counts.
            for _ in range(4):
                frame = shots.grab()
                control = find_controls(frame)
                if control is not None:
                    break
                time.sleep(0.5)
            if control is None:
                raise Abort('the control window is not in the captured frame; '
                            'is something covering the example?')
            found = find_preview(frame)
            return frame, control, found

        def ready(timeout=60):
            """Both windows rendered and probed; a cold debug start takes seconds."""
            deadline = time.time() + timeout
            while time.time() < deadline:
                if app.proc.poll() is not None:
                    raise Abort(f'{NAME} exited early; see {app.log_path}')
                try:
                    views = app.views()
                except Exception:
                    views = []
                if any(v.has(HEADER) for v in views) and any(v.has('\u283f  DRAG ME') for v in views):
                    return
                time.sleep(0.5)
            raise Abort(f'{NAME} did not render both windows; see {app.log_path}')

        def guard(point, control, blob):
            """Refuse any press the capture does not place on the control window."""
            x, y = point
            left, top, width, height = control
            if not (left + 6 <= x <= left + width - 6 and top + 6 <= y <= top + height - 6):
                raise Abort(f'refusing to press at ({x:.0f}, {y:.0f}): outside the control '
                            f'window {control}; stopping')
            if blob is not None:
                cx, cy = blob[0]
                if abs(x - cx) <= PREVIEW_SIZE // 2 + 6 and abs(y - cy) <= PREVIEW_SIZE // 2 + 6:
                    raise Abort(f'refusing to press at ({x:.0f}, {y:.0f}): inside the preview '
                                f'silhouette at {blob[0]}; stopping')

        def click(point, control, blob, hold=0.9):
            guard(point, control, blob)
            app.move(point)
            guard(point, control, blob)
            app.input.button(BTN_LEFT, True)
            time.sleep(0.06)
            app.input.button(BTN_LEFT, False)
            beat(hold)

        def drag(start, *legs, hold=0.35):
            app.move(start, scaled(300))
            app.input.button(BTN_LEFT, True)
            try:
                time.sleep(hold)
                for x, y, ms in legs:
                    app.move((x, y), scaled(ms))
                    time.sleep(0.06)
            finally:
                app.input.button(BTN_LEFT, False)
                time.sleep(0.2)

        # -- before recording: find the windows, move the preview out of the gallery -------
        ready()
        beat(1.0)
        frame, control, blob = look()
        if blob is None:
            raise Abort('the preview silhouette is not in the captured frame')
        left, top, width, height = control
        print(f'located control window {control}, preview silhouette centre {blob[0]} '
              f'(radii {blob[1]})', flush=True)
        cx, cy = blob[0]
        overlap = (abs(cx - (left + width / 2)) < width / 2 + PREVIEW_SIZE / 2 and
                   abs(cy - (top + height / 2)) < height / 2 + PREVIEW_SIZE / 2)
        if overlap:
            # GNOME puts the transient preview on top of the gallery. Its silhouette is a
            # shape, not a window, so clicks on the cards it covers never arrive; it has to be
            # moved, and on Wayland the example's own drag handle is the only way. This is the
            # only drag in the script and it happens before the recorder starts.
            wanted = (left + width + PREVIEW_GAP[0], top + PREVIEW_GAP[1])
            # Keep the whole preview (and its shadow gutter) on the screen: the frame is the
            # monitor, so its size is the screen size.
            frame_width, frame_height = frame.size
            wanted = (max(8, min(wanted[0], frame_width - PREVIEW_SIZE - 40)),
                      max(8, min(wanted[1], frame_height - PREVIEW_SIZE - 40)))
            handle = (cx, cy - PREVIEW_SIZE // 2 + HANDLE[1])
            goal = (wanted[0] + PREVIEW_SIZE // 2, wanted[1] + HANDLE[1])
            aim = (wanted[0] + PREVIEW_SIZE // 2, wanted[1] + PREVIEW_SIZE // 2)
            print(f'dragging the preview off the gallery: handle {handle} -> {goal} '
                  f'(content {wanted})', flush=True)
            drag(handle, (handle[0] + 70, handle[1] - 12, 220), (*goal, 520))
            beat(0.8)
            frame, control, blob = look()
            if blob is None:
                raise Abort('the preview silhouette was lost after moving it')
            cx, cy = blob[0]
            if abs(cx - aim[0]) > 30 or abs(cy - aim[1]) > 30:
                raise Abort(f'the preview is at {blob[0]}, not where it was dragged to '
                            f'({aim}); stopping so the video is not misleading')
            left, top, width, height = control
            near = 40  # the shadow never takes clicks, but keep it clear anyway
            if (cx + PREVIEW_SIZE // 2 + near > left and cx - PREVIEW_SIZE // 2 - near < left + width
                    and cy + PREVIEW_SIZE // 2 + near > top
                    and cy - PREVIEW_SIZE // 2 - near < top + height):
                raise Abort(f'the preview at {blob[0]} still overlaps the control window '
                            f'{control}; stopping')
            print(f'preview now at {blob[0]}: clear of the control window {control}', flush=True)

        # -- the clicks: gallery then presets, aimed through the probe -------------------
        view = controls()
        if view.size != (float(width), float(height)):
            raise Abort(f'the control view is {view.size}, not {CONTROL_SIZE}; the probe and '
                        f'the capture disagree')
        cards, grid = {}, []
        for index, name in enumerate(SHAPES):
            rect = view.find(name)
            if rect is None:
                raise Abort(f'the gallery card {name!r} is not in the control window')
            column, row = index % COLUMNS, index // COLUMNS
            want_x = (GALLERY_LEFT + column * (COLUMN_WIDTH + GAP)
                      + COLUMN_WIDTH / 2)
            got_x = rect[0] + rect[2] / 2
            grid.append((name, round(want_x, 1), round(got_x, 1), round(rect[1], 1), row))
            if abs(want_x - got_x) > 2:
                raise Abort(f'the {name} label is {got_x:.1f} px across, not on the {COLUMNS} '
                            f'column grid at {want_x:.1f}; the layout this script assumes moved')
            cards[name] = (left + want_x, top + rect[1] - CARD_CENTRE_ABOVE_LABEL)
        # The gallery really is the documented 4 x 3 grid: the columns line up above, and the
        # three rows are evenly spaced and sit between the two rows of headings around them.
        steps = [grid[r + COLUMNS][3] - grid[r][3] for r in range(0, len(grid) - COLUMNS)]
        heading = view.find('SHAPE COLLECTION')
        below = view.find('Window')
        if len(set(round(s) for s in steps)) != 1 or not 60 < steps[0] < 220:
            raise Abort(f'the gallery rows are not evenly spaced: {steps}')
        if not all(heading[1] + 20 < y < below[1] - 4 for _, _, _, y, _ in grid):
            raise Abort('the gallery labels are not between the rows of headings')
        print(f'gallery grid: columns {sorted({g[1] for g in grid})} match the probe '
              f'{sorted({g[2] for g in grid})}; rows {sorted({g[3] for g in grid})} '
              f'step {steps[0]:.1f}', flush=True)
        preset = chips(view)
        for name, rect in preset.items():
            preset[name] = (left + rect[0] + rect[2] / 2, top + rect[1] + rect[3] / 2)

        # Every press point is proved from the frame that located the windows: inside the
        # control window, and nowhere near the preview's silhouette.
        for name, point in list(cards.items()) + list(preset.items()):
            guard(point, control, blob)

        scenes = [('shapes', lambda: scene_shapes()), ('shadow', lambda: scene_shadow())]
        if only:
            scenes = [s for s in scenes if s[0] == only]
            if not scenes:
                raise SystemExit(f'unknown scene {only!r}; pick from ["shapes", "shadow"]')

        reached = {'shapes': [], 'presets': []}

        def card(name):
            view = controls()
            click(cards[name], control, blob, hold=0.9)
            if not preview().has(name):
                raise Abort(f'the preview does not show {name!r} after clicking its card: '
                            f'{status(controls())}')
            reached['shapes'].append(name)
            print(f'shape  {len(reached["shapes"]):2d}/{len(SHAPES)} {name:9s} '
                  f'-> preview shows {name!r}', flush=True)

        def chip(name, hold=1.5):
            click(preset[name], control, blob, hold=hold)
            view = controls()
            readout = min((r[1], t) for t, r in view.texts if t in PRESETS)[1]
            if readout != name:
                raise Abort(f'the shadow readout says {readout!r}, not {name!r}')
            reached['presets'].append(name)
            print(f'preset {len(reached["presets"]):2d}/{len(PRESETS)} {name:6s} '
                  f'-> shadow readout {readout!r}', flush=True)

        def scene_shapes():
            # Every silhouette in the gallery, one after the other, left to right and top to
            # bottom: the polygon the clip follows morphs over 450 ms and the label follows it.
            for name in SHAPES:
                card(name)
            print('shapes: ' + status(controls()), flush=True)

        def scene_shadow():
            # None, Soft, Float, Sharp, Glow: the contour shadow follows the same polygon,
            # outside the shape, without taking clicks. The presets differ subtly, so each one
            # is held a little longer than a gallery click.
            for name in PRESETS:
                chip(name)
            print('shadow: ' + reached['presets'][-1], flush=True)

        if recorder:
            # The app is already up and arranged, so the take opens on it rather than on an
            # empty desktop: nothing is trimmed afterwards, and a cold launch costs seconds.
            recorder.start()
            print('\u25cf recording', flush=True)

        for _, scene in scenes:
            scene()

        beat(1.6)
        view = controls()
        print(f'proof: {status(view)} | controls={control} '
              f'preview={(round(cx - PREVIEW_SIZE / 2), round(cy - PREVIEW_SIZE / 2), PREVIEW_SIZE, PREVIEW_SIZE)}',
              flush=True)
        print(f'reached: {len(reached["shapes"])}/{len(SHAPES)} shapes, '
              f'{len(reached["presets"])}/{len(PRESETS)} presets', flush=True)
        for line in [l for l in app.output().splitlines() if l.startswith('[shape]')][-4:]:
            print('  ', line, flush=True)
    finally:
        if recorder:
            recorder.stop()
            recorder.report()
        print(f'App log: {app.log_path}', flush=True)
        app.quit()


def main():
    global PACE
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--record', metavar='OUT.mp4', nargs='?', const='',
                        help='record the screen (default: $REMOTE_SCRATCH/<script>-linux.mp4)')
    parser.add_argument('--build', action='store_true',
                        help='build the example in debug first (in the scratch checkout)')
    parser.add_argument('--pace', type=float, default=PACE,
                        help=f'speed factor for motions and pauses (default {PACE})')
    parser.add_argument('--keep-open', action='store_true',
                        help='leave the example running at the end')
    parser.add_argument('--only', help='run a single scene from a fresh launch')
    args = parser.parse_args()
    PACE = args.pace

    project = Path(os.environ.get('SHAPE_EXAMPLE_DIR',
                                  SCRATCH / 'shape-flutter-linux/examples/shaped_window_example'))
    if args.build:
        build_flutter(str(project))
    try:
        assert_idle()
    except Abort as e:
        raise SystemExit(f'Stopped: {e}')

    # The recorder is made inside play(), once the harness has the one stream it reads.
    output = (args.record or str(SCRATCH / f'{Path(__file__).stem}-linux.mp4')) \
        if args.record is not None else None
    failed = None
    try:
        play(args.keep_open, args.only, output)  # starts the recorder once the app is arranged
        beat(1.0)
    except (Abort, LookupError, StopIteration, AssertionError) as e:
        failed = e
        traceback.print_exc()
    if failed:
        raise SystemExit(f'Stopped: {failed!r}')


if __name__ == '__main__':
    sys.exit(main())
