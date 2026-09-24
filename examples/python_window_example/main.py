"""Window example: opens a window, reacts to its events, and runs the
platform event loop alongside ordinary asyncio tasks until the window is
closed.

Usage (from this directory):
    uv run main.py
"""

import asyncio
import sys

from nativeapi import (
    Application,
    ApplicationEvent,
    DisplayManager,
    Size,
    TitleBarStyle,
    Window,
    WindowClosedEvent,
    WindowEvent,
    WindowManager,
    WindowMovedEvent,
    WindowResizedEvent,
)


async def main() -> int:
    window = Window()
    print(f"Created window #{window.id}")

    # --- Title and geometry ---
    window.set_title("Python Window Example")
    window.set_size(Size(800, 600), False)
    window.set_minimum_size(Size(400, 300))
    window.set_title_bar_style(TitleBarStyle.NORMAL)
    window.center()
    print("Title:", window.title)
    print("Bounds:", window.bounds)

    primary = DisplayManager.get_primary()
    print("Primary display:", primary.name if primary else None)

    # --- Events ---
    # One listener receives every window event, as a dataclass per kind.
    def on_window_event(event: WindowEvent) -> None:
        match event:
            case WindowMovedEvent(window_id=id, new_position=position):
                print(f"[event] window {id} moved to {position}")
            case WindowResizedEvent(window_id=id, new_size=size):
                print(f"[event] window {id} resized to {size}")
            case WindowClosedEvent(window_id=id):
                print(f"[event] window {id} closed")
                if id == window.id:
                    Application.quit(0)
            case _:
                print(f"[event] window {event.window_id} {type(event).__name__}")

    def on_app_event(event: ApplicationEvent) -> None:
        print("[app]", type(event).__name__)

    WindowManager.add_listener(on_window_event)
    Application.add_listener(on_app_event)

    # --- Run ---
    # The platform loop is pumped from asyncio, so this task keeps running.
    async def tick() -> None:
        seconds = 0
        while True:
            await asyncio.sleep(1)
            seconds += 1
            window.set_title(f"Python Window Example — {seconds}s")

    ticker = asyncio.create_task(tick())
    exit_code = await Application.run_async(window)
    ticker.cancel()
    print(f"Event loop finished with exit code {exit_code}")
    return exit_code


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
