"""Launch a desktop app, look at it, and drive it with guarded synthetic input (macOS).

    import sys; sys.path.insert(0, '.agents/skills/gui-test/scripts/macos')
    from guiapp import GuiApp, Abort, flutter_executable, pause

    app = GuiApp(flutter_executable('path/to/flutter_project'))   # or any executable
    app.launch(min_windows=1)
    try:
        view = next(v for v in app.views() if v.has('Some heading'))
        frame = app.window('Window title')
        app.click(app.to_screen(frame, view, view.center('OK')))
    finally:
        app.quit()

Coordinates are screen points with a top-left origin. Every press is checked to land
on one of the app's own windows; `Abort` is raised otherwise.
"""

import os
import subprocess
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
SKILLS = os.path.normpath(os.path.join(HERE, '..', '..', '..'))
INPUT = os.path.join(HERE, 'input')
# uiprobe.py: in its own skill here; next to this file on a remote host (flat kit).
sys.path[:0] = [HERE, os.path.join(SKILLS, 'flutter-ui-probe', 'scripts')]
from uiprobe import App as Probe  # noqa: E402


class MenuItem:
    """An item of an open native menu, as Accessibility reports it."""

    def __init__(self, line):
        # The driver's output is stripped, so the last line may lose its empty mark.
        depth, title, frame, flags, mark = (line.split('\t') + [''])[:5]
        self.depth = int(depth)  # 0 = the menu itself, 1 = an open submenu, …
        self.title = title
        self.frame = tuple(int(v) for v in frame.split())  # x y w h, screen points
        self.enabled = 'e' in flags
        self.has_submenu = 's' in flags
        self.separator = '-' in flags
        self.is_menu = 'M' in flags  # the menu window's own frame, not an item
        self.mark = mark  # '✓' checked, '-' mixed, '' unchecked

    @property
    def checked(self):
        return self.mark not in ('', '-')

    @property
    def center(self):
        x, y, w, h = self.frame
        return x + w / 2, y + h / 2

    def __repr__(self):
        return f'MenuItem({self.title!r}, {self.frame}, enabled={self.enabled}, mark={self.mark!r})'


class Abort(Exception):
    """The script must not go on: wrong window under the cursor, machine in use, …"""


def inp(*args, check=True):
    """Runs the input driver next to this file; returns its stdout."""
    if any(a is None or str(a) == '' for a in args):
        raise Abort(f'refusing to run input with an empty argument: {args}')
    return subprocess.run([INPUT, *map(str, args)], check=check, capture_output=True,
                          text=True).stdout.strip()


def pause(seconds):
    time.sleep(seconds)


def assert_idle(ms=1500):
    """Raises Abort when the cursor is moving: someone is using the machine."""
    if subprocess.run([INPUT, 'idle', str(ms)]).returncode != 0:
        raise Abort('the mouse is moving; someone is using this machine')


def flutter_executable(project_dir, name=None, mode='Debug'):
    """The executable inside a Flutter project's built macOS bundle.

    `name` is the product name; it defaults to the project directory's name.
    """
    project_dir = os.path.abspath(project_dir)
    name = name or os.path.basename(project_dir)
    return os.path.join(project_dir, 'build', 'macos', 'Build', 'Products', mode, f'{name}.app',
                        'Contents', 'MacOS', name)


def build_flutter(project_dir):
    subprocess.run(['flutter', 'build', 'macos', '--debug'], check=True, cwd=project_dir)


