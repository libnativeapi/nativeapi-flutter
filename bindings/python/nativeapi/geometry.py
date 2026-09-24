# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from foundation/geometry.h."""

from __future__ import annotations

from dataclasses import dataclass

from . import _capi as _C


@dataclass
class Point:
    x: float = 0.0
    y: float = 0.0

    @classmethod
    def _from_c(cls, raw: _C.native_point_t) -> Point:
        return cls(raw.x, raw.y)

    def _to_c(self) -> _C.native_point_t:
        raw = _C.native_point_t()
        raw.x = self.x
        raw.y = self.y
        return raw


@dataclass
class Size:
    width: float = 0.0
    height: float = 0.0

    @classmethod
    def _from_c(cls, raw: _C.native_size_t) -> Size:
        return cls(raw.width, raw.height)

    def _to_c(self) -> _C.native_size_t:
        raw = _C.native_size_t()
        raw.width = self.width
        raw.height = self.height
        return raw


@dataclass
class Rectangle:
    x: float = 0.0
    y: float = 0.0
    width: float = 0.0
    height: float = 0.0

    @classmethod
    def _from_c(cls, raw: _C.native_rectangle_t) -> Rectangle:
        return cls(raw.x, raw.y, raw.width, raw.height)

    def _to_c(self) -> _C.native_rectangle_t:
        raw = _C.native_rectangle_t()
        raw.x = self.x
        raw.y = self.y
        raw.width = self.width
        raw.height = self.height
        return raw
