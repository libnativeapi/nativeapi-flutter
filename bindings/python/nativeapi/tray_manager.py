# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from tray_manager.h."""

from __future__ import annotations

from . import _capi as _C
from . import _runtime as _rt
from . import tray_icon as _tray_icon


class TrayManager:
    """The process-wide TrayManager; every member is static."""

    def __init__(self) -> None:
        raise TypeError("TrayManager is a singleton; call its static methods")

    @staticmethod
    def is_supported() -> bool:
        raw = _C.native_tray_manager_is_supported()
        return raw

    @staticmethod
    def get(id: _tray_icon.TrayIconId) -> _tray_icon.TrayIcon | None:
        raw = _C.native_tray_manager_get(id)
        return _tray_icon.TrayIcon._owned(raw)

    @staticmethod
    def get_all() -> list[_tray_icon.TrayIcon]:
        raw = _C.native_tray_manager_get_all()
        return _rt.take_handles(
            raw,
            raw.tray_icons,
            _tray_icon.TrayIcon,
            _C.native_tray_icon_list_release,
        )