class GuiApp:
    def __init__(self, executable, args=()):
        self.executable = executable
        self.args = list(args)
        self.name = os.path.basename(executable)
        self.proc = None
        self.log_path = None
        self.probe = None
        self.keep_open = False

    # -- lifecycle ------------------------------------------------------------

    def launch(self, min_windows=1, flutter=True, timeout=30):
        """Starts the app and waits for its windows (and, for Flutter, its VM service)."""
        if not os.path.exists(self.executable):
            raise SystemExit(f'{self.executable} is missing; build it first')
        log = tempfile.NamedTemporaryFile('w', suffix=f'.{self.name}.log', delete=False)
        self.log_path = log.name
        self.proc = subprocess.Popen([self.executable, *self.args], stdout=log,
                                     stderr=subprocess.STDOUT)
        self.probe = Probe(self.log_path)
        deadline = time.time() + timeout
        while time.time() < deadline:
            if self.proc.poll() is not None:
                raise Abort(f'{self.name} exited early; see {self.log_path}')
            if (not flutter or self.probe.vm_url()) and len(self.windows()) >= min_windows:
                break
            time.sleep(0.3)
        else:
            self.quit()
            raise Abort(f'{self.name} did not come up; see {self.log_path}')
        pause(1.5)  # first frames
        inp('activate', self.proc.pid)
        pause(0.5)

    def quit(self):
        if self.keep_open or not self.proc or self.proc.poll() is not None:
            return
        self.proc.terminate()
        try:
            self.proc.wait(5)
        except subprocess.TimeoutExpired:
            self.proc.kill()

    def blur(self):
        """Takes the focus away without a click, so the next press on this app is a focus change.

        The Dock process becomes the active app: it has no windows to raise, so nothing
        covers this app (activating Finder instead brings a Finder window forward).
        """
        dock = subprocess.run(['pgrep', '-x', 'Dock'], capture_output=True, text=True).stdout.split()
        if not dock:
            raise Abort('the Dock process is not running; cannot take the focus away')
        inp('activate', dock[0], 'soft')
        pause(0.6)
        if int(inp('front')) == self.proc.pid:
            raise Abort('could not take the focus away from the app')

    def set_frame(self, x, y, w, h, title=None):
        """Moves and resizes the app's first window, or the one with this title (no input
        involved)."""
        args = ['setframe', self.proc.pid, int(x), int(y), int(w), int(h)]
        inp(*args, *([title] if title is not None else []))
        pause(0.8)

    def output(self):
        """Everything the app has printed so far."""
        return open(self.log_path).read()

    # -- looking --------------------------------------------------------------

    def windows(self):
        """[(title, (x, y, w, h))] — frames include the title bar."""
        out = []
        for line in inp('windows', self.proc.pid).splitlines():
            title, _, frame = line.rpartition('\t')
            out.append((title, tuple(int(v) for v in frame.split())))
        return out

    def window(self, title):
        """The frame of the window with this title."""
        for t, frame in self.windows():
            if t == title:
                return frame
        raise LookupError(f'no window titled {title!r}: {[t for t, _ in self.windows()]}')

    def views(self):
        """flutter-ui-probe views of a debug Flutter app."""
        return self.probe.views()

    @staticmethod
    def visible_frame(point):
        """(x, y, w, h) of the screen at a point without the menu bar and the Dock: where
        AppKit keeps windows and menus."""
        return tuple(int(v) for v in inp('visible', int(point[0]), int(point[1])).split())

    def menu_items(self):
        """[MenuItem] of the app's open native menus (context menus, pop-ups), open
        submenus included; [] when none is open. Safe while a menu is tracking — unlike
        `views()`, which may stall until the menu closes."""
        return [i for i in self._menu_lines() if not i.is_menu]

    def _menu_lines(self):
        return [MenuItem(line) for line in inp('menus', self.proc.pid).splitlines() if line]

    def menu_frames(self):
        """{depth: (x, y, w, h)} of the open menu windows (padding and rounded corners
        included) — what a placement is measured against."""
        return {i.depth: i.frame for i in self._menu_lines() if i.is_menu}

    def menu_item(self, title, depth=None):
        for item in self.menu_items():
            if item.title == title and (depth is None or item.depth == depth):
                return item
        raise LookupError(f'no open menu item {title!r}: '
                          f'{[i.title for i in self.menu_items() if not i.separator]}')

    def wait_menu(self, is_open=True, timeout=5, depth=0):
        """Waits until a menu (or a submenu, depth=1) is open — or closed with is_open=False."""
        deadline = time.time() + timeout
        while time.time() < deadline:
            if any(i.depth >= depth for i in self.menu_items()) == is_open:
                return True
            time.sleep(0.15)
        return False

    @staticmethod
    def to_screen(frame, view, point):
        """A view point to the screen; the content sits at the bottom of the frame."""
        x, y, w, h = frame
        return x + point[0], y + (h - view.size[1]) + point[1]

    # -- acting, guarded ------------------------------------------------------

    def _check(self, x, y):
        owner = int(inp('owner', int(x), int(y)))
        if owner != self.proc.pid:
            raise Abort(f'({x:.0f}, {y:.0f}) belongs to pid {owner}, not {self.name}; stopping')

    def _check_menu_item(self, item, x, y):
        owner = int(inp('owner', int(x), int(y), 'menus'))
        fx, fy, fw, fh = item.frame
        if owner != self.proc.pid or not (fx <= x < fx + fw and fy <= y < fy + fh):
            raise Abort(f'({x:.0f}, {y:.0f}) is not on menu item {item.title!r} of '
                        f'{self.name} (owner pid {owner}); stopping')

    def move(self, point, ms=600):
        inp('move', int(point[0]), int(point[1]), ms)

    def click(self, point, ms=450):
        self.move(point, ms)
        self._check(*point)
        inp('click', int(point[0]), int(point[1]))

    def right_click(self, point, ms=450):
        self.move(point, ms)
        self._check(*point)
        inp('rclick', int(point[0]), int(point[1]))

    def hover_menu_item(self, title, depth=None, ms=400):
        """Moves onto an open menu item (opens its submenu); returns the item."""
        item = self.menu_item(title, depth)
        self.move(item.center, ms)
        # Re-read after the move: menus scroll and submenus open under the cursor.
        item = self.menu_item(title, depth)
        self._check_menu_item(item, *item.center)
        return item

    def click_menu_item(self, title, depth=None, ms=400):
        """Clicks an item of an open native menu, checking the press lands on that item
        of this app's menu window."""
        item = self.hover_menu_item(title, depth, ms)
        inp('click', *map(int, item.center))
        return item

    def double_click(self, point, ms=450):
        self.move(point, ms)
        self._check(*point)
        inp('dblclick', int(point[0]), int(point[1]))

    def drag(self, start, *legs, approach_ms=500):
        """legs: (x, y, ms) tuples, glided through with the button held."""
        self.move(start, approach_ms)
        self._check(*start)
        args = [int(start[0]), int(start[1])]
        for x, y, ms in legs:
            args += [int(x), int(y), int(ms)]
        inp('drag', *args)

    def scroll(self, point, lines):
        self.move(point, 400)
        self._check(*point)
        inp('scroll', int(point[0]), int(point[1]), lines)


class Checks:
    """Collects PASS/FAIL lines so one failure does not hide the rest."""

    def __init__(self):
        self.failures = 0

    def check(self, what, ok, detail=''):
        self.failures += 0 if ok else 1
        print(f"{'PASS' if ok else 'FAIL'} {what}{' — ' + str(detail) if detail else ''}",
              flush=True)

    def near(self, what, actual, expected, tolerance=2):
        ok = all(abs(a - e) <= tolerance for a, e in zip(actual, expected))
        self.check(what, ok, f'got {tuple(actual)}, expected {tuple(expected)} ±{tolerance}')
