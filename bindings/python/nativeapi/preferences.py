# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from preferences.h."""

from __future__ import annotations

from . import _capi as _C
from . import _runtime as _rt


class Preferences(_rt.NativeObject):
    """Owned reference to a native Preferences.

    `dispose()` (or `with`) releases it; otherwise it is released when the
    wrapper is garbage collected.
    """

    __slots__ = ()
    _free = staticmethod(_C.native_preferences_free)

    def __init__(self) -> None:
        handle = _C.native_preferences_create()
        if not handle:
            raise _rt.NativeApiError("failed to create a Preferences")
        self._adopt(handle)

    @classmethod
    def with_scope(cls, scope: str) -> Preferences:
        handle = _C.native_preferences_create_with_scope(_rt.encode(scope))
        if not handle:
            raise _rt.NativeApiError("failed to create a Preferences")
        return cls._owned(handle)

    def set(self, key: str, value: str) -> bool:
        raw = _C.native_preferences_set(
            self._handle,
            _rt.encode(key),
            _rt.encode(value),
        )
        return raw

    def get(self, key: str, default_value: str) -> str:
        raw = _C.native_preferences_get(
            self._handle,
            _rt.encode(key),
            _rt.encode(default_value),
        )
        return _rt.take_str(raw)

    def remove(self, key: str) -> bool:
        raw = _C.native_preferences_remove(self._handle, _rt.encode(key))
        return raw

    def clear(self) -> bool:
        raw = _C.native_preferences_clear(self._handle)
        return raw

    def contains(self, key: str) -> bool:
        raw = _C.native_preferences_contains(self._handle, _rt.encode(key))
        return raw

    @property
    def keys(self) -> list[str]:
        raw = _C.native_preferences_get_keys(self._handle)
        return _rt.take_str_list(raw)

    @property
    def size(self) -> int:
        raw = _C.native_preferences_get_size(self._handle)
        return raw

    @property
    def all(self) -> dict[str, str]:
        raw = _C.native_preferences_get_all(self._handle)
        return _rt.take_str_map(raw)

    @property
    def scope(self) -> str:
        raw = _C.native_preferences_get_scope(self._handle)
        return _rt.take_str(raw)
