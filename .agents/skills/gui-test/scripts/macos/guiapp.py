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
    def to_screen(frame, view, point):
        """A view point to the screen; the content sits at the bottom of the frame."""
        x, y, w, h = frame
        return x + point[0], y + (h - view.size[1]) + point[1]

    # -- acting, guarded ------------------------------------------------------

    def _check(self, x, y):
        owner = int(inp('owner', int(x), int(y)))
        if owner != self.proc.pid:
            raise Abort(f'({x:.0f}, {y:.0f}) belongs to pid {owner}, not {self.name}; stopping')

    def move(self, point, ms=600):
        inp('move', int(point[0]), int(point[1]), ms)

    def click(self, point, ms=450):
        self.move(point, ms)
        self._check(*point)
        inp('click', int(point[0]), int(point[1]))

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
