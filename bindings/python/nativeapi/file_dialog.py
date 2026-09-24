# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from file_dialog.h."""

from __future__ import annotations

import enum

from . import _capi as _C
from . import _runtime as _rt
from . import dialog as _dialog
from . import window as _window


class FileDialogMode(enum.IntEnum):
    OPEN_FILE = 0
    OPEN_FILES = 1
    SAVE_FILE = 2
    SELECT_FOLDER = 3


class FileDialogResult(enum.IntEnum):
    NONE = 0
    ACCEPTED = 1
    CANCELLED = 2
    FAILED = 3


class FileDialog(_rt.NativeObject):
    """Owned reference to a native FileDialog.

    `dispose()` (or `with`) releases it; otherwise it is released when the
    wrapper is garbage collected.
    """

    __slots__ = ()
    _free = staticmethod(_C.native_file_dialog_free)

    def __init__(self, mode: FileDialogMode) -> None:
        handle = _C.native_file_dialog_create(int(mode))
        if not handle:
            raise _rt.NativeApiError("failed to create a FileDialog")
        self._adopt(handle)

    @staticmethod
    def is_supported() -> bool:
        raw = _C.native_file_dialog_is_supported()
        return raw

    def set_parent_window(self, window: _window.Window | None) -> bool:
        raw = _C.native_file_dialog_set_parent_window(
            self._handle,
            _rt.handle_of(window),
        )
        return raw

    def set_file_types(self, extensions: list[str]) -> bool:
        raw = _C.native_file_dialog_set_file_types(
            self._handle,
            _rt.str_list(extensions),
        )
        return raw

    def set_suggested_file_name(self, name: str) -> bool:
        raw = _C.native_file_dialog_set_suggested_file_name(
            self._handle,
            _rt.encode(name),
        )
        return raw

    @property
    def modality(self) -> _dialog.DialogModality:
        raw = _C.native_file_dialog_get_modality(self._handle)
        return _rt.to_enum(_dialog.DialogModality, raw)

    def set_modality(self, modality: _dialog.DialogModality) -> None:
        _C.native_file_dialog_set_modality(self._handle, int(modality))

    def open(self) -> bool:
        raw = _C.native_file_dialog_open(self._handle)
        return raw

    def close(self) -> bool:
        raw = _C.native_file_dialog_close(self._handle)
        return raw

    @property
    def result(self) -> FileDialogResult:
        raw = _C.native_file_dialog_get_result(self._handle)
        return _rt.to_enum(FileDialogResult, raw)

    @property
    def paths(self) -> list[str]:
        raw = _C.native_file_dialog_get_paths(self._handle)
        return _rt.take_str_list(raw)

    @property
    def last_error(self) -> str:
        raw = _C.native_file_dialog_get_last_error(self._handle)
        return _rt.take_str(raw)
