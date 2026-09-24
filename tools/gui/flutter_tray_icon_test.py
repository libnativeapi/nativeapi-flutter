#!/usr/bin/env python3
"""GUI test (macOS) of tray_icon_example: animated tray icons really are rendered and
pushed frame by frame (frame counter, rate, no dropped frames, Pause / Step, the
widget-captured animation, three icons at once), every property reads back from the
native getters (title, tooltip, visibility, trigger, bounds), and the context menu opens
from code, shows its items and closes again from code.

    tools/gui/flutter_tray_icon_test.py [--build] [--keep-open]

Built on the gui-test skill (.agents/skills). It takes over the mouse for ~70 s.

What it does not do: click the tray icon itself. The input driver refuses every press on
the menu-bar layer by design, so the clicked / right-clicked / double-clicked events and
the look of the icon in the tray stay manual items of the example's own Checklist tab.
The auto items of that checklist are asserted here through the `[checklist]` lines the
example prints.
"""

import re
import sys

from common import build_example, example
from guiapp import Abort, Checks, assert_idle, pause

NAME = 'tray_icon_example'
MENU_ITEMS = ['Show window', 'Animate', 'Notifications', 'Check for updates', 'About', 'Quit']

# TrayManager never registers icons (specs/managers.md, known gap), so this checklist
# item is expected to fail until core fixes it.
KNOWN_FAILURES = {'managed'}


