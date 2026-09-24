# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from foundation/keyboard.h."""

from __future__ import annotations

import enum
from dataclasses import dataclass, field

from . import _capi as _C
from . import _runtime as _rt


class ModifierKey(enum.IntFlag):
    NONE = 0
    SHIFT = 1
    CTRL = 2
    ALT = 4
    META = 8
    FN = 16
    CAPS_LOCK = 32
    NUM_LOCK = 64
    SCROLL_LOCK = 128


@dataclass
class KeyboardAccelerator:
    modifiers: ModifierKey = field(default_factory=lambda: ModifierKey.NONE)
    key: str = ""

    @classmethod
    def _from_c(cls, raw: _C.native_keyboard_accelerator_t) -> KeyboardAccelerator:
        return cls(_rt.to_enum(ModifierKey, raw.modifiers), _rt.decode(raw.key))

    def _to_c(self) -> _C.native_keyboard_accelerator_t:
        raw = _C.native_keyboard_accelerator_t()
        raw.modifiers = int(self.modifiers)
        raw.key = _rt.encode(self.key)
        return raw

    def to_string(self) -> str:
        raw = _C.native_keyboard_accelerator_to_string(self._to_c())
        return _rt.take_str(raw)

    def is_empty(self) -> bool:
        raw = _C.native_keyboard_accelerator_is_empty(self._to_c())
        return raw


@dataclass(frozen=True)
class KeyboardEvent:
    """Base of every KeyboardEvent; listeners receive one of its subclasses."""

    keycode: int

    @staticmethod
    def _from_c(raw: _C.native_keyboard_event_t) -> KeyboardEvent | None:
        if raw.type == 0:
            return KeyPressedEvent(raw.keycode)
        if raw.type == 1:
            return KeyReleasedEvent(raw.keycode)
        if raw.type == 2:
            return ModifierKeysChangedEvent(
                raw.keycode,
                raw.data.modifier_keys_changed.modifier_keys,
            )
        return None


@dataclass(frozen=True)
class KeyPressedEvent(KeyboardEvent):
    pass


@dataclass(frozen=True)
class KeyReleasedEvent(KeyboardEvent):
    pass


@dataclass(frozen=True)
class ModifierKeysChangedEvent(KeyboardEvent):
    modifier_keys: int
