# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from tray_icon.h."""

from __future__ import annotations

import enum
from collections.abc import Callable
from dataclasses import dataclass

from . import _capi as _C
from . import _runtime as _rt
from . import geometry as _geometry
from . import image as _image
from . import menu as _menu

TrayIconId = int


class ContextMenuTrigger(enum.IntEnum):
    NONE = 0
    CLICKED = 1
    RIGHT_CLICKED = 2
    DOUBLE_CLICKED = 3


class TrayIconPosition(enum.IntEnum):
    LEFT = 0
    RIGHT = 1


@dataclass(frozen=True)
class TrayIconEvent:
    """Base of every TrayIconEvent; listeners receive one of its subclasses."""

    @staticmethod
    def _from_c(raw: _C.native_tray_icon_event_t) -> TrayIconEvent | None:
        if raw.type == 0:
            return TrayIconClickedEvent(raw.data.clicked.tray_icon_id)
        if raw.type == 1:
            return TrayIconRightClickedEvent(raw.data.right_clicked.tray_icon_id)
        if raw.type == 2:
            return TrayIconDoubleClickedEvent(raw.data.double_clicked.tray_icon_id)
        return None


@dataclass(frozen=True)
class TrayIconClickedEvent(TrayIconEvent):
    tray_icon_id: TrayIconId


@dataclass(frozen=True)
class TrayIconRightClickedEvent(TrayIconEvent):
    tray_icon_id: TrayIconId


@dataclass(frozen=True)
class TrayIconDoubleClickedEvent(TrayIconEvent):
    tray_icon_id: TrayIconId


class TrayIcon(_rt.NativeObject):
    """Owned reference to a native TrayIcon.

    `dispose()` (or `with`) releases it; otherwise it is released when the
    wrapper is garbage collected.
    """

    __slots__ = ()
    _free = staticmethod(_C.native_tray_icon_free)

    def __init__(self) -> None:
        handle = _C.native_tray_icon_create()
        if not handle:
            raise _rt.NativeApiError("failed to create a TrayIcon")
        self._adopt(handle)

    @classmethod
    def with_tray(cls, tray: int | None) -> TrayIcon:
        handle = _C.native_tray_icon_create_with_tray(tray)
        if not handle:
            raise _rt.NativeApiError("failed to create a TrayIcon")
        return cls._owned(handle)

    def get_id(self) -> TrayIconId:
        raw = _C.native_tray_icon_get_id(self._handle)
        return raw

    def set_icon(self, image: _image.Image | None) -> None:
        _C.native_tray_icon_set_icon(self._handle, _rt.handle_of(image))

    @property
    def icon(self) -> _image.Image | None:
        raw = _C.native_tray_icon_get_icon(self._handle)
        return _image.Image._owned(raw)

    def set_icon_template(self, is_icon_template: bool) -> None:
        _C.native_tray_icon_set_icon_template(self._handle, is_icon_template)

    @property
    def is_icon_template(self) -> bool:
        raw = _C.native_tray_icon_is_icon_template(self._handle)
        return raw

    def set_icon_size(self, size: _geometry.Size) -> None:
        _C.native_tray_icon_set_icon_size(self._handle, size._to_c())

    @property
    def icon_size(self) -> _geometry.Size:
        raw = _C.native_tray_icon_get_icon_size(self._handle)
        return _geometry.Size._from_c(raw)

    def set_icon_position(self, position: TrayIconPosition) -> None:
        _C.native_tray_icon_set_icon_position(self._handle, int(position))

    @property
    def icon_position(self) -> TrayIconPosition:
        raw = _C.native_tray_icon_get_icon_position(self._handle)
        return _rt.to_enum(TrayIconPosition, raw)

    def set_title(self, title: str | None) -> None:
        _C.native_tray_icon_set_title(self._handle, _rt.encode_optional(title))

    def get_title(self) -> str | None:
        raw = _C.native_tray_icon_get_title(self._handle)
        return _rt.take_optional_str(raw)

    def set_tooltip(self, tooltip: str | None) -> None:
        _C.native_tray_icon_set_tooltip(self._handle, _rt.encode_optional(tooltip))

    def get_tooltip(self) -> str | None:
        raw = _C.native_tray_icon_get_tooltip(self._handle)
        return _rt.take_optional_str(raw)

    def set_context_menu(self, menu: _menu.Menu | None) -> None:
        _C.native_tray_icon_set_context_menu(self._handle, _rt.handle_of(menu))

    def get_context_menu(self) -> _menu.Menu | None:
        raw = _C.native_tray_icon_get_context_menu(self._handle)
        return _menu.Menu._owned(raw)

    def set_context_menu_trigger(self, trigger: ContextMenuTrigger) -> None:
        _C.native_tray_icon_set_context_menu_trigger(self._handle, int(trigger))

    def get_context_menu_trigger(self) -> ContextMenuTrigger:
        raw = _C.native_tray_icon_get_context_menu_trigger(self._handle)
        return _rt.to_enum(ContextMenuTrigger, raw)

    def get_bounds(self) -> _geometry.Rectangle:
        raw = _C.native_tray_icon_get_bounds(self._handle)
        return _geometry.Rectangle._from_c(raw)

    def set_visible(self, visible: bool) -> bool:
        raw = _C.native_tray_icon_set_visible(self._handle, visible)
        return raw

    def is_visible(self) -> bool:
        raw = _C.native_tray_icon_is_visible(self._handle)
        return raw

    def open_context_menu(self) -> bool:
        raw = _C.native_tray_icon_open_context_menu(self._handle)
        return raw

    def close_context_menu(self) -> bool:
        raw = _C.native_tray_icon_close_context_menu(self._handle)
        return raw

    @property
    def native_object(self) -> int | None:
        """The platform object behind this handle (NSWindow*, HWND, ...)."""
        return _C.native_tray_icon_get_native_object(self._handle)

    @icon.setter
    def icon(self, value: _image.Image | None) -> None:
        self.set_icon(value)

    @icon_size.setter
    def icon_size(self, value: _geometry.Size) -> None:
        self.set_icon_size(value)

    @icon_position.setter
    def icon_position(self, value: TrayIconPosition) -> None:
        self.set_icon_position(value)

    def add_listener(self, callback: Callable[[TrayIconEvent], None]) -> int:
        """Calls `callback` with every TrayIconEvent this TrayIcon emits.

        Returns the listener id for `remove_listener()`.
        """

        def trampoline(raw, _user_data):
            event = TrayIconEvent._from_c(raw.contents)
            if event is not None:
                callback(event)

        return _rt.add_listener(
            _C.native_tray_icon_add_listener,
            _C.native_tray_icon_event_callback_t,
            trampoline,
            self._handle,
        )

    def remove_listener(self, listener_id: int) -> bool:
        """Unregisters a listener. Returns False if unknown."""
        return _rt.remove_listener(
            _C.native_tray_icon_remove_listener,
            listener_id,
            self._handle,
        )