def main():
    if '--build' in sys.argv:
        build_example(NAME)
    assert_idle()
    app = example(NAME, args=['-ApplePersistenceIgnoreState', 'YES'])
    app.keep_open = '--keep-open' in sys.argv
    checks = Checks()
    app.launch(min_windows=1)
    try:
        title = app.windows()[0][0]

        def look():
            """(frame, view) as they are now; never probe while a menu is open."""
            if app.menu_items():
                raise Abort('a menu is still open; refusing to probe')
            return app.window(title), next(v for v in app.views() if v.has('Tray icons'))

        def texts():
            return [t for t, _ in look()[1].texts]

        def text(prefix):
            return next((t for t in texts() if t.startswith(prefix)), None)

        def press(label, settle=0.7, prefix=False):
            frame, view = look()
            x, y = app.to_screen(frame, view, view.center(label, prefix=prefix))
            app.click((round(x), round(y)))
            pause(settle)

        def frame_count():
            m = re.match(r'frame (\d+) · ([\d.]+) fps', text('frame ') or '')
            if not m:
                raise Abort('the preview shows no frame counter')
            return int(m.group(1)), float(m.group(2))

        def checklist():
            """Latest status of each checklist item, from the example's stdout."""
            status = {}
            for line in app.output().splitlines():
                m = re.search(r'\[checklist\] (\S+) (\w+) ?(.*)', line)
                if m:
                    status[m.group(1)] = (m.group(2), m.group(3))
            return status

        # -- the window itself -------------------------------------------------
        frame, view = look()
        checks.check('window content is 400 x 640', tuple(map(round, view.size)) == (400, 640),
                     f'{view.size}')
        checks.check('starts on the asset icon', text('Asset icon') == 'Asset icon · still')

        # -- animation: frames are rendered and pushed --------------------------
        press('Progress', settle=4.5)
        count, fps = frame_count()
        checks.check('Progress plays', text('Progress ·') == 'Progress · playing')
        checks.check('about 30 frames a second reach the tray', count >= 100 and fps >= 27,
                     f'{count} frames, {fps} fps')
        # Reading the render tree stalls the UI thread for a moment, so a probe can cost a frame.
        dropped = int(re.match(r'dropped (\d+) ', text('dropped ')).group(1))
        checks.check('next to no dropped frames', dropped <= 3, text('dropped '))
        checks.check('frames are 36 px (2x)', '36×36 px' in (text('render ') or ''), text('render '))

        press('Pause', settle=0.5)
        a = frame_count()[0]
        pause(1.0)
        b = frame_count()[0]
        checks.check('Pause stops the frames', a == b and text('Progress ·') == 'Progress · paused',
                     f'{a} → {b}')
        press('Step', settle=0.5)
        checks.check('Step renders exactly one frame', frame_count()[0] == b + 1,
                     f'{b} → {frame_count()[0]}')
        press('Resume', settle=1.0)
        checks.check('Resume continues', frame_count()[0] > b + 5, f'{frame_count()[0]}')

        press('60 fps', settle=3.0)
        count, fps = frame_count()
        checks.check('60 fps is reached', fps >= 54, f'{fps} fps')
        press('3x', settle=1.0)
        checks.check('3x renders 54 px frames', '54×54 px' in (text('render ') or ''),
                     text('render '))
        press('2x', settle=0.3)
        press('30 fps', settle=0.3)

        press('Any widget', settle=2.5)
        count, fps = frame_count()
        checks.check('a live widget is captured into frames', count >= 40 and fps >= 24,
                     f'{count} frames, {fps} fps')

        press('Download', settle=1.5)
        press('Properties', settle=0.8)
        title_line = text('title ')
        checks.check('the Download scene drives the title',
                     bool(re.match(r'title "\d+%"', title_line or '')), title_line)
        press('Animate', settle=0.5)

        press('Three icons', settle=2.0)
        chips = texts()
        checks.check('three icons exist', all(c in chips for c in ('#1', '#2', '#3')))
        running = []
        for number in ('#1', '#2', '#3'):
            press(number, settle=1.2)
            running.append((text('frame ') or '', (text('Spinner ·') or text('Wave ·')
                                                  or text('Clock ·') or '')))
        checks.check('each of the three plays its own animation',
                     [r[1].split(' ·')[0] for r in running] == ['Spinner', 'Wave', 'Clock']
                     and all(r[1].endswith('playing') for r in running), f'{running}')
        press('Remove #3', settle=0.6)
        press('Remove #2', settle=0.6)
        checks.check('removing leaves one icon', '#2' not in texts() and '#1' in texts())
        press('Stop', settle=1.0)
        checks.check('Stop returns to the asset icon', text('Asset icon') is not None)
        for kind in ('Drawn', 'Base64', 'Asset'):
            press(kind, settle=0.8)
            checks.check(f'the {kind} still icon is set', text(f'{kind} icon') == f'{kind} icon · still')

        # -- properties read back from the native getters -----------------------
        press('Properties', settle=0.8)
        press('42%')
        checks.check('title reads back', text('title ') == 'title "42%"', text('title '))
        press('你好')
        checks.check('a CJK title reads back', text('title ') == 'title "你好"', text('title '))
        press('No title')
        checks.check('a cleared title reads back empty',
                     text('title ') in ('title null', 'title ""'), text('title '))
        press('2 lines')
        checks.check('a two-line tooltip reads back',
                     text('tooltip ') == r'tooltip "Line one\nLine two"', text('tooltip '))
        press('Hidden')
        checks.check('setVisible(false) reads back', 'visible false' in (text('id ') or ''),
                     text('id '))
        press('Shown')
        checks.check('setVisible(true) reads back', 'visible true' in (text('id ') or ''),
                     text('id '))
        press('Double')
        checks.check('the trigger reads back', 'trigger doubleClicked' in (text('id ') or ''),
                     text('id '))
        press('Manual')
        press('Refresh')
        m = re.match(r'bounds (-?\d+),(-?\d+) (\d+)×(\d+)', text('bounds ') or '')
        checks.check('getBounds is a real rectangle in the menu bar',
                     bool(m) and int(m.group(3)) > 0 and int(m.group(4)) > 0
                     and int(m.group(2)) < 40, text('bounds '))

        press('Window to icon', settle=1.2)
        if m:
            ix, iy, iw, ih = map(int, m.groups())
            wx, wy, ww, wh = app.window(title)
            checks.check('Window to icon puts the window right below the icon, centred on it',
                         abs((wx + ww / 2) - (ix + iw / 2)) <= 12 and 0 <= wy - (iy + ih) <= 16,
                         f'window {(wx, wy, ww, wh)}, icon {(ix, iy, iw, ih)}')

        # -- the menu, opened and closed from code ------------------------------
        press('Open menu', settle=0.3)
        opened = app.wait_menu()
        checks.check('openContextMenu opens the menu', opened)
        if opened:
            pause(0.4)
            shown = [i.title for i in app.menu_items() if i.depth == 0 and not i.separator]
            checks.check('the menu shows its items', shown == MENU_ITEMS, f'{shown}')
            disabled = app.menu_item('Check for updates')
            checks.check('the disabled item is disabled', not disabled.enabled)
            checks.check('the checkbox starts checked', app.menu_item('Notifications').checked)
            app.click_menu_item('About')
            checks.check('picking an item closes the menu', app.wait_menu(is_open=False))
            pause(0.8)
            log = [t[9:] for t in texts() if re.match(r'\d\d:\d\d:\d\d ', t)]
            checks.check('the item click arrives', 'menu item "about" #1' in log, f'{log}')

        press('Open, close in 2 s', settle=0.3)
        opened = app.wait_menu()
        checks.check('the menu opens again', opened)
        closed = app.wait_menu(is_open=False, timeout=5)
        checks.check('closeContextMenu closes it without a click', closed)
        if not closed:
            raise Abort('the menu stayed open; leaving it for a person to close')
        pause(2.0)

        # -- the example's own checklist ----------------------------------------
        status = checklist()
        for item in ('supported', 'create', 'menuOpenClose', 'openMenu', 'closeMenu',
                     'visible', 'readBack', 'bounds', 'frames'):
            state, detail = status.get(item, ('open', ''))
            checks.check(f'checklist: {item}', state == 'pass', f'{state} {detail}')
        unexpected = {k: v for k, v in status.items()
                      if v[0] == 'fail' and k not in KNOWN_FAILURES}
        checks.check('checklist: no unexpected failures', not unexpected, f'{unexpected}')
    finally:
        app.quit()
    return 1 if checks.failures else 0


if __name__ == '__main__':
    sys.exit(main())
