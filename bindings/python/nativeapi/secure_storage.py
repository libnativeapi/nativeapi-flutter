# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from secure_storage.h."""

from __future__ import annotations

from . import _capi as _C
from . import _runtime as _rt


class SecureStorage(_rt.NativeObject):
    """Owned reference to a native SecureStorage.

    `dispose()` (or `with`) releases it; otherwise it is released when the
    wrapper is garbage collected.
    """

    __slots__ = ()
    _free = staticmethod(_C.native_secure_storage_free)

    def __init__(self) -> None:
        handle = _C.native_secure_storage_create()
        if not handle:
            raise _rt.NativeApiError("failed to create a SecureStorage")
        self._adopt(handle)

    @classmethod
    def with_scope(cls, scope: str) -> SecureStorage:
        handle = _C.native_secure_storage_create_with_scope(_rt.encode(scope))
        if not handle:
            raise _rt.NativeApiError("failed to create a SecureStorage")
        return cls._owned(handle)

    def set(self, key: str, value: str) -> bool:
        raw = _C.native_secure_storage_set(
            self._handle,
            _rt.encode(key),
            _rt.encode(value),
        )
        return raw

    def get(self, key: str, default_value: str) -> str:
        raw = _C.native_secure_storage_get(
            self._handle,
            _rt.encode(key),
            _rt.encode(default_value),
        )
        return _rt.take_str(raw)

    def remove(self, key: str) -> bool:
        raw = _C.native_secure_storage_remove(self._handle, _rt.encode(key))
        return raw

    def clear(self) -> bool:
        raw = _C.native_secure_storage_clear(self._handle)
        return raw

    def contains(self, key: str) -> bool:
        raw = _C.native_secure_storage_contains(self._handle, _rt.encode(key))
        return raw

    @property
    def keys(self) -> list[str]:
        raw = _C.native_secure_storage_get_keys(self._handle)
        return _rt.take_str_list(raw)

    @property
    def size(self) -> int:
        raw = _C.native_secure_storage_get_size(self._handle)
        return raw

    @property
    def all(self) -> dict[str, str]:
        raw = _C.native_secure_storage_get_all(self._handle)
        return _rt.take_str_map(raw)

    @property
    def scope(self) -> str:
        raw = _C.native_secure_storage_get_scope(self._handle)
        return _rt.take_str(raw)

    @staticmethod
    def is_available() -> bool:
        raw = _C.native_secure_storage_is_available()
        return raw
