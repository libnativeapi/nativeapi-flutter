#!/usr/bin/env python3
"""Check (Linux, GNOME on Wayland) of floating_toolbar_example, from the inside only.

Flutter's multi-window does not run under Xwayland on this kind of host (see the
remote-hosts skill, references/linux.md), so the example runs as a Wayland client — and a
Wayland window can neither be measured nor pressed from outside. What is left to check:
the app comes up with both windows rendering, Window.setParentWindow succeeded and
reached the compositor (read from the Wayland protocol trace), the two views show what
they should at the size they were given, and the app keeps running. Geometry (does the toolbar sit
above the main window?) is NOT checked: on Wayland a client cannot even position its
windows. The macOS twin, flutter_floating_toolbar_test.py, covers the behaviour.

    .agents/skills/remote-hosts/scripts/remote.sh linux desktop \
        tools/gui/flutter_floating_toolbar_test_linux.py 120

The example is expected built in debug under $TOOLBAR_EXAMPLE_DIR, or in the host's
checkout ($REMOTE_WORKSPACE). No input is sent.
"""

import os
import re
import subprocess
import sys
import tempfile
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # the flat kit on a remote host

from guiapp import Checks, flutter_executable  # noqa: E402
from uiprobe import App as Probe  # noqa: E402

NAME = 'floating_toolbar_example'


def example_dir():
    scratch = os.environ.get('REMOTE_SCRATCH', '')
    candidates = [
        os.environ.get('TOOLBAR_EXAMPLE_DIR', ''),
        os.path.join(scratch, 'toolbar-flutter', 'examples', NAME) if scratch else '',
        os.path.join(os.environ.get('REMOTE_WORKSPACE', ''), 'bindings', 'flutter', 'examples', NAME),
    ]
    for candidate in candidates:
        if candidate and os.path.isdir(os.path.join(candidate, 'build')):
            return candidate
    raise SystemExit(f'{NAME} is not built in any of {[c for c in candidates if c]}')


def main():
    checks = Checks()
    log = tempfile.NamedTemporaryFile('w', suffix=f'.{NAME}.log', delete=False)
    # WAYLAND_DEBUG: the protocol trace is the only way to see what the compositor was told
    env = dict(os.environ, GDK_BACKEND='wayland', WAYLAND_DEBUG='1')
    proc = subprocess.Popen([flutter_executable(example_dir())], stdout=log,
                            stderr=subprocess.STDOUT, env=env)
    probe = Probe(log.name)

    def output():
        with open(log.name) as f:
            return f.read()

    try:
        views = []
        deadline = time.time() + 40
        while time.time() < deadline and proc.poll() is None:
            if probe.vm_url():
                try:
                    views = probe.views()
                except Exception:  # the VM service answers before the first frame
                    views = []
                if len(views) >= 2:
                    break
            time.sleep(0.5)
        # The views exist before their first real frame (they report 1 x 1 until then)
        time.sleep(3)
        if proc.poll() is None:
            views = probe.views()
        checks.check('the app came up and is still running', proc.poll() is None,
                     output()[-600:] if proc.poll() is not None else '')
        checks.check('two Flutter views are rendering', len(views) >= 2, len(views))
        checks.check('the main window shows its content',
                     any(v.has('Stamps: 0') and v.has('Detach toolbar') for v in views))
        checks.check('the toolbar window shows its content',
                     any(v.has('Stamp') and not v.has('Stamps: 0') for v in views))
        checks.check('setParentWindow succeeded',
                     'Toolbar attached to the main window' in output()
                     and 'setParentWindow failed' not in output())
        print('view sizes:', [tuple(round(s) for s in v.size) for v in views])
        # GDK only announces a parent that is mapped already, and the toolbar is mapped
        # first: core announces it again once the main window is up.
        checks.check('the compositor was told the toolbar has a parent',
                     re.search(r'xdg_toplevel@\d+\.set_parent\(xdg_toplevel@\d+\)', output()) is not None)
        toolbar = next((v for v in views if v.has('Stamp') and not v.has('Stamps: 0')), None)
        if toolbar is not None:
            # It was 328 x 12 while core un-decorated the window instead of hiding its
            # header bar: GTK then takes its shadow margin out of the content.
            checks.check('the toolbar view has the size it was asked to have',
                         [round(s) for s in toolbar.size] == [380, 64], toolbar.size)
        time.sleep(5)
        checks.check('still running five seconds later', proc.poll() is None,
                     output()[-600:] if proc.poll() is not None else '')
    finally:
        if proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(5)
            except subprocess.TimeoutExpired:
                proc.kill()
    lines = [line for line in output().splitlines()
             if ('floating_toolbar' in line or 'rror' in line) and '@' not in line[:40]]
    print('app log:', *lines[:12], sep='\n  ')
    print(f'{checks.failures} failure(s)')
    return 1 if checks.failures else 0


if __name__ == '__main__':
    sys.exit(main())
