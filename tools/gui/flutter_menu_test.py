#!/usr/bin/env python3
"""GUI test (macOS) of menu_example: the native context menu opens where it is asked to
(click point, placement, absolute position, cursor), shows the item types and states the
example set (checkbox, radio group, disabled, submenu, special characters), fires click
and open/close events for the right items only, and reflects changes made while closed
(label, added item, detached submenu).

    tools/gui/flutter_menu_test.py [--build] [--keep-open]

Built on the gui-test skill (.agents/skills). It takes over the mouse for ~90 s.
Open menus are read through Accessibility (`GuiApp.menu_items`); the Flutter UI is only
probed while no menu is open, because a tracking menu can stall the VM service.
"""

import sys

from common import build_example, example
from guiapp import Abort, Checks, assert_idle, pause

NAME = 'menu_example'
REGION = 'Right-click here'
HISTORY = 'Event History'  # header prefix: "Event History (n)"

# The context menu's items, top to bottom, separators left out (see _setupContextMenu).
ITEMS = [
    'Normal Menu Item', 'Checkbox Item', 'Radio Option 1', 'Radio Option 2',
    'Radio Option 3', 'Disabled Item', 'Disabled Checkbox', 'Dynamic Label Item',
    'Item with Tooltip', 'Submenu', 'Special: 中文 日本語 🎉 @#$%',
]
SUBITEMS = ['Submenu Item 1', 'Submenu Item 2', 'Submenu Item 3']
POSITIONING = ['Positioning Menu Item 1', 'Positioning Menu Item 2']

# The window is 800 x 600; the lower sections of the scrolling left column would be out of
# sight (and the probe does not apply scroll offsets), so the test enlarges it first.
FRAME = (60, 40, 1100, 1000)

# Placements are measured on the menu window. AppKit puts the first *item* at the requested
# point, so the window (with its padding) sits a few points higher.
PAD = 8


def items(app, depth=0):
    return [i for i in app.menu_items() if i.depth == depth and not i.separator]


def near(a, b):
    return all(abs(x - y) <= PAD for x, y in zip(a, b))


def check_top_end(app, checks, what, point):
    """Top End: the menu's bottom-right corner at the point — unless the menu is too tall
    for the room above it, where AppKit keeps it below the menu bar instead."""
    mx, my, mw, mh = app.menu_frames()[0]
    detail = f'menu {(mx, my, mw, mh)}, click at {point}'
    top = app.visible_frame(point)[1]
    if point[1] - mh >= top:
        checks.check(what, near((mx + mw, my + mh), point), detail)
    else:
        checks.check(f'{what} (too tall for the room above: kept below the menu bar)',
                     near((mx + mw, my), (point[0], top)), f'{detail}, visible top {top}')


