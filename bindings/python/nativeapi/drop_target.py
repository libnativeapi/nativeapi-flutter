# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from drop_target.h."""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass

from . import _capi as _C
from . import _runtime as _rt
from . import drag_source as _drag_source
from . import geometry as _geometry
from . import window as _window


@dataclass(frozen=True)
class DropTargetEvent:
    """Base of every DropTargetEvent; listeners receive one of its subclasses."""

    window_id: _window.WindowId
    position: _geometry.Point

    @staticmethod
    def _from_c(raw: _C.native_drop_target_event_t) -> DropTargetEvent | None:
        if raw.type == 0:
            return DropTargetEnteredEvent(
                raw.window_id,
                _geometry.Point._from_c(raw.position),
            )
        if raw.type == 1:
            return DropTargetMovedEvent(
                raw.window_id,
                _geometry.Point._from_c(raw.position),
            )
        if raw.type == 2:
            return DropTargetExitedEvent(
                raw.window_id,
                _geometry.Point._from_c(raw.position),
            )
        if raw.type == 3:
            return DropTargetDroppedEvent(
                raw.window_id,
                _geometry.Point._from_c(raw.position),
                _rt.read_str_list(raw.data.dropped.file_paths),
                _rt.decode(raw.data.dropped.text),
            )
        return None


@dataclass(frozen=True)
class DropTargetEnteredEvent(DropTargetEvent):
    pass


@dataclass(frozen=True)
class DropTargetMovedEvent(DropTargetEvent):
    pass


@dataclass(frozen=True)
class DropTargetExitedEvent(DropTargetEvent):
    pass


@dataclass(frozen=True)
class DropTargetDroppedEvent(DropTargetEvent):
    file_paths: list[str]
    text: str


class DropTarget(_rt.NativeObject):
    """Owned reference to a native DropTarget.

    `dispose()` (or `with`) releases it; otherwise it is released when the
    wrapper is garbage collected.
    """

    __slots__ = ()
    _free = staticmethod(_C.native_drop_target_free)

    def __init__(self, window: _window.Window | None) -> None:
        handle = _C.native_drop_target_create(_rt.handle_of(window))
        if not handle:
            raise _rt.NativeApiError("failed to create a DropTarget")
        self._adopt(handle)

    @staticmethod
    def is_supported() -> bool:
        raw = _C.native_drop_target_is_supported()
        return raw

    @property
    def window_id(self) -> _window.WindowId:
        raw = _C.native_drop_target_get_window_id(self._handle)
        return raw

    def set_drop_operation(self, operation: _drag_source.DragOperation) -> None:
        _C.native_drop_target_set_drop_operation(self._handle, int(operation))

    @property
    def drop_operation(self) -> _drag_source.DragOperation:
        raw = _C.native_drop_target_get_drop_operation(self._handle)
        return _rt.to_enum(_drag_source.DragOperation, raw)

    @property
    def is_active(self) -> bool:
        raw = _C.native_drop_target_is_active(self._handle)
        return raw

    def add_listener(self, callback: Callable[[DropTargetEvent], None]) -> int:
        """Calls `callback` with every DropTargetEvent this DropTarget emits.

        Returns the listener id for `remove_listener()`.
        """

        def trampoline(raw, _user_data):
            event = DropTargetEvent._from_c(raw.contents)
            if event is not None:
                callback(event)

        return _rt.add_listener(
            _C.native_drop_target_add_listener,
            _C.native_drop_target_event_callback_t,
            trampoline,
            self._handle,
        )

    def remove_listener(self, listener_id: int) -> bool:
        """Unregisters a listener. Returns False if unknown."""
        return _rt.remove_listener(
            _C.native_drop_target_remove_listener,
            listener_id,
            self._handle,
        )
