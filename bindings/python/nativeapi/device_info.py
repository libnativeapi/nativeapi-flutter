# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from device_info.h."""

from __future__ import annotations

from . import _capi as _C
from . import _runtime as _rt


class DeviceInfo:
    """The process-wide DeviceInfo; every member is static."""

    def __init__(self) -> None:
        raise TypeError("DeviceInfo is a singleton; call its static methods")

    @staticmethod
    def get_name() -> str:
        raw = _C.native_device_info_get_name()
        return _rt.take_str(raw)

    @staticmethod
    def get_model() -> str:
        raw = _C.native_device_info_get_model()
        return _rt.take_str(raw)

    @staticmethod
    def get_manufacturer() -> str:
        raw = _C.native_device_info_get_manufacturer()
        return _rt.take_str(raw)

    @staticmethod
    def get_os_name() -> str:
        raw = _C.native_device_info_get_os_name()
        return _rt.take_str(raw)

    @staticmethod
    def get_os_version() -> str:
        raw = _C.native_device_info_get_os_version()
        return _rt.take_str(raw)

    @staticmethod
    def get_kernel_version() -> str:
        raw = _C.native_device_info_get_kernel_version()
        return _rt.take_str(raw)

    @staticmethod
    def get_architecture() -> str:
        raw = _C.native_device_info_get_architecture()
        return _rt.take_str(raw)
