# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from accessibility_manager.h."""

from __future__ import annotations

from . import _capi as _C


class AccessibilityManager:
    """The process-wide AccessibilityManager; every member is static."""

    def __init__(self) -> None:
        raise TypeError("AccessibilityManager is a singleton; call its static methods")

    @staticmethod
    def enable() -> None:
        _C.native_accessibility_manager_enable()

    @staticmethod
    def is_enabled() -> bool:
        raw = _C.native_accessibility_manager_is_enabled()
        return raw
