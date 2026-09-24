# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from display_manager.h."""

from __future__ import annotations

from collections.abc import Callable

from . import _capi as _C
from . import _runtime as _rt
from . import display as _display
from . import geometry as _geometry


class DisplayManager:
    """The process-wide DisplayManager; every member is static."""

    def __init__(self) -> None:
        raise TypeError("DisplayManager is a singleton; call its static methods")

    @staticmethod
    def get_all() -> list[_display.Display]:
        raw = _C.native_display_manager_get_all()
        return _rt.take_handles(
            raw,
            raw.displays,
            _display.Display,
            _C.native_display_list_release,
        )

    @staticmethod
    def get_primary() -> _display.Display | None:
        raw = _C.native_display_manager_get_primary()
        return _display.Display._owned(raw)

    @staticmethod
    def get_cursor_position() -> _geometry.Point:
        raw = _C.native_display_manager_get_cursor_position()
        return _geometry.Point._from_c(raw)

    @staticmethod
    def add_listener(callback: Callable[[_display.DisplayEvent], None]) -> int:
        """Calls `callback` with every DisplayEvent this DisplayManager emits.

        Returns the listener id for `remove_listener()`.
        """

        def trampoline(raw, _user_data):
            event = _display.DisplayEvent._from_c(raw.contents)
            if event is not None:
                callback(event)

        return _rt.add_listener(
            _C.native_display_manager_add_listener,
            _C.native_display_event_callback_t,
            trampoline,
        )

    @staticmethod
    def remove_listener(listener_id: int) -> bool:
        """Unregisters a listener. Returns False if unknown."""
        return _rt.remove_listener(
            _C.native_display_manager_remove_listener,
            listener_id,
        )
