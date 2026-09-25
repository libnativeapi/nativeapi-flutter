# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from drag_source.h."""

from __future__ import annotations

import enum
from collections.abc import Callable
from dataclasses import dataclass

from . import _capi as _C
from . import _runtime as _rt
from . import geometry as _geometry
from . import image as _image
from . import window as _window


class DragOperation(enum.IntEnum):
    NONE = 0
    COPY = 1
    MOVE = 2
    LINK = 3


@dataclass(frozen=True)
class DragSourceEvent:
    """Base of every DragSourceEvent; listeners receive one of its subclasses."""

    window_id: _window.WindowId
    position: _geometry.Point

    @staticmethod
    def _from_c(raw: _C.native_drag_source_event_t) -> DragSourceEvent | None:
        if raw.type == 0:
            return DragSourceEndedEvent(
                raw.window_id,
                _geometry.Point._from_c(raw.position),
                _rt.to_enum(DragOperation, raw.data.ended.operation),
            )
        return None


@dataclass(frozen=True)
class DragSourceEndedEvent(DragSourceEvent):
    operation: DragOperation


class DragSource(_rt.NativeObject):
    """Owned reference to a native DragSource.

    `dispose()` (or `with`) releases it; otherwise it is released when the
    wrapper is garbage collected.
    """

    __slots__ = ()
    _free = staticmethod(_C.native_drag_source_free)

    def __init__(self) -> None:
        handle = _C.native_drag_source_create()
        if not handle:
            raise _rt.NativeApiError("failed to create a DragSource")
        self._adopt(handle)

    @staticmethod
    def is_supported() -> bool:
        raw = _C.native_drag_source_is_supported()
        return raw

    def set_file_paths(self, file_paths: list[str]) -> None:
        _C.native_drag_source_set_file_paths(self._handle, _rt.str_list(file_paths))

    @property
    def file_paths(self) -> list[str]:
        raw = _C.native_drag_source_get_file_paths(self._handle)
        return _rt.take_str_list(raw)

    def set_text(self, text: str | None) -> None:
        _C.native_drag_source_set_text(self._handle, _rt.encode_optional(text))

    @property
    def text(self) -> str | None:
        raw = _C.native_drag_source_get_text(self._handle)
        return _rt.take_optional_str(raw)

    def set_image(self, image: _image.Image | None) -> None:
        _C.native_drag_source_set_image(self._handle, _rt.handle_of(image))

    @property
    def image(self) -> _image.Image | None:
        raw = _C.native_drag_source_get_image(self._handle)
        return _image.Image._owned(raw)

    def set_drag_operation(self, operation: DragOperation) -> None:
        _C.native_drag_source_set_drag_operation(self._handle, int(operation))

    @property
    def drag_operation(self) -> DragOperation:
        raw = _C.native_drag_source_get_drag_operation(self._handle)
        return _rt.to_enum(DragOperation, raw)

    def start_dragging(self, window: _window.Window | None) -> bool:
        raw = _C.native_drag_source_start_dragging(self._handle, _rt.handle_of(window))
        return raw

    @property
    def is_dragging(self) -> bool:
        raw = _C.native_drag_source_is_dragging(self._handle)
        return raw

    @file_paths.setter
    def file_paths(self, value: list[str]) -> None:
        self.set_file_paths(value)

    @text.setter
    def text(self, value: str | None) -> None:
        self.set_text(value)

    @image.setter
    def image(self, value: _image.Image | None) -> None:
        self.set_image(value)

    @drag_operation.setter
    def drag_operation(self, value: DragOperation) -> None:
        self.set_drag_operation(value)

    def add_listener(self, callback: Callable[[DragSourceEvent], None]) -> int:
        """Calls `callback` with every DragSourceEvent this DragSource emits.

        Returns the listener id for `remove_listener()`.
        """

        def trampoline(raw, _user_data):
            event = DragSourceEvent._from_c(raw.contents)
            if event is not None:
                callback(event)

        return _rt.add_listener(
            _C.native_drag_source_add_listener,
            _C.native_drag_source_event_callback_t,
            trampoline,
            self._handle,
        )

    def remove_listener(self, listener_id: int) -> bool:
        """Unregisters a listener. Returns False if unknown."""
        return _rt.remove_listener(
            _C.native_drag_source_remove_listener,
            listener_id,
            self._handle,
        )
