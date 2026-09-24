"""Launch a desktop app, look at it, and drive it with guarded synthetic input (Linux).

The Linux twin of scripts/macos/guiapp.py, with the same shape:

    import sys; sys.path.insert(0, '.agents/skills/gui-test/scripts/linux')
    from guiapp import GuiApp, Abort, pause

    app = GuiApp('/path/to/executable')
    app.launch(min_windows=2, flutter=False)
    try:
        frame = app.window('Dock - drop the panel here')
        app.click((frame[0] + frame[2] / 2, frame[1] + 100))
    finally:
        app.quit()

Coordinates are screen pixels with a top-left origin; frames include the window
manager's decorations.

Input is real compositor input (org.gnome.Mutter.RemoteDesktop), so it focuses and
raises windows like a hand on the mouse; windows are *seen* through X11, which only
shows X11 clients, so apps under test are launched with GDK_BACKEND=x11 unless asked
otherwise. See xinput.py — and do not reach for XTEST, which the note there explains.
"""

import os
import subprocess
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
SKILLS = os.path.normpath(os.path.join(HERE, '..', '..', '..'))
# uiprobe.py: in its own skill here; next to this file on a remote host (flat kit).
sys.path[:0] = [HERE, os.path.join(SKILLS, 'flutter-ui-probe', 'scripts')]

from xinput import (BTN_LEFT, BTN_MIDDLE, BTN_RIGHT, RemoteDesktop, X11,  # noqa: E402
                    idle_ms, session_type)

try:
    from uiprobe import App as Probe  # noqa: E402
except ImportError:  # only Flutter apps need it
    Probe = None


class Abort(Exception):
    """The script must not go on: wrong window under the cursor, machine in use, …"""


def pause(seconds):
    time.sleep(seconds)


def assert_idle(ms=1500):
    """Raises Abort when someone used the machine in the last `ms` milliseconds."""
    idle = idle_ms()
    if idle is None:
        raise Abort('no GNOME idle monitor: cannot tell whether someone is using this machine')
    if idle < ms:
        raise Abort(f'input {idle} ms ago; someone is using this machine')


def flutter_executable(project_dir, name=None, mode='debug'):
    """The executable inside a Flutter project's built Linux bundle."""
    project_dir = os.path.abspath(project_dir)
    name = name or os.path.basename(project_dir)
    return os.path.join(project_dir, 'build', 'linux', 'x64', mode, 'bundle', name)


def build_flutter(project_dir):
    subprocess.run(['flutter', 'build', 'linux', '--debug'], check=True, cwd=project_dir)


# blur()'s focus holder: a window with nothing in it, parked where it covers nothing.
HOLDER = """
import sys
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk
window = Gtk.Window(title='gui-test focus holder')
window.set_default_size(140, 100)
window.move(int(sys.argv[1]), int(sys.argv[2]))
window.show_all()
Gtk.main()
"""


def ease(t):
    """Smooth start and end, like a hand moving the mouse."""
    return t * t * (3 - 2 * t)