def main():
    if '--build' in sys.argv:
        build_example(NAME)
    assert_idle()
    app = example(NAME, args=['-ApplePersistenceIgnoreState', 'YES'])
    app.keep_open = '--keep-open' in sys.argv
    checks = Checks()
    app.launch(min_windows=1)
    try:
        app.set_frame(*FRAME)
        title = app.windows()[0][0]

        def look():
            """(frame, view) as they are now; never probe while a menu is open."""
            if app.menu_items():
                raise Abort('a menu is still open; refusing to probe')
            return app.window(title), next(v for v in app.views() if v.has(REGION))

        def texts():
            return [t for t, _ in look()[1].texts]

        def history():
            """Event history entries without their "[hh:mm:ss] " prefix, newest first."""
            return [t[11:] for t in texts() if t.startswith('[') and t[9:11] == '] ']

        def info(label):
            """The value shown under an info row label (Items / Checkbox / Radio)."""
            frame, view = look()
            lx, ly, lw, lh = view.find(label)
            below = [(r[1], t) for t, r in view.texts
                     if abs(r[0] - lx) < 2 and ly + lh - 1 <= r[1] < ly + lh + 30]
            return min(below)[1] if below else None

        def button(label):
            frame, view = look()
            x, y = app.to_screen(frame, view, view.center(label))
            if not (frame[1] < y < frame[1] + frame[3] - 10):
                raise Abort(f'button {label!r} is out of sight at y={y:.0f}')
            x, y = round(x), round(y)
            app.click((x, y))
            pause(0.8)
            return x, y

        def open_context_menu():
            frame, view = look()
            point = app.to_screen(frame, view, view.center(REGION))
            point = tuple(map(round, point))  # menu frames are whole points
            app.right_click(point)
            if not app.wait_menu():
                raise Abort('the context menu did not open')
            pause(0.4)
            return point

        def dismiss():
            """Closes the open menus with a click on the app's own window, clear of every
            menu (a press on a menu would pick an item)."""
            menus = list(app.menu_frames().values())
            frame = app.window(title)
            # The title bar, and the empty right end of the history column's header.
            for point in [(frame[0] + frame[2] / 2, frame[1] + 12),
                          (frame[0] + frame[2] - 40, frame[1] + header_y),
                          (frame[0] + 90, frame[1] + 12)]:
                if not any(x - 20 <= point[0] <= x + w + 20 and y - 20 <= point[1] <= y + h + 20
                           for x, y, w, h in menus):
                    break
            else:
                raise Abort(f'no free spot outside the menus {menus} to dismiss them')
            app.click(point)
            closed = app.wait_menu(is_open=False)
            pause(0.6)
            return closed

        def pick(label, depth=0):
            app.click_menu_item(label, depth)
            closed = app.wait_menu(is_open=False)
            pause(0.8)
            return closed

        frame, view = look()
        header_y = frame[3] - view.size[1] + view.center(HISTORY, prefix=True)[1]

        # 1. Right click opens the menu at the click point (placement Bottom Start).
        point = open_context_menu()
        menu = items(app)
        checks.check('context menu shows the example items in order',
                     [i.title for i in menu] == ITEMS, [i.title for i in menu])
        mx, my, mw, mh = app.menu_frames()[0]
        checks.check('menu top-left is at the click point (Bottom Start)', near((mx, my), point),
                     f'menu {(mx, my, mw, mh)}, click at {point}')
        by_title = {i.title: i for i in menu}
        checks.check('checkbox starts unchecked', not by_title['Checkbox Item'].checked)
        checks.check('radio group starts on option 1',
                     [by_title[f'Radio Option {n}'].checked for n in (1, 2, 3)]
                     == [True, False, False])
        checks.check('disabled items are disabled, the rest enabled',
                     [i.title for i in menu if not i.enabled]
                     == ['Disabled Item', 'Disabled Checkbox'])
        checks.check('disabled checkbox keeps its checked state',
                     by_title['Disabled Checkbox'].checked)
        checks.check('only "Submenu" has a submenu',
                     [i.title for i in menu if i.has_submenu] == ['Submenu'])
        checks.check('separators are where the example put them',
                     sum(i.separator for i in app.menu_items() if i.depth == 0) == 4)

        # 2. Clicking an item fires its event and closes the menu.
        checks.check('menu closes after a click', pick('Normal Menu Item'))
        h = history()
        checks.check('item click event', any(e.startswith('Normal item clicked') for e in h), h[:4])
        checks.check('menu opened and closed events',
                     any(e.startswith('Menu opened') for e in h)
                     and any(e.startswith('Menu closed') for e in h), h[:4])

        # 3. Checkbox: the app flips the state; the menu shows it the next time.
        open_context_menu()
        pick('Checkbox Item')
        checks.check('checkbox click reaches the app', info('Checkbox') == 'true', info('Checkbox'))
        open_context_menu()
        checks.check('checkbox shows checked on reopen', app.menu_item('Checkbox Item').checked)
        pick('Checkbox Item')
        checks.check('second click unchecks it', info('Checkbox') == 'false', info('Checkbox'))

        # 4. Radio group: exactly one option checked.
        open_context_menu()
        pick('Radio Option 3')
        checks.check('radio selection reaches the app', info('Radio') == 'Option 3', info('Radio'))
        open_context_menu()
        marks = [app.menu_item(f'Radio Option {n}').checked for n in (1, 2, 3)]
        checks.check('only option 3 is checked on reopen', marks == [False, False, True], marks)
        pick('Radio Option 1')
        checks.check('back to option 1', info('Radio') == 'Option 1', info('Radio'))

        # 5. A disabled item does nothing.
        open_context_menu()
        app.click_menu_item('Disabled Item')
        pause(0.8)
        still_open = bool(app.menu_items())
        checks.check('clicking a disabled item leaves the menu open', still_open)
        if still_open:
            checks.check('dismissed by a click outside', dismiss())
        h = history()
        checks.check('disabled item fires no click', not any('should not fire' in e for e in h), h[:4])

        # 6. Dismissing without picking fires close but no click.
        clicks = sum('clicked' in e for e in history())
        open_context_menu()
        checks.check('click outside closes the menu', dismiss())
        h = history()
        checks.check('dismiss fires "Menu closed"', h and h[0].startswith('Menu closed'), h[:3])
        checks.check('dismiss fires no item click', sum('clicked' in e for e in h) == clicks)

        # 7. Submenu: hovering opens it beside its item; its items fire their own events.
        open_context_menu()
        parent = app.hover_menu_item('Submenu', depth=0)
        opened = app.wait_menu(depth=1)
        checks.check('hovering "Submenu" opens it', opened)
        if opened:
            pause(0.4)
            sub = items(app, 1)
            checks.check('submenu items', [i.title for i in sub] == SUBITEMS, [i.title for i in sub])
            px, py, pw, ph = parent.frame
            checks.check('submenu opens to the right of its item, level with it',
                         sub[0].frame[0] >= px + pw - PAD and abs(sub[0].frame[1] - py) <= PAD,
                         f'parent {parent.frame}, first subitem {sub[0].frame}')
            # Slide right along the parent's row first, so the submenu stays open.
            app.move((sub[0].center[0], parent.center[1]), 350)
            checks.check('submenu item click closes all menus', pick('Submenu Item 2', depth=1))
            h = history()
            checks.check('submenu item click event',
                         any(e.startswith('Submenu Item 2 clicked') for e in h), h[:5])
            checks.check('submenu opened/closed events',
                         any(e.startswith('Submenu opened') for e in h)
                         and any(e.startswith('Submenu closed') for e in h), h[:5])
            checks.check('the parent menu item fires no click',
                         not any(e.startswith('Normal item') for e in h[:5]), h[:5])
        else:
            dismiss()

        # 8. Placement: Top End puts the menu's bottom-right corner at the click point.
        frame, view = look()
        dropdown = view.find('Bottom Start')
        app.click(app.to_screen(frame, view, view.center('Bottom Start')))
        pause(1.0)
        frame, view = look()
        choices = [r for t, r in view.texts if t == 'Top End' and abs(r[1] - dropdown[1]) > 4]
        if not choices:
            raise Abort(f'the placement list did not open: {[t for t, _ in view.texts][:40]}')
        x, y, w, h = choices[0]
        app.click(app.to_screen(frame, view, (x + w / 2, y + h / 2)))
        pause(1.0)
        checks.check('placement changed', any(e.startswith('Placement changed to: topEnd')
                                              for e in history()), history()[:2])
        point = open_context_menu()
        check_top_end(app, checks, 'menu bottom-right is at the click point (Top End)', point)
        dismiss()

        # 9. Changes made while the menu is closed show up on the next open (placement is
        #    still Top End, so this also checks that it uses the menu's new size).
        button('Update Label')
        new_label = next((e.split(': ', 1)[1] for e in history()
                          if e.startswith('Menu item label changed to')), None)
        button('Add Item')
        count = info('Items')
        button('Detach Submenu')
        point = open_context_menu()
        titles = [i.title for i in items(app)]
        check_top_end(app, checks, 'Top End uses the changed menu size', point)
        checks.check('updated label is shown', new_label in titles and 'Dynamic Label Item' not in titles,
                     f'{new_label!r} in {titles}')
        checks.check('added item is appended', titles[-1].startswith('New Item'), titles[-1:])
        checks.check('item count matches the menu', count == str(len(app.menu_items())),
                     f'app says {count}, menu has {len(app.menu_items())} entries')
        checks.check('detached submenu leaves a plain item',
                     not app.menu_item('Submenu').has_submenu)
        pick(titles[-1])
        h = history()
        checks.check('added item fires its click', any(e.startswith('New item') for e in h), h[:3])
        button('Detach Submenu')  # attach it again
        open_context_menu()
        checks.check('re-attached submenu is back', app.menu_item('Submenu').has_submenu)
        app.hover_menu_item('Submenu', depth=0)
        sub = [i.title for i in items(app, 1)] if app.wait_menu(depth=1) else []
        checks.check('re-attached submenu still shows its items', sub == SUBITEMS, sub)
        dismiss()

        # 10. Absolute position and cursor position (the positioning menu).
        button('Pos (300,200)')
        if app.wait_menu():
            pause(0.4)
            menu = items(app)
            checks.check('positioning menu items', [i.title for i in menu] == POSITIONING,
                         [i.title for i in menu])
            frame = app.menu_frames()[0]
            checks.check('absolute position (300, 200)', near(frame, (300, 200)), f'menu {frame}')
            pick('Positioning Menu Item 2')
            h = history()
            checks.check('positioning item click',
                         any(e == 'Positioning menu item 2 clicked' for e in h), h[:3])
        else:
            checks.check('positioning menu opens at (300, 200)', False)

        point = button('At Cursor')
        if app.wait_menu():
            pause(0.4)
            mx, my, mw, mh = app.menu_frames()[0]
            # The button sits low in the window; AppKit lifts a menu that would cross the
            # bottom of the visible screen, so only the cursor row has to be inside it.
            checks.check('menu opens at the cursor (lifted to fit the screen)',
                         abs(mx - point[0]) <= PAD and my <= point[1] <= my + mh,
                         f'menu {(mx, my, mw, mh)}, cursor at {point}')
            dismiss()
            checks.check('positioning menu closed event',
                         any(e == 'Positioning menu closed' for e in history()[:3]), history()[:3])
        else:
            checks.check('menu opens at the cursor', False,
                         f'clicked at {point}; history {history()[:4]}')
    except Abort as e:
        checks.check('ran to the end', False, e)
    finally:
        app.quit()
    print(f'{checks.failures} failure(s); app log: {app.log_path}')
    return 1 if checks.failures else 0


if __name__ == '__main__':
    sys.exit(main())
