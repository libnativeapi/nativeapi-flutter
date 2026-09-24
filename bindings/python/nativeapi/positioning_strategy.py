# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from positioning_strategy.h."""

from __future__ import annotations

import enum

from . import _capi as _C
from . import _runtime as _rt
from . import geometry as _geometry
from . import window as _window


class PositioningStrategyType(enum.IntEnum):
    ABSOLUTE = 0
    CURSOR_POSITION = 1
    RELATIVE = 2


class PositioningStrategy(_rt.NativeObject):
    """Owned reference to a native PositioningStrategy.

    `dispose()` (or `with`) releases it; otherwise it is released when the
    wrapper is garbage collected.
    """

    __slots__ = ()
    _free = staticmethod(_C.native_positioning_strategy_free)

    @staticmethod
    def absolute(point: _geometry.Point) -> PositioningStrategy | None:
        raw = _C.native_positioning_strategy_absolute(point._to_c())
        return PositioningStrategy._owned(raw)

    @staticmethod
    def cursor_position() -> PositioningStrategy | None:
        raw = _C.native_positioning_strategy_cursor_position()
        return PositioningStrategy._owned(raw)

    @staticmethod
    def relative_with_rect_and_offset(
        rect: _geometry.Rectangle,
        offset: _geometry.Point,
    ) -> PositioningStrategy | None:
        raw = _C.native_positioning_strategy_relative_with_rect_and_offset(
            rect._to_c(),
            offset._to_c(),
        )
        return PositioningStrategy._owned(raw)

    @staticmethod
    def relative_with_window_and_offset(
        window: _window.Window,
        offset: _geometry.Point,
    ) -> PositioningStrategy | None:
        raw = _C.native_positioning_strategy_relative_with_window_and_offset(
            window._handle,
            offset._to_c(),
        )
        return PositioningStrategy._owned(raw)

    @property
    def type(self) -> PositioningStrategyType:
        raw = _C.native_positioning_strategy_get_type(self._handle)
        return _rt.to_enum(PositioningStrategyType, raw)

    @property
    def absolute_position(self) -> _geometry.Point:
        raw = _C.native_positioning_strategy_get_absolute_position(self._handle)
        return _geometry.Point._from_c(raw)

    @property
    def relative_rectangle(self) -> _geometry.Rectangle:
        raw = _C.native_positioning_strategy_get_relative_rectangle(self._handle)
        return _geometry.Rectangle._from_c(raw)

    @property
    def relative_offset(self) -> _geometry.Point:
        raw = _C.native_positioning_strategy_get_relative_offset(self._handle)
        return _geometry.Point._from_c(raw)
