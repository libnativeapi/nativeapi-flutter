#!/usr/bin/env python3
"""GUI test (Linux, GNOME) of tray_icon_example: animated tray icons really are rendered
and pushed frame by frame (frame counter, rate, Pause / Step, the widget-captured
animation, three icons at once) and the properties read back from the native getters
(title, tooltip, visibility, trigger). The Linux twin of flutter_tray_icon_test.py
(macOS) and flutter_tray_icon_test.ps1 (Windows).

On Linux a tray icon is a StatusNotifierItem drawn by the shell: there is no geometry to
ask for and the app cannot pop the menu up itself, so the example offers neither
"Window to icon" nor "Open menu" here, and this test checks that instead of using them.
The icon in the top bar and its menu belong to gnome-shell, outside the app's windows:
the driver does not press there, those stay manual items of the example's Checklist tab.

    .agents/skills/remote-hosts/scripts/remote.sh linux desktop \
        tools/gui/flutter_tray_icon_test_linux.py 300

The example is expected built in debug in the host's checkout ($REMOTE_WORKSPACE). The
app runs under GDK_BACKEND=x11 (only X11 windows can be measured from outside). It takes
over the mouse for ~80 s.
"""

import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # the flat kit on a remote host

from guiapp import Abort, Checks, GuiApp, assert_idle, flutter_executable, pause  # noqa: E402
from xinput import session_type  # noqa: E402

NAME = 'tray_icon_example'
# TrayManager never registers icons (specs/managers.md, known gap).
KNOWN_FAILURES = {'managed'}


