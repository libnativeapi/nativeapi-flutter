# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from launch_at_login.h."""

from __future__ import annotations

from . import _capi as _C
from . import _runtime as _rt


class LaunchAtLogin(_rt.NativeObject):
    """Owned reference to a native LaunchAtLogin.

    `dispose()` (or `with`) releases it; otherwise it is released when the
    wrapper is garbage collected.
    """

    __slots__ = ()
    _free = staticmethod(_C.native_launch_at_login_free)

    def __init__(self) -> None:
        handle = _C.native_launch_at_login_create()
        if not handle:
            raise _rt.NativeApiError("failed to create a LaunchAtLogin")
        self._adopt(handle)

    @classmethod
    def with_id(cls, id: str) -> LaunchAtLogin:
        handle = _C.native_launch_at_login_create_with_id(_rt.encode(id))
        if not handle:
            raise _rt.NativeApiError("failed to create a LaunchAtLogin")
        return cls._owned(handle)

    @classmethod
    def with_id_and_display_name(cls, id: str, display_name: str) -> LaunchAtLogin:
        handle = _C.native_launch_at_login_create_with_id_and_display_name(
            _rt.encode(id),
            _rt.encode(display_name),
        )
        if not handle:
            raise _rt.NativeApiError("failed to create a LaunchAtLogin")
        return cls._owned(handle)

    @staticmethod
    def is_supported() -> bool:
        raw = _C.native_launch_at_login_is_supported()
        return raw

    @property
    def id(self) -> str:
        raw = _C.native_launch_at_login_get_id(self._handle)
        return _rt.take_str(raw)

    @property
    def display_name(self) -> str:
        raw = _C.native_launch_at_login_get_display_name(self._handle)
        return _rt.take_str(raw)

    def set_display_name(self, display_name: str) -> bool:
        raw = _C.native_launch_at_login_set_display_name(
            self._handle,
            _rt.encode(display_name),
        )
        return raw

    def set_program(self, executable_path: str, arguments: list[str]) -> bool:
        raw = _C.native_launch_at_login_set_program(
            self._handle,
            _rt.encode(executable_path),
            _rt.str_list(arguments),
        )
        return raw

    @property
    def executable_path(self) -> str:
        raw = _C.native_launch_at_login_get_executable_path(self._handle)
        return _rt.take_str(raw)

    @property
    def arguments(self) -> list[str]:
        raw = _C.native_launch_at_login_get_arguments(self._handle)
        return _rt.take_str_list(raw)

    def enable(self) -> bool:
        raw = _C.native_launch_at_login_enable(self._handle)
        return raw

    def disable(self) -> bool:
        raw = _C.native_launch_at_login_disable(self._handle)
        return raw

    @property
    def is_enabled(self) -> bool:
        raw = _C.native_launch_at_login_is_enabled(self._handle)
        return raw
