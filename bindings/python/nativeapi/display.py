# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from display.h."""

from __future__ import annotations

import enum
from dataclasses import dataclass

from . import _capi as _C
from . import _runtime as _rt
from . import geometry as _geometry

DisplayId = int


class DisplayOrientation(enum.IntEnum):
    PORTRAIT = 0
    LANDSCAPE = 90
    PORTRAIT_FLIPPED = 180
    LANDSCAPE_FLIPPED = 270


@dataclass(frozen=True)
class DisplayEvent:
    """Base of every DisplayEvent; listeners receive one of its subclasses."""

    display: Display | None

    @staticmethod
    def _from_c(raw: _C.native_display_event_t) -> DisplayEvent | None:
        if raw.type == 0:
            return DisplayAddedEvent(Display._borrowed(raw.display))
        if raw.type == 1:
            return DisplayRemovedEvent(Display._borrowed(raw.display))
        if raw.type == 2:
            return DisplayChangedEvent(Display._borrowed(raw.display))
        return None


@dataclass(frozen=True)
class DisplayAddedEvent(DisplayEvent):
    pass


@dataclass(frozen=True)
class DisplayRemovedEvent(DisplayEvent):
    pass


@dataclass(frozen=True)
class DisplayChangedEvent(DisplayEvent):
    pass


class Display(_rt.NativeObject):
    """Owned reference to a native Display.

    `dispose()` (or `with`) releases it; otherwise it is released when the
    wrapper is garbage collected.
    """

    __slots__ = ()
    _free = staticmethod(_C.native_display_free)

    def __init__(self, display: int | None) -> None:
        handle = _C.native_display_create(display)
        if not handle:
            raise _rt.NativeApiError("failed to create a Display")
        self._adopt(handle)

    @property
    def id(self) -> DisplayId:
        raw = _C.native_display_get_id(self._handle)
        return raw

    @property
    def name(self) -> str:
        raw = _C.native_display_get_name(self._handle)
        return _rt.take_str(raw)

    @property
    def position(self) -> _geometry.Point:
        raw = _C.native_display_get_position(self._handle)
        return _geometry.Point._from_c(raw)

    @property
    def size(self) -> _geometry.Size:
        raw = _C.native_display_get_size(self._handle)
        return _geometry.Size._from_c(raw)

    @property
    def work_area(self) -> _geometry.Rectangle:
        raw = _C.native_display_get_work_area(self._handle)
        return _geometry.Rectangle._from_c(raw)

    @property
    def scale_factor(self) -> float:
        raw = _C.native_display_get_scale_factor(self._handle)
        return raw

    @property
    def is_primary(self) -> bool:
        raw = _C.native_display_is_primary(self._handle)
        return raw

    @property
    def orientation(self) -> DisplayOrientation:
        raw = _C.native_display_get_orientation(self._handle)
        return _rt.to_enum(DisplayOrientation, raw)

    @property
    def refresh_rate(self) -> int:
        raw = _C.native_display_get_refresh_rate(self._handle)
        return raw

    @property
    def bit_depth(self) -> int:
        raw = _C.native_display_get_bit_depth(self._handle)
        return raw

    @property
    def native_object(self) -> int | None:
        """The platform object behind this handle (NSWindow*, HWND, ...)."""
        return _C.native_display_get_native_object(self._handle)