def executable():
    workspace = os.environ.get('REMOTE_WORKSPACE') or os.path.dirname(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    return flutter_executable(
        os.path.join(workspace, 'bindings', 'flutter', 'examples', NAME))


def registered_items(pid):
    """The app's icons as the shell's StatusNotifierWatcher lists them. core names each
    item org.kde.StatusNotifierItem-<pid>-<n>."""
    out = subprocess.run(
        ['gdbus', 'call', '--session', '--dest', 'org.kde.StatusNotifierWatcher',
         '--object-path', '/StatusNotifierWatcher',
         '--method', 'org.freedesktop.DBus.Properties.Get',
         'org.kde.StatusNotifierWatcher', 'RegisteredStatusNotifierItems'],
        capture_output=True, text=True, timeout=10).stdout
    return sorted(set(re.findall(rf'org\.kde\.StatusNotifierItem-{pid}-\d+', out)))


def main():
    assert_idle()
    app = GuiApp(executable(), backend='x11')
    app.keep_open = '--keep-open' in sys.argv
    checks = Checks()
    print(f'session: {session_type()}, app backend: x11', flush=True)
    app.launch(min_windows=1)
    try:
        title = app.windows()[0][0]

        def view():
            return next(v for v in app.views() if v.has('Tray icons'))

        def texts():
            return [t for t, _ in view().texts]

        def text(prefix):
            return next((t for t in texts() if t.startswith(prefix)), None)

        def view_origin(v):
            """Where the Flutter view's top-left corner is on the screen.

            A Flutter window on GTK has client-side decorations: its X window also holds
            the invisible shadow margins (_GTK_FRAME_EXTENTS: left, right, top, bottom)
            and the header bar, so the harness's to_screen() — which takes the X window
            for the view — would press ~70 px too high. The view sits at the bottom of
            what is left inside the shadows.
            """
            window = next(w for w in app._windows() if w.title == title)
            x, y, w, h = window.content
            left, right, top, bottom = (app.x.cardinals(window.xid, '_GTK_FRAME_EXTENTS')
                                        + [0, 0, 0, 0])[:4]
            return x + left, y + h - bottom - v.size[1]

        def press(label, settle=0.7):
            v = view()
            ox, oy = view_origin(v)
            cx, cy = v.center(label)
            app.click((round(ox + cx), round(oy + cy)))
            pause(settle)

        def frame_count():
            m = re.match(r'frame (\d+) · ([\d.]+) fps', text('frame ') or '')
            if not m:
                raise Abort('the preview shows no frame counter')
            return int(m.group(1)), float(m.group(2))

        def checklist():
            status = {}
            for line in app.output().splitlines():
                m = re.search(r'\[checklist\] (\S+) (\w+) ?(.*)', line)
                if m:
                    status[m.group(1)] = (m.group(2), m.group(3))
            return status

        items = registered_items(app.proc.pid)
        checks.check('the shell lists the icon', len(items) == 1, f'{items}')

        size = tuple(map(round, view().size))
        checks.check('window content is 400 x 640', size == (400, 640), f'{size}')
        checks.check('starts on the asset icon', text('Asset icon') == 'Asset icon · still')

        # -- animation: frames are rendered and pushed --------------------------
        # What a frame costs depends on the machine (GPU read-back, PNG, D-Bus): ~2 ms on
        # the Mac, ~27 ms on the Celeron NUC this was written on, which tops out near
        # 20 fps. The pipeline is asserted at 10 fps, which any host holds; what 30 fps
        # really gives here is printed for the record, not judged.
        press('Progress', settle=4.0)
        count, fps = frame_count()
        checks.check('Progress plays', text('Progress ·') == 'Progress · playing')
        print(f'INFO at 30 fps requested: {count} frames, {fps} fps, {text("render ")}, '
              f'{text("dropped ")}', flush=True)
        press('10 fps', settle=11.5)
        count, fps = frame_count()
        checks.check('10 frames a second reach the tray', count >= 100 and fps >= 9,
                     f'{count} frames, {fps} fps')
        # Reading the render tree stalls the UI thread, so a probe can cost a frame or two.
        dropped = int(re.match(r'dropped (\d+) ', text('dropped ')).group(1))
        checks.check('next to no dropped frames', dropped <= 3, text('dropped '))
        checks.check('frames are 36 px (2x)', '36×36 px' in (text('render ') or ''),
                     text('render '))

        press('Pause', settle=0.5)
        a = frame_count()[0]
        pause(1.0)
        b = frame_count()[0]
        checks.check('Pause stops the frames',
                     a == b and text('Progress ·') == 'Progress · paused', f'{a} → {b}')
        press('Step', settle=0.5)
        checks.check('Step renders exactly one frame', frame_count()[0] == b + 1,
                     f'{b} → {frame_count()[0]}')
        press('Resume', settle=1.0)
        checks.check('Resume continues', frame_count()[0] > b + 5, f'{frame_count()[0]}')

        press('Any widget', settle=3.5)
        count, fps = frame_count()
        checks.check('a live widget is captured into frames', count >= 25 and fps >= 9,
                     f'{count} frames, {fps} fps')

        press('Download', settle=1.5)
        press('Properties', settle=0.8)
        checks.check('the Download scene drives the title',
                     bool(re.match(r'title "\d+%"', text('title ') or '')), text('title '))
        press('Animate', settle=0.5)

        press('Three icons', settle=2.0)
        chips = texts()
        checks.check('three icons exist', all(c in chips for c in ('#1', '#2', '#3')))
        # Each icon needs a D-Bus connection of its own: a watcher given a bus name looks
        # at the fixed path /StatusNotifierItem, which a connection can export only once.
        items = registered_items(app.proc.pid)
        checks.check('the shell lists all three icons', len(items) == 3, f'{items}')
        running = []
        for number in ('#1', '#2', '#3'):
            press(number, settle=1.2)
            running.append(text('Spinner ·') or text('Wave ·') or text('Clock ·') or '')
        checks.check('each of the three plays its own animation',
                     running == ['Spinner · playing', 'Wave · playing', 'Clock · playing'],
                     f'{running}')
        press('Remove #3', settle=0.6)
        press('Remove #2', settle=0.6)
        checks.check('removing leaves one icon', '#2' not in texts() and '#1' in texts())
        items = registered_items(app.proc.pid)
        checks.check('the shell drops the removed icons', len(items) == 1, f'{items}')
        press('Stop', settle=1.0)
        checks.check('Stop returns to the asset icon', text('Asset icon') is not None)
        for kind in ('Drawn', 'Base64', 'Asset'):
            press(kind, settle=0.8)
            checks.check(f'the {kind} still icon is set',
                         text(f'{kind} icon') == f'{kind} icon · still')

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
        press('Right')

        # -- what a StatusNotifierItem cannot do is not offered ------------------
        shown = texts()
        checks.check('no "Open menu" on Linux, a note instead',
                     'Open menu' not in shown and 'only the shell opens it on Linux' in shown)
        checks.check('getBounds is empty, as the SNI spec leaves it',
                     (text('bounds ') or '').startswith('bounds 0,0 0×0'), text('bounds '))
        before = app.window(title)
        press('Window to icon', settle=1.0)  # disabled: the click must do nothing
        checks.check('"Window to icon" is disabled and leaves the window alone',
                     app.window(title) == before, f'{before} → {app.window(title)}')

        checks.check('no icon failed to register on D-Bus',
                     'D-Bus initialisation failed' not in app.output())

        # -- the example's own checklist ----------------------------------------
        status = checklist()
        for item in ('supported', 'create', 'visible', 'readBack', 'frames'):
            state, detail = status.get(item, ('open', ''))
            checks.check(f'checklist: {item}', state == 'pass', f'{state} {detail}')
        unexpected = {k: v for k, v in status.items()
                      if v[0] == 'fail' and k not in KNOWN_FAILURES}
        checks.check('checklist: no unexpected failures', not unexpected, f'{unexpected}')
    except (Abort, LookupError) as e:
        checks.check('ran to the end', False, f'{e}')
    finally:
        app.quit()
        print(f'--- app log ---\n{app.output()[-1500:]}', flush=True)
    print(f'{checks.failures} failure(s)', flush=True)
    return 1 if checks.failures else 0


if __name__ == '__main__':
    sys.exit(main())
