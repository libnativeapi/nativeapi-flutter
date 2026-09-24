# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from url_opener.h."""

from __future__ import annotations

import enum
from dataclasses import dataclass, field

from . import _capi as _C
from . import _runtime as _rt


class UrlOpenErrorCode(enum.IntEnum):
    NONE = 0
    INVALID_URL_EMPTY = 1
    INVALID_URL_MISSING_SCHEME = 2
    INVALID_URL_UNSUPPORTED_SCHEME = 3
    UNSUPPORTED_PLATFORM = 4
    INVOCATION_FAILED = 5


@dataclass
class UrlOpenResult:
    success: bool = False
    error_code: UrlOpenErrorCode = field(default_factory=lambda: UrlOpenErrorCode.NONE)
    error_message: str = ""

    @classmethod
    def _from_c(cls, raw: _C.native_url_open_result_t) -> UrlOpenResult:
        return cls(
            bool(raw.success),
            _rt.to_enum(UrlOpenErrorCode, raw.error_code),
            _rt.decode(raw.error_message),
        )

    def _to_c(self) -> _C.native_url_open_result_t:
        raw = _C.native_url_open_result_t()
        raw.success = self.success
        raw.error_code = int(self.error_code)
        raw.error_message = _rt.encode(self.error_message)
        return raw


class UrlOpener:
    """The process-wide UrlOpener; every member is static."""

    def __init__(self) -> None:
        raise TypeError("UrlOpener is a singleton; call its static methods")

    @staticmethod
    def is_supported() -> bool:
        raw = _C.native_url_opener_is_supported()
        return raw

    @staticmethod
    def can_open(url: str) -> bool:
        raw = _C.native_url_opener_can_open(_rt.encode(url))
        return raw

    @staticmethod
    def open(url: str) -> UrlOpenResult:
        raw = _C.native_url_opener_open(_rt.encode(url))
        value = UrlOpenResult._from_c(raw)
        _C.native_url_open_result_free(_rt.byref(raw))
        return value
