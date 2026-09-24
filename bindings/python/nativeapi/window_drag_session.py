# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from window_drag_session.h."""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass

from . import _capi as _C
from . import _runtime as _rt
from . import geometry as _geometry
from . import window as _window


@dataclass(frozen=True)
class WindowDragEvent:
    """Base of every WindowDragEvent; listeners receive one of its subclasses."""

    window_id: _window.WindowId
    cursor_position: _geometry.Point

    @staticmethod
    def _from_c(raw: _C.native_window_drag_event_t) -> WindowDragEvent | None:
        if raw.type == 0:
            return WindowDragMovedEvent(
                raw.window_id,
                _geometry.Point._from_c(raw.cursor_position),
            )
        if raw.type == 1:
            return WindowDragEndedEvent(
                raw.window_id,
                _geometry.Point._from_c(raw.cursor_position),
            )
        if raw.type == 2:
            return WindowDragCancelledEvent(
                raw.window_id,
                _geometry.Point._from_c(raw.cursor_position),
            )
        return None


@dataclass(frozen=True)
class WindowDragMovedEvent(WindowDragEvent):
    pass


@dataclass(frozen=True)
class WindowDragEndedEvent(WindowDragEvent):
    pass


@dataclass(frozen=True)
class WindowDragCancelledEvent(WindowDragEvent):
    pass


class WindowDragSession(_rt.NativeObject):
    """Owned reference to a native WindowDragSession.

    `dispose()` (or `with`) releases it; otherwise it is released when the
    wrapper is garbage collected.
    """

    __slots__ = ()
    _free = staticmethod(_C.native_window_drag_session_free)

    def __init__(self) -> None:
        handle = _C.native_window_drag_session_create()
        if not handle:
            raise _rt.NativeApiError("failed to create a WindowDragSession")
        self._adopt(handle)

    def start(self, window: _window.Window | None, anchor: _geometry.Point) -> bool:
        raw = _C.native_window_drag_session_start(
            self._handle,
            _rt.handle_of(window),
            anchor._to_c(),
        )
        return raw

    def cancel(self) -> None:
        _C.native_window_drag_session_cancel(self._handle)

    @property
    def is_active(self) -> bool:
        raw = _C.native_window_drag_session_is_active(self._handle)
        return raw

    @property
    def window_id(self) -> _window.WindowId:
        raw = _C.native_window_drag_session_get_window_id(self._handle)
        return raw

    @property
    def anchor(self) -> _geometry.Point:
        raw = _C.native_window_drag_session_get_anchor(self._handle)
        return _geometry.Point._from_c(raw)

    def add_listener(self, callback: Callable[[WindowDragEvent], None]) -> int:
        """Calls `callback` with every WindowDragEvent this WindowDragSession emits.

        Returns the listener id for `remove_listener()`.
        """

        def trampoline(raw, _user_data):
            event = WindowDragEvent._from_c(raw.contents)
            if event is not None:
                callback(event)

        return _rt.add_listener(
            _C.native_window_drag_session_add_listener,
            _C.native_window_drag_event_callback_t,
            trampoline,
            self._handle,
        )

    def remove_listener(self, listener_id: int) -> bool:
        """Unregisters a listener. Returns False if unknown."""
        return _rt.remove_listener(
            _C.native_window_drag_session_remove_listener,
            listener_id,
            self._handle,
        )
