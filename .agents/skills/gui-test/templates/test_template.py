#!/usr/bin/env python3
"""GUI test template (macOS). Copy it next to the project's other GUI tests, fill in the
TODOs, and keep the shape: idle check, launch, look, act, settle, look again, assert, quit.
"""

import os
import sys

SKILLS = 'TODO: path to .agents/skills'
sys.path.insert(0, os.path.join(SKILLS, 'gui-test', 'scripts', 'macos'))
from guiapp import Abort, Checks, GuiApp, assert_idle, flutter_executable, pause  # noqa: E402


def main():
    assert_idle()  # never fight a person for the mouse
    # A Flutter project's debug build, or any executable: GuiApp('/path/to/app', args=[...]).
    app = GuiApp(flutter_executable('TODO: path/to/flutter_project'))
    checks = Checks()
    app.launch(min_windows=1)  # flutter=False for apps without a Dart VM service
    try:
        # Look: OS window frames + probed views. Identify a view by a text only it shows.
        frame = app.window('TODO: window title')
        view = next(v for v in app.views() if v.has('TODO: a text in that window'))

        # Act: one owner-checked gesture. Drag in two legs: a short one to pass the drag
        # threshold, then the long one.
        start = app.to_screen(frame, view, view.center('TODO: text to grab'))
        drop = (start[0] + 300, start[1] + 200)
        app.drag(start, (start[0] + 60, start[1] + 40, 350), (*drop, 900))
        pause(1.5)  # windows are created, destroyed and laid out asynchronously

        # Look again (never reuse coordinates from before the gesture), then assert numbers.
        titles = [t for t, _ in app.windows()]
        checks.check('TODO: what should be true now', 'TODO' in titles, titles)
        texts = [t for v in app.views() for t, _ in v.texts]
        checks.check('TODO: state survived', any(t == 'TODO' for t in texts))
    except Abort as e:
        checks.check('ran to the end', False, e)
    finally:
        app.quit()
    print(f'{checks.failures} failure(s); app log: {app.log_path}')
    return 1 if checks.failures else 0


if __name__ == '__main__':
    sys.exit(main())
