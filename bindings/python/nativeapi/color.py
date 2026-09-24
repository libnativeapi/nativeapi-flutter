# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from foundation/color.h."""

from __future__ import annotations

from dataclasses import dataclass
from typing import ClassVar

from . import _capi as _C
from . import _runtime as _rt


@dataclass
class Color:
    r: int = 0
    g: int = 0
    b: int = 0
    a: int = 0
    TRANSPARENT: ClassVar[Color]
    BLACK: ClassVar[Color]
    WHITE: ClassVar[Color]
    RED: ClassVar[Color]
    GREEN: ClassVar[Color]
    BLUE: ClassVar[Color]
    YELLOW: ClassVar[Color]
    CYAN: ClassVar[Color]
    MAGENTA: ClassVar[Color]

    @classmethod
    def _from_c(cls, raw: _C.native_color_t) -> Color:
        return cls(raw.r, raw.g, raw.b, raw.a)

    def _to_c(self) -> _C.native_color_t:
        raw = _C.native_color_t()
        raw.r = self.r
        raw.g = self.g
        raw.b = self.b
        raw.a = self.a
        return raw

    @classmethod
    def from_rgba(cls, red: int, green: int, blue: int, alpha: int) -> Color:
        raw = _C.native_color_from_rgba(red, green, blue, alpha)
        return Color._from_c(raw)

    @classmethod
    def from_hex(cls, hex: str) -> Color:
        raw = _C.native_color_from_hex(_rt.encode(hex))
        return Color._from_c(raw)

    def to_rgba(self) -> int:
        raw = _C.native_color_to_rgba(self._to_c())
        return raw

    def to_argb(self) -> int:
        raw = _C.native_color_to_argb(self._to_c())
        return raw


Color.TRANSPARENT = Color._from_c(_C.NATIVE_COLOR_TRANSPARENT)
Color.BLACK = Color._from_c(_C.NATIVE_COLOR_BLACK)
Color.WHITE = Color._from_c(_C.NATIVE_COLOR_WHITE)
Color.RED = Color._from_c(_C.NATIVE_COLOR_RED)
Color.GREEN = Color._from_c(_C.NATIVE_COLOR_GREEN)
Color.BLUE = Color._from_c(_C.NATIVE_COLOR_BLUE)
Color.YELLOW = Color._from_c(_C.NATIVE_COLOR_YELLOW)
Color.CYAN = Color._from_c(_C.NATIVE_COLOR_CYAN)
Color.MAGENTA = Color._from_c(_C.NATIVE_COLOR_MAGENTA)
