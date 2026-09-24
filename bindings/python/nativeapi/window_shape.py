# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from window_shape.h."""

from __future__ import annotations

from . import _capi as _C
from . import _runtime as _rt
from . import geometry as _geometry


class WindowShape(_rt.NativeObject):
    """Owned reference to a native WindowShape.

    `dispose()` (or `with`) releases it; otherwise it is released when the
    wrapper is garbage collected.
    """

    __slots__ = ()
    _free = staticmethod(_C.native_window_shape_free)

    def __init__(self) -> None:
        handle = _C.native_window_shape_create()
        if not handle:
            raise _rt.NativeApiError("failed to create a WindowShape")
        self._adopt(handle)

    def add_point(self, point: _geometry.Point) -> bool:
        raw = _C.native_window_shape_add_point(self._handle, point._to_c())
        return raw

    def clear(self) -> None:
        _C.native_window_shape_clear(self._handle)

    @property
    def point_count(self) -> int:
        raw = _C.native_window_shape_get_point_count(self._handle)
        return raw

    def get_point_at(self, index: int) -> _geometry.Point:
        raw = _C.native_window_shape_get_point_at(self._handle, index)
        return _geometry.Point._from_c(raw)
