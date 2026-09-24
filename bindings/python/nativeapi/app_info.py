# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from app_info.h."""

from __future__ import annotations

from . import _capi as _C
from . import _runtime as _rt


class AppInfo:
    """The process-wide AppInfo; every member is static."""

    def __init__(self) -> None:
        raise TypeError("AppInfo is a singleton; call its static methods")

    @staticmethod
    def get_name() -> str:
        raw = _C.native_app_info_get_name()
        return _rt.take_str(raw)

    @staticmethod
    def get_identifier() -> str:
        raw = _C.native_app_info_get_identifier()
        return _rt.take_str(raw)

    @staticmethod
    def get_version() -> str:
        raw = _C.native_app_info_get_version()
        return _rt.take_str(raw)

    @staticmethod
    def get_build_number() -> str:
        raw = _C.native_app_info_get_build_number()
        return _rt.take_str(raw)
