# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from shortcut.h."""

from __future__ import annotations

import enum
from collections.abc import Callable
from dataclasses import dataclass, field

from . import _capi as _C
from . import _runtime as _rt

ShortcutId = int


class ShortcutScope(enum.IntEnum):
    GLOBAL = 0
    APPLICATION = 1


@dataclass
class ShortcutOptions:
    accelerator: str = ""
    callback: Callable[[], None] | None = None
    description: str = ""
    scope: ShortcutScope = field(default_factory=lambda: ShortcutScope.GLOBAL)
    enabled: bool = False

    @classmethod
    def _from_c(cls, raw: _C.native_shortcut_options_t) -> ShortcutOptions:
        return cls(
            _rt.decode(raw.accelerator),
            None,
            _rt.decode(raw.description),
            _rt.to_enum(ShortcutScope, raw.scope),
            bool(raw.enabled),
        )

    def _to_c(self) -> _C.native_shortcut_options_t:
        raw = _C.native_shortcut_options_t()
        raw.accelerator = _rt.encode(self.accelerator)
        if self.callback is not None:
            fn = self.callback
            raw.callback = _rt.make_callback(
                _C.native_void_callback_t,
                lambda _user_data: fn(),
            )
            raw.callback_user_data = _rt.user_data(raw.callback)
            raw.callback_release_user_data = _rt.release_user_data
        raw.description = _rt.encode(self.description)
        raw.scope = int(self.scope)
        raw.enabled = self.enabled
        return raw


@dataclass(frozen=True)
class ShortcutEvent:
    """Base of every ShortcutEvent; listeners receive one of its subclasses."""

    shortcut_id: ShortcutId
    accelerator: str

    @staticmethod
    def _from_c(raw: _C.native_shortcut_event_t) -> ShortcutEvent | None:
        if raw.type == 0:
            return ShortcutActivatedEvent(raw.shortcut_id, _rt.decode(raw.accelerator))
        if raw.type == 1:
            return ShortcutRegisteredEvent(raw.shortcut_id, _rt.decode(raw.accelerator))
        if raw.type == 2:
            return ShortcutUnregisteredEvent(
                raw.shortcut_id,
                _rt.decode(raw.accelerator),
            )
        if raw.type == 3:
            return ShortcutRegistrationFailedEvent(
                raw.shortcut_id,
                _rt.decode(raw.accelerator),
                _rt.decode(raw.data.registration_failed.error_message),
            )
        return None


@dataclass(frozen=True)
class ShortcutActivatedEvent(ShortcutEvent):
    pass


@dataclass(frozen=True)
class ShortcutRegisteredEvent(ShortcutEvent):
    pass


@dataclass(frozen=True)
class ShortcutUnregisteredEvent(ShortcutEvent):
    pass


@dataclass(frozen=True)
class ShortcutRegistrationFailedEvent(ShortcutEvent):
    error_message: str


class Shortcut(_rt.NativeObject):
    """Owned reference to a native Shortcut.

    `dispose()` (or `with`) releases it; otherwise it is released when the
    wrapper is garbage collected.
    """

    __slots__ = ()
    _free = staticmethod(_C.native_shortcut_free)

    @classmethod
    def with_id_and_options(cls, id: ShortcutId, options: ShortcutOptions) -> Shortcut:
        handle = _C.native_shortcut_create_with_id_and_options(id, options._to_c())
        if not handle:
            raise _rt.NativeApiError("failed to create a Shortcut")
        return cls._owned(handle)

    @classmethod
    def with_id_and_accelerator_and_callback(
        cls,
        id: ShortcutId,
        accelerator: str,
        callback: Callable[[], None],
    ) -> Shortcut:
        native_callback = _rt.make_callback(
            _C.native_void_callback_t,
            lambda _user_data: callback(),
        )
        handle = _C.native_shortcut_create_with_id_and_accelerator_and_callback(
            id,
            _rt.encode(accelerator),
            native_callback,
            _rt.user_data(native_callback),
            _rt.release_user_data,
        )
        if not handle:
            raise _rt.NativeApiError("failed to create a Shortcut")
        return cls._owned(handle)

    @property
    def id(self) -> ShortcutId:
        raw = _C.native_shortcut_get_id(self._handle)
        return raw

    @property
    def accelerator(self) -> str:
        raw = _C.native_shortcut_get_accelerator(self._handle)
        return _rt.take_str(raw)

    @property
    def description(self) -> str:
        raw = _C.native_shortcut_get_description(self._handle)
        return _rt.take_str(raw)

    def set_description(self, description: str) -> None:
        _C.native_shortcut_set_description(self._handle, _rt.encode(description))

    @property
    def scope(self) -> ShortcutScope:
        raw = _C.native_shortcut_get_scope(self._handle)
        return _rt.to_enum(ShortcutScope, raw)

    def set_enabled(self, enabled: bool) -> None:
        _C.native_shortcut_set_enabled(self._handle, enabled)

    @property
    def is_enabled(self) -> bool:
        raw = _C.native_shortcut_is_enabled(self._handle)
        return raw

    def invoke(self) -> None:
        _C.native_shortcut_invoke(self._handle)

    def set_callback(self, callback: Callable[[], None]) -> None:
        native_callback = _rt.make_callback(
            _C.native_void_callback_t,
            lambda _user_data: callback(),
        )
        _C.native_shortcut_set_callback(
            self._handle,
            native_callback,
            _rt.user_data(native_callback),
            _rt.release_user_data,
        )

    @description.setter
    def description(self, value: str) -> None:
        self.set_description(value)
