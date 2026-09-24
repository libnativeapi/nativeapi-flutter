# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from notification_manager.h."""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass

from . import _capi as _C
from . import _runtime as _rt


@dataclass(frozen=True)
class NotificationEvent:
    """Base of every NotificationEvent; listeners receive one of its subclasses."""

    @staticmethod
    def _from_c(raw: _C.native_notification_event_t) -> NotificationEvent | None:
        if raw.type == 0:
            return NotificationActivatedEvent(_rt.decode(raw.data.activated.argument))
        return None


@dataclass(frozen=True)
class NotificationActivatedEvent(NotificationEvent):
    argument: str


class NotificationManager:
    """The process-wide NotificationManager; every member is static."""

    def __init__(self) -> None:
        raise TypeError("NotificationManager is a singleton; call its static methods")

    @staticmethod
    def is_supported() -> bool:
        raw = _C.native_notification_manager_is_supported()
        return raw

    @staticmethod
    def initialize() -> bool:
        raw = _C.native_notification_manager_initialize()
        return raw

    @staticmethod
    def shutdown() -> None:
        _C.native_notification_manager_shutdown()

    @staticmethod
    def show(title: str, message: str, tag: str, button_label: str) -> bool:
        raw = _C.native_notification_manager_show(
            _rt.encode(title),
            _rt.encode(message),
            _rt.encode(tag),
            _rt.encode(button_label),
        )
        return raw

    @staticmethod
    def remove(tag: str) -> bool:
        raw = _C.native_notification_manager_remove(_rt.encode(tag))
        return raw

    @staticmethod
    def get_last_error() -> str:
        raw = _C.native_notification_manager_get_last_error()
        return _rt.take_str(raw)

    @staticmethod
    def add_listener(callback: Callable[[NotificationEvent], None]) -> int:
        """Calls `callback` with every NotificationEvent this NotificationManager emits.

        Returns the listener id for `remove_listener()`.
        """

        def trampoline(raw, _user_data):
            event = NotificationEvent._from_c(raw.contents)
            if event is not None:
                callback(event)

        return _rt.add_listener(
            _C.native_notification_manager_add_listener,
            _C.native_notification_event_callback_t,
            trampoline,
        )

    @staticmethod
    def remove_listener(listener_id: int) -> bool:
        """Unregisters a listener. Returns False if unknown."""
        return _rt.remove_listener(
            _C.native_notification_manager_remove_listener,
            listener_id,
        )
