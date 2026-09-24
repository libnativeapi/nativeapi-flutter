# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from keyboard_monitor.h."""

from __future__ import annotations

from collections.abc import Callable

from . import _capi as _C
from . import _runtime as _rt
from . import keyboard as _keyboard


class KeyboardMonitor(_rt.NativeObject):
    """Owned reference to a native KeyboardMonitor.

    `dispose()` (or `with`) releases it; otherwise it is released when the
    wrapper is garbage collected.
    """

    __slots__ = ()
    _free = staticmethod(_C.native_keyboard_monitor_free)

    def __init__(self) -> None:
        handle = _C.native_keyboard_monitor_create()
        if not handle:
            raise _rt.NativeApiError("failed to create a KeyboardMonitor")
        self._adopt(handle)

    def start(self) -> None:
        _C.native_keyboard_monitor_start(self._handle)

    def stop(self) -> None:
        _C.native_keyboard_monitor_stop(self._handle)

    @property
    def is_monitoring(self) -> bool:
        raw = _C.native_keyboard_monitor_is_monitoring(self._handle)
        return raw

    def add_listener(self, callback: Callable[[_keyboard.KeyboardEvent], None]) -> int:
        """Calls `callback` with every KeyboardEvent this KeyboardMonitor emits.

        Returns the listener id for `remove_listener()`.
        """

        def trampoline(raw, _user_data):
            event = _keyboard.KeyboardEvent._from_c(raw.contents)
            if event is not None:
                callback(event)

        return _rt.add_listener(
            _C.native_keyboard_monitor_add_listener,
            _C.native_keyboard_event_callback_t,
            trampoline,
            self._handle,
        )

    def remove_listener(self, listener_id: int) -> bool:
        """Unregisters a listener. Returns False if unknown."""
        return _rt.remove_listener(
            _C.native_keyboard_monitor_remove_listener,
            listener_id,
            self._handle,
        )
