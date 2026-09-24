# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from application.h."""

from __future__ import annotations

import enum
from collections.abc import Callable
from dataclasses import dataclass

from . import _capi as _C
from . import _runtime as _rt
from . import menu as _menu
from . import window as _window


class Brightness(enum.IntEnum):
    SYSTEM = 0
    LIGHT = 1
    DARK = 2


@dataclass(frozen=True)
class ApplicationEvent:
    """Base of every ApplicationEvent; listeners receive one of its subclasses."""

    @staticmethod
    def _from_c(raw: _C.native_application_event_t) -> ApplicationEvent | None:
        if raw.type == 0:
            return ApplicationStartedEvent()
        if raw.type == 1:
            return ApplicationExitingEvent(raw.data.exiting.exit_code)
        if raw.type == 2:
            return ApplicationActivatedEvent()
        if raw.type == 3:
            return ApplicationDeactivatedEvent()
        if raw.type == 4:
            return ApplicationQuitRequestedEvent()
        return None


@dataclass(frozen=True)
class ApplicationStartedEvent(ApplicationEvent):
    pass


@dataclass(frozen=True)
class ApplicationExitingEvent(ApplicationEvent):
    exit_code: int


@dataclass(frozen=True)
class ApplicationActivatedEvent(ApplicationEvent):
    pass


@dataclass(frozen=True)
class ApplicationDeactivatedEvent(ApplicationEvent):
    pass


@dataclass(frozen=True)
class ApplicationQuitRequestedEvent(ApplicationEvent):
    pass


class Application:
    """The process-wide Application; every member is static."""

    def __init__(self) -> None:
        raise TypeError("Application is a singleton; call its static methods")

    @staticmethod
    def run(window: _window.Window | None = None) -> int:
        """Runs the platform event loop until `quit()`; returns the exit code.

        Blocks the calling thread, which must be the main thread. With `window`,
        it is shown and made the primary window. See `run_async()` to keep an
        asyncio loop running alongside.
        """
        return _rt.run_event_loop(window)

    @staticmethod
    async def run_async(window: _window.Window | None = None) -> int:
        """Pumps the platform event loop from the running asyncio loop until
        `quit()`; resolves with the exit code.

        Tasks, timers and I/O keep running while windows are up. Must be awaited
        on the main thread.
        """
        return await _rt.run_event_loop_async(window)

    @staticmethod
    def quit(exit_code: int = 0) -> None:
        """Stops the loop started by `run()` or `run_async()`, which then
        returns `exit_code`."""
        _rt.quit_event_loop(exit_code)

    @staticmethod
    def is_running() -> bool:
        raw = _C.native_application_is_running()
        return raw

    @staticmethod
    def is_single_instance() -> bool:
        raw = _C.native_application_is_single_instance()
        return raw

    @staticmethod
    def set_icon(icon_path: str) -> bool:
        raw = _C.native_application_set_icon(_rt.encode(icon_path))
        return raw

    @staticmethod
    def set_dock_icon_visible(visible: bool) -> bool:
        raw = _C.native_application_set_dock_icon_visible(visible)
        return raw

    @staticmethod
    def set_progress_bar(progress: float) -> bool:
        raw = _C.native_application_set_progress_bar(progress)
        return raw

    @staticmethod
    def set_badge_label(label: str) -> bool:
        raw = _C.native_application_set_badge_label(_rt.encode(label))
        return raw

    @staticmethod
    def set_brightness(brightness: Brightness) -> bool:
        raw = _C.native_application_set_brightness(int(brightness))
        return raw

    @staticmethod
    def set_menu_bar(menu: _menu.Menu | None) -> bool:
        raw = _C.native_application_set_menu_bar(_rt.handle_of(menu))
        return raw

    @staticmethod
    def get_primary_window() -> _window.Window | None:
        raw = _C.native_application_get_primary_window()
        return _window.Window._owned(raw)

    @staticmethod
    def set_primary_window(window: _window.Window | None) -> None:
        _C.native_application_set_primary_window(_rt.handle_of(window))

    @staticmethod
    def get_all_windows() -> list[_window.Window]:
        raw = _C.native_application_get_all_windows()
        return _rt.take_handles(
            raw,
            raw.windows,
            _window.Window,
            _C.native_window_list_release,
        )

    @staticmethod
    def add_listener(callback: Callable[[ApplicationEvent], None]) -> int:
        """Calls `callback` with every ApplicationEvent this Application emits.

        Returns the listener id for `remove_listener()`.
        """

        def trampoline(raw, _user_data):
            event = ApplicationEvent._from_c(raw.contents)
            if event is not None:
                callback(event)

        return _rt.add_listener(
            _C.native_application_add_listener,
            _C.native_application_event_callback_t,
            trampoline,
        )

    @staticmethod
    def remove_listener(listener_id: int) -> bool:
        """Unregisters a listener. Returns False if unknown."""
        return _rt.remove_listener(_C.native_application_remove_listener, listener_id)
