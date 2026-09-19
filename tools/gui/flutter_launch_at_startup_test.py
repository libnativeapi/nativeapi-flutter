#!/usr/bin/env python3
"""GUI test (macOS) of the launch_at_startup example: the 0.5.x compatible API on top of
nativeapi really registers and removes a login item.

    tools/gui/flutter_launch_at_startup_test.py [--build] [--keep-open]

macOS registers the running app through `SMAppService`, so `isEnabled` is the status the
service reports — no plist of ours to read back. The test clicks Enable, reads the state
back, clicks Disable, and reads it back again. It always leaves the login item off: a
failure after Enable still runs the Disable in `finally`.

Built on the gui-test skill (.agents/skills). It takes over the mouse for ~15 s.
"""

import os
import sys

from common import WORKSPACE
from guiapp import Checks, GuiApp, assert_idle, build_flutter, flutter_executable, pause

PROJECT = os.path.join(WORKSPACE, 'bindings', 'flutter', 'packages',
                       'launch_at_startup', 'example')
NAME = 'launch_at_startup_example'


def main():
    if '--build' in sys.argv:
        build_flutter(PROJECT)
    assert_idle()
    app = GuiApp(flutter_executable(PROJECT, name=NAME),
                 args=['-ApplePersistenceIgnoreState', 'YES'])
    app.keep_open = '--keep-open' in sys.argv
    checks = Checks()
    app.launch(min_windows=1)
    try:
        title = app.windows()[0][0]

        def look():
            return app.window(title), next(v for v in app.views() if v.has('Enable'))

        def texts():
            return [t for t, _ in look()[1].texts]

        def state():
            """The strip says whether the app is registered; the footer says what the
            last call answered."""
            enabled = 'Launches at startup' in texts()
            last = next((t for t in texts() if '() →' in t or '() threw' in t), '')
            return enabled, last

        def press(label, settle=1.0):
            frame, view = look()
            x, y = app.to_screen(frame, view, view.center(label))
            app.click((round(x), round(y)))
            pause(settle)

        checks.check('supported on this macOS', 'not supported here' not in texts(),
                     'SMAppService needs macOS 13+')
        checks.check('starts not registered', not state()[0], state()[1])

        press('Enable')
        enabled, last = state()
        checks.check('Enable registers the login item', enabled, last)
        checks.check('enable() answered true', 'enable() → true' in last, last)

        press('Read back')
        enabled, last = state()
        checks.check('isEnabled reads back true', enabled and 'isEnabled() → true' in last,
                     last)

        press('Disable')
        enabled, last = state()
        checks.check('Disable removes the login item', not enabled, last)
        checks.check('disable() answered true', 'disable() → true' in last, last)

        # The arguments chips call setup() again; macOS ignores them, but the call must
        # not throw and must not leave the entry behind.
        press('--minimized', settle=0.5)
        press('Read back')
        enabled, last = state()
        checks.check('still off after setup(args:)', not enabled, last)
        checks.check('setup with args does not throw', 'threw' not in last, last)
    finally:
        try:
            if state()[0]:
                press('Disable')
                print(f'cleanup: {state()[1]}', flush=True)
        except Exception as error:  # noqa: BLE001 - cleanup must not mask the failure
            print(f'cleanup failed, check System Settings: {error}', flush=True)
        app.quit()
        print(f'app log: {app.log_path}', flush=True)
    print(f'\n{checks.failures} failure(s)')
    return 1 if checks.failures else 0


if __name__ == '__main__':
    sys.exit(main())
