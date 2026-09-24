# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from message_dialog.h."""

from __future__ import annotations

import enum

from . import _capi as _C
from . import _runtime as _rt
from . import dialog as _dialog
from . import window as _window


class MessageDialogResult(enum.IntEnum):
    NONE = 0
    PRIMARY = 1
    SECONDARY = 2
    CLOSE = 3


class MessageDialog(_rt.NativeObject):
    """Owned reference to a native MessageDialog.

    `dispose()` (or `with`) releases it; otherwise it is released when the
    wrapper is garbage collected.
    """

    __slots__ = ()
    _free = staticmethod(_C.native_message_dialog_free)

    def __init__(self, title: str, message: str) -> None:
        handle = _C.native_message_dialog_create(_rt.encode(title), _rt.encode(message))
        if not handle:
            raise _rt.NativeApiError("failed to create a MessageDialog")
        self._adopt(handle)

    @staticmethod
    def is_extended_supported() -> bool:
        raw = _C.native_message_dialog_is_extended_supported()
        return raw

    def set_buttons(self, primary: str, secondary: str, close: str) -> bool:
        raw = _C.native_message_dialog_set_buttons(
            self._handle,
            _rt.encode(primary),
            _rt.encode(secondary),
            _rt.encode(close),
        )
        return raw

    def set_default_button(self, button: MessageDialogResult) -> bool:
        raw = _C.native_message_dialog_set_default_button(self._handle, int(button))
        return raw

    def set_parent_window(self, window: _window.Window | None) -> bool:
        raw = _C.native_message_dialog_set_parent_window(
            self._handle,
            _rt.handle_of(window),
        )
        return raw

    @property
    def result(self) -> MessageDialogResult:
        raw = _C.native_message_dialog_get_result(self._handle)
        return _rt.to_enum(MessageDialogResult, raw)

    @property
    def is_open(self) -> bool:
        raw = _C.native_message_dialog_is_open(self._handle)
        return raw

    def set_input_enabled(self, enabled: bool) -> bool:
        raw = _C.native_message_dialog_set_input_enabled(self._handle, enabled)
        return raw

    def set_input_text(self, text: str) -> bool:
        raw = _C.native_message_dialog_set_input_text(self._handle, _rt.encode(text))
        return raw

    @property
    def input_text(self) -> str:
        raw = _C.native_message_dialog_get_input_text(self._handle)
        return _rt.take_str(raw)

    def set_checkbox(self, label: str, checked: bool) -> bool:
        raw = _C.native_message_dialog_set_checkbox(
            self._handle,
            _rt.encode(label),
            checked,
        )
        return raw

    @property
    def is_checkbox_checked(self) -> bool:
        raw = _C.native_message_dialog_is_checkbox_checked(self._handle)
        return raw

    def set_progress(self, value: float) -> bool:
        raw = _C.native_message_dialog_set_progress(self._handle, value)
        return raw

    def set_title(self, title: str) -> None:
        _C.native_message_dialog_set_title(self._handle, _rt.encode(title))

    @property
    def title(self) -> str:
        raw = _C.native_message_dialog_get_title(self._handle)
        return _rt.take_str(raw)

    def set_message(self, message: str) -> None:
        _C.native_message_dialog_set_message(self._handle, _rt.encode(message))

    @property
    def message(self) -> str:
        raw = _C.native_message_dialog_get_message(self._handle)
        return _rt.take_str(raw)

    @property
    def modality(self) -> _dialog.DialogModality:
        raw = _C.native_message_dialog_get_modality(self._handle)
        return _rt.to_enum(_dialog.DialogModality, raw)

    def set_modality(self, modality: _dialog.DialogModality) -> None:
        _C.native_message_dialog_set_modality(self._handle, int(modality))

    def open(self) -> bool:
        raw = _C.native_message_dialog_open(self._handle)
        return raw

    def close(self) -> bool:
        raw = _C.native_message_dialog_close(self._handle)
        return raw
