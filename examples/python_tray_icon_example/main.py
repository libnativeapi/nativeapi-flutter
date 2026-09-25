"""Tray icon example: a tray icon with a context menu (a checkbox, a radio
group, a submenu and Quit), a global shortcut, and an asyncio task updating
the tooltip, all running until Quit is chosen.

Usage (from this directory):
    uv run main.py
"""

import asyncio
import sys

from nativeapi import (
    Application,
    ContextMenuTrigger,
    Image,
    Menu,
    MenuEvent,
    MenuItem,
    MenuItemClickedEvent,
    MenuItemState,
    MenuItemType,
    ShortcutActivatedEvent,
    ShortcutManager,
    TrayIcon,
    TrayIconClickedEvent,
    TrayIconEvent,
    TrayManager,
)

# A 1x1 transparent PNG, so the example needs no asset on disk.
PIXEL_PNG = (
    "data:image/png;base64,"
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="
)
SHORTCUT = "CmdOrCtrl+Shift+Y"


def item(label: str, type: MenuItemType = MenuItemType.NORMAL) -> MenuItem:
    return MenuItem.with_label_and_type(label, type)


async def main() -> int:
    if not TrayManager.is_supported():
        print("System tray is not supported on this platform.")
        return 1

    # --- Tray icon ---
    tray = TrayIcon()
    tray.set_title("NativeAPI")
    tray.set_tooltip("Python tray icon example")
    icon = Image.from_base64(PIXEL_PNG)
    if icon is not None:
        tray.set_icon(icon)

    # --- Context menu ---
    # Keep a reference to every item: an item released on the Python side
    # still lives in the menu, but its listeners go with the wrapper's scope.
    menu = Menu()
    greet = item("Say Hello")
    menu.add_item(greet)
    menu.add_separator()

    notifications = item("Notifications", MenuItemType.CHECKBOX)
    notifications.set_state(MenuItemState.CHECKED)
    menu.add_item(notifications)

    themes = []
    for index, label in enumerate(["Light", "Dark", "Auto"]):
        theme = item(label, MenuItemType.RADIO)
        theme.set_radio_group(1)
        if index == 2:
            theme.set_state(MenuItemState.CHECKED)
        menu.add_item(theme)
        themes.append(theme)

    tools = Menu()
    clear_cache = item("Clear Cache")
    tools.add_item(clear_cache)
    tools_item = item("Tools", MenuItemType.SUBMENU)
    tools_item.set_submenu(tools)
    menu.add_item(tools_item)

    menu.add_separator()
    quit_item = item("Quit")
    menu.add_item(quit_item)

    tray.set_context_menu(menu)
    tray.set_context_menu_trigger(ContextMenuTrigger.CLICKED)
    tray.set_visible(True)
    print(f"Tray icon #{tray.get_id()} visible, menu with {menu.item_count} items")

    # --- Events ---
    # Items emit their own clicks; a radio item unchecks its siblings itself
    # on some platforms only, so the example keeps the group consistent.
    def on_item(event: MenuEvent) -> None:
        if not isinstance(event, MenuItemClickedEvent):
            return
        if event.item_id == greet.id:
            print("Hello from the tray!")
        elif event.item_id == notifications.id:
            checked = notifications.state == MenuItemState.CHECKED
            notifications.set_state(
                MenuItemState.UNCHECKED if checked else MenuItemState.CHECKED
            )
            print("Notifications", "off" if checked else "on")
        elif event.item_id == clear_cache.id:
            print("Cache cleared")
        elif event.item_id == quit_item.id:
            Application.quit(0)
        else:
            for theme in themes:
                selected = theme.id == event.item_id
                theme.set_state(
                    MenuItemState.CHECKED if selected else MenuItemState.UNCHECKED
                )
                if selected:
                    print("Theme:", theme.label)

    for menu_item in [greet, notifications, *themes, clear_cache, quit_item]:
        menu_item.add_listener(on_item)

    def on_tray(event: TrayIconEvent) -> None:
        if isinstance(event, TrayIconClickedEvent):
            print("[tray] clicked")

    tray.add_listener(on_tray)

    # --- Global shortcut ---
    if ShortcutManager.is_supported():
        ShortcutManager.register_with_accelerator_and_callback(
            SHORTCUT, lambda: print(f"[shortcut] {SHORTCUT}")
        )

        def on_shortcut(event: object) -> None:
            if isinstance(event, ShortcutActivatedEvent):
                tray.set_title(f"NativeAPI ({event.accelerator})")

        ShortcutManager.add_listener(on_shortcut)
        print(f"Press {SHORTCUT} anywhere")

    # --- Run ---
    async def count() -> None:
        seconds = 0
        while True:
            await asyncio.sleep(1)
            seconds += 1
            tray.set_tooltip(f"Running for {seconds}s")

    counter = asyncio.create_task(count())
    exit_code = await Application.run_async()
    counter.cancel()
    ShortcutManager.unregister_all()
    tray.set_visible(False)
    return exit_code


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
