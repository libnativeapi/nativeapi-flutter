# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from window_shadow.h."""

from __future__ import annotations

from . import _capi as _C
from . import _runtime as _rt
from . import color as _color
from . import geometry as _geometry


class WindowShadow(_rt.NativeObject):
    """Owned reference to a native WindowShadow.

    `dispose()` (or `with`) releases it; otherwise it is released when the
    wrapper is garbage collected.
    """

    __slots__ = ()
    _free = staticmethod(_C.native_window_shadow_free)

    def __init__(self) -> None:
        handle = _C.native_window_shadow_create()
        if not handle:
            raise _rt.NativeApiError("failed to create a WindowShadow")
        self._adopt(handle)

    def set_color(self, color: _color.Color) -> None:
        _C.native_window_shadow_set_color(self._handle, color._to_c())

    @property
    def color(self) -> _color.Color:
        raw = _C.native_window_shadow_get_color(self._handle)
        return _color.Color._from_c(raw)

    def set_blur_radius(self, radius: float) -> bool:
        raw = _C.native_window_shadow_set_blur_radius(self._handle, radius)
        return raw

    @property
    def blur_radius(self) -> float:
        raw = _C.native_window_shadow_get_blur_radius(self._handle)
        return raw

    def set_offset(self, offset: _geometry.Point) -> bool:
        raw = _C.native_window_shadow_set_offset(self._handle, offset._to_c())
        return raw

    @property
    def offset(self) -> _geometry.Point:
        raw = _C.native_window_shadow_get_offset(self._handle)
        return _geometry.Point._from_c(raw)

    @color.setter
    def color(self, value: _color.Color) -> None:
        self.set_color(value)