class GuiApp:
    def __init__(self, executable, args=(), backend='x11'):
        self.executable = executable
        self.args = list(args)
        self.backend = backend  # GDK_BACKEND for the app; None leaves the session default
        self.name = os.path.basename(executable)
        self.proc = None
        self.log_path = None
        self.probe = None
        self.keep_open = False
        self.holder = None        # blur(): a window of ours to take the focus
        self.x = X11()            # looking: windows, geometry, stacking
        self.input = RemoteDesktop()  # acting: real pointer input

    # -- lifecycle ------------------------------------------------------------

    def launch(self, min_windows=1, flutter=True, timeout=30):
        if not os.path.exists(self.executable):
            raise SystemExit(f'{self.executable} is missing; build it first')
        log = tempfile.NamedTemporaryFile('w', suffix=f'.{self.name}.log', delete=False)
        self.log_path = log.name
        env = dict(os.environ)
        if self.backend:
            env['GDK_BACKEND'] = self.backend
        self.proc = subprocess.Popen([self.executable, *self.args], stdout=log,
                                     stderr=subprocess.STDOUT, env=env)
        if flutter:
            if Probe is None:
                raise Abort('uiprobe.py is not next to this harness; cannot probe a Flutter app')
            self.probe = Probe(self.log_path)
        deadline = time.time() + timeout
        while time.time() < deadline:
            if self.proc.poll() is not None:
                raise Abort(f'{self.name} exited early; see {self.log_path}\n{self.output()}')
            if (not flutter or self.probe.vm_url()) and len(self.windows()) >= min_windows:
                break
            time.sleep(0.3)
        else:
            self.quit()
            raise Abort(f'{self.name} did not come up; see {self.log_path}\n{self.output()}')
        pause(1.5)  # first frames
        self.activate()

    def quit(self):
        self.input.stop()
        if self.holder is not None and self.holder.poll() is None:
            self.holder.terminate()
        if self.keep_open or not self.proc or self.proc.poll() is not None:
            return
        self.proc.terminate()
        try:
            self.proc.wait(5)
        except subprocess.TimeoutExpired:
            self.proc.kill()

    def activate(self):
        """Raise and focus the app's first window."""
        windows = self._windows()
        if windows:
            self.x.activate(windows[0].xid)
            pause(0.5)

    def blur(self):
        """Take the focus away, so the next press on this app is a focus change.

        Clicks a small window of this harness parked in a screen corner. Asking the
        window manager to focus something else (_NET_ACTIVE_WINDOW) or dropping the
        focus with XSetInputFocus is not enough on GNOME — a real click is what the
        compositor acts on, and it needs a window of ours to land on.
        """
        window = self._focus_holder()
        point = (window.frame[0] + window.frame[2] / 2, window.frame[1] + window.frame[3] / 2)
        self.move(point, 400)
        at = self.x.window_at(*point)
        if at is None or at.pid != self.holder.pid:
            raise Abort(f'the focus holder is not at {point}: {at!r}')
        self.input.button(BTN_LEFT, True)
        time.sleep(0.06)
        self.input.button(BTN_LEFT, False)
        pause(0.6)
        focused = self.x.atom('_NET_WM_STATE_FOCUSED')
        if any(focused in self.x.cardinals(w.xid, '_NET_WM_STATE') for w in self._windows()):
            raise Abort('could not take the focus away from the app')

    def _focus_holder(self, timeout=10):
        """A small window of this harness, in the bottom right corner, used by blur()."""
        if self.holder is None or self.holder.poll() is not None:
            width, height = self.x.screen_size()
            self.holder = subprocess.Popen(
                [sys.executable, '-c', HOLDER, str(width - 160), str(height - 140)],
                env=dict(os.environ, GDK_BACKEND='x11'),
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        deadline = time.time() + timeout
        while time.time() < deadline:
            window = next((w for w in self.x.windows() if w.pid == self.holder.pid), None)
            if window is not None:
                return window
            time.sleep(0.2)
        raise Abort('the focus holder window did not come up')

    def output(self):
        """Everything the app has printed so far."""
        with open(self.log_path) as f:
            return f.read()

    # -- looking --------------------------------------------------------------

    def _windows(self):
        return self.x.windows(pid=self.proc.pid)

    def windows(self):
        """[(title, (x, y, w, h))] — frames include the decorations."""
        return [(w.title, w.frame) for w in self._windows()]

    def contents(self):
        """[(title, (x, y, w, h))] — the client areas, without the decorations."""
        return [(w.title, w.content) for w in self._windows()]

    def window(self, title):
        for t, frame in self.windows():
            if t == title:
                return frame
        raise LookupError(f'no window titled {title!r}: {[t for t, _ in self.windows()]}')

    def title_bar_height(self, title=None):
        """How tall this window manager's title bar is on the app's windows."""
        windows = self._windows()
        if title is not None:
            windows = [w for w in windows if w.title == title]
        if not windows:
            return 0
        w = windows[0]
        return w.content[1] - w.frame[1]

    def is_focused(self, title):
        """Does the window manager consider this window of the app focused?"""
        focused = self.x.atom('_NET_WM_STATE_FOCUSED')
        return any(focused in self.x.cardinals(w.xid, '_NET_WM_STATE')
                   for w in self._windows() if w.title == title)

    def views(self):
        """flutter-ui-probe views of a debug Flutter app."""
        return self.probe.views()

    def to_screen(self, title, point):
        """A point in a window's Flutter view to the screen.

        The view fills the client area, which X11 reports in screen pixels; a scale
        other than 1 would have to be applied by the caller (GNOME's fractional scaling
        is per monitor, and Flutter reports its own logical pixels).
        """
        content = next((c for t, c in self.contents() if t == title), None)
        if content is None:
            raise LookupError(f'no window titled {title!r}: {[t for t, _ in self.windows()]}')
        return content[0] + point[0], content[1] + point[1]

    # -- acting, guarded ------------------------------------------------------

    def _check(self, x, y):
        """The point must be on one of the app's own windows, right now.

        Two conditions, because X11 alone cannot see a Wayland window lying on top:
        the X server must agree the pointer is at this very point — it only knows that
        while the pointer is over an X surface — and the X window there must be ours.
        """
        if x is None or y is None:
            raise Abort(f'refusing to press at ({x}, {y})')
        px, py, _ = self.x.pointer()
        if abs(px - x) > 1 or abs(py - y) > 1:
            raise Abort(f'the X server has the pointer at ({px}, {py}), not at '
                        f'({x:.0f}, {y:.0f}): something else is under the cursor; stopping')
        window = self.x.window_at(x, y)
        if window is None or window.pid != self.proc.pid:
            raise Abort(f'({x:.0f}, {y:.0f}) belongs to {window!r}, not {self.name}; stopping')

    def move(self, point, ms=600):
        """Glides the pointer to a point, eased, ~120 Hz."""
        x1, y1 = float(point[0]), float(point[1])
        if self.input.position is None:  # nothing to glide from yet
            self.input.motion(x1, y1)
            time.sleep(0.1)
            return
        x0, y0 = self.input.position
        steps = max(2, int(ms / 8))
        for i in range(1, steps + 1):
            t = ease(i / steps)
            self.input.motion(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t)
            time.sleep(ms / 1000 / steps)
        self.input.motion(x1, y1)

    def click(self, point, ms=450, button=BTN_LEFT):
        self.move(point, ms)
        self._check(*point)
        self.input.button(button, True)
        time.sleep(0.06)
        self.input.button(button, False)

    def right_click(self, point, ms=450):
        self.click(point, ms, button=BTN_RIGHT)

    def middle_click(self, point, ms=450):
        self.click(point, ms, button=BTN_MIDDLE)

    def double_click(self, point, ms=450):
        self.move(point, ms)
        self._check(*point)
        for _ in range(2):
            self.input.button(BTN_LEFT, True)
            time.sleep(0.04)
            self.input.button(BTN_LEFT, False)
            time.sleep(0.06)

    def drag(self, start, *legs, approach_ms=500, hold_ms=250, hold_until=None,
             hold_timeout=5, button=BTN_LEFT):
        """legs: (x, y, ms) tuples, glided through with the button held.

        `hold_ms` is the pause between the press and the first move. Apps that react to
        the press through the window manager — a focus change, say — see it that late,
        and on GNOME that is a few hundred milliseconds after the button went down, with
        no upper bound worth guessing: pass `hold_until` (a predicate polled with the
        button held, for instance `lambda: app.is_focused(title)`) and the drag waits for
        the app to have noticed the press instead.
        """
        for leg in legs:
            if len(leg) != 3 or any(v is None for v in leg):
                raise Abort(f'bad drag leg {leg!r}')
        self.move(start, approach_ms)
        self._check(*start)
        self.input.button(button, True)
        try:
            time.sleep(hold_ms / 1000)
            if hold_until is not None:
                deadline = time.time() + hold_timeout
                while not hold_until() and time.time() < deadline:
                    time.sleep(0.05)
            for x, y, ms in legs:
                self.move((x, y), ms)
                time.sleep(0.05)
        finally:
            self.input.button(button, False)
            time.sleep(0.05)

    def scroll(self, point, lines):
        self.move(point, 400)
        self._check(*point)
        self.input.wheel(lines)


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
