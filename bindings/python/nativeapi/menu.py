# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from menu.h."""

from __future__ import annotations

import enum
from collections.abc import Callable
from dataclasses import dataclass

from . import _capi as _C
from . import _runtime as _rt
from . import image as _image
from . import keyboard as _keyboard
from . import placement as _placement
from . import positioning_strategy as _positioning_strategy

MenuId = int

MenuItemId = int


class MenuBackend(enum.IntEnum):
    NATIVE = 0
    WIN_UI3 = 1


class MenuItemType(enum.IntEnum):
    NORMAL = 0
    CHECKBOX = 1
    RADIO = 2
    SEPARATOR = 3
    SUBMENU = 4


class MenuItemState(enum.IntEnum):
    UNCHECKED = 0
    CHECKED = 1
    MIXED = 2


@dataclass(frozen=True)
class MenuEvent:
    """Base of every MenuEvent; listeners receive one of its subclasses."""

    @staticmethod
    def _from_c(raw: _C.native_menu_event_t) -> MenuEvent | None:
        if raw.type == 0:
            return MenuOpenedEvent(raw.data.opened.menu_id)
        if raw.type == 1:
            return MenuClosedEvent(raw.data.closed.menu_id)
        if raw.type == 2:
            return MenuItemClickedEvent(raw.data.item_clicked.item_id)
        if raw.type == 3:
            return MenuItemSubmenuOpenedEvent(raw.data.item_submenu_opened.item_id)
        if raw.type == 4:
            return MenuItemSubmenuClosedEvent(raw.data.item_submenu_closed.item_id)
        return None


@dataclass(frozen=True)
class MenuOpenedEvent(MenuEvent):
    menu_id: MenuId


@dataclass(frozen=True)
class MenuClosedEvent(MenuEvent):
    menu_id: MenuId


@dataclass(frozen=True)
class MenuItemClickedEvent(MenuEvent):
    item_id: MenuItemId


@dataclass(frozen=True)
class MenuItemSubmenuOpenedEvent(MenuEvent):
    item_id: MenuItemId


@dataclass(frozen=True)
class MenuItemSubmenuClosedEvent(MenuEvent):
    item_id: MenuItemId


class MenuItem(_rt.NativeObject):
    """Owned reference to a native MenuItem.

    `dispose()` (or `with`) releases it; otherwise it is released when the
    wrapper is garbage collected.
    """

    __slots__ = ()
    _free = staticmethod(_C.native_menu_item_free)

    @classmethod
    def with_label_and_type(cls, label: str, type: MenuItemType) -> MenuItem:
        handle = _C.native_menu_item_create_with_label_and_type(
            _rt.encode(label),
            int(type),
        )
        if not handle:
            raise _rt.NativeApiError("failed to create a MenuItem")
        return cls._owned(handle)

    @classmethod
    def with_native_item(cls, native_item: int | None) -> MenuItem:
        handle = _C.native_menu_item_create_with_native_item(native_item)
        if not handle:
            raise _rt.NativeApiError("failed to create a MenuItem")
        return cls._owned(handle)

    @property
    def id(self) -> MenuItemId:
        raw = _C.native_menu_item_get_id(self._handle)
        return raw

    @property
    def type(self) -> MenuItemType:
        raw = _C.native_menu_item_get_type(self._handle)
        return _rt.to_enum(MenuItemType, raw)

    def set_label(self, label: str | None) -> None:
        _C.native_menu_item_set_label(self._handle, _rt.encode_optional(label))

    @property
    def label(self) -> str | None:
        raw = _C.native_menu_item_get_label(self._handle)
        return _rt.take_optional_str(raw)

    def set_icon(self, image: _image.Image | None) -> None:
        _C.native_menu_item_set_icon(self._handle, _rt.handle_of(image))

    @property
    def icon(self) -> _image.Image | None:
        raw = _C.native_menu_item_get_icon(self._handle)
        return _image.Image._owned(raw)

    def set_tooltip(self, tooltip: str | None) -> None:
        _C.native_menu_item_set_tooltip(self._handle, _rt.encode_optional(tooltip))

    @property
    def tooltip(self) -> str | None:
        raw = _C.native_menu_item_get_tooltip(self._handle)
        return _rt.take_optional_str(raw)

    def set_accelerator(
        self,
        accelerator: _keyboard.KeyboardAccelerator | None,
    ) -> None:
        _C.native_menu_item_set_accelerator(
            self._handle,
            None if accelerator is None else _rt.byref(accelerator._to_c()),
        )

    @property
    def accelerator(self) -> _keyboard.KeyboardAccelerator:
        raw = _C.native_menu_item_get_accelerator(self._handle)
        value = _keyboard.KeyboardAccelerator._from_c(raw)
        _C.native_keyboard_accelerator_free(_rt.byref(raw))
        return value

    def set_enabled(self, enabled: bool) -> None:
        _C.native_menu_item_set_enabled(self._handle, enabled)

    @property
    def is_enabled(self) -> bool:
        raw = _C.native_menu_item_is_enabled(self._handle)
        return raw

    def set_state(self, state: MenuItemState) -> None:
        _C.native_menu_item_set_state(self._handle, int(state))

    @property
    def state(self) -> MenuItemState:
        raw = _C.native_menu_item_get_state(self._handle)
        return _rt.to_enum(MenuItemState, raw)

    def set_radio_group(self, group_id: int) -> None:
        _C.native_menu_item_set_radio_group(self._handle, group_id)

    @property
    def radio_group(self) -> int:
        raw = _C.native_menu_item_get_radio_group(self._handle)
        return raw

    def set_submenu(self, submenu: Menu | None) -> None:
        _C.native_menu_item_set_submenu(self._handle, _rt.handle_of(submenu))

    @property
    def submenu(self) -> Menu | None:
        raw = _C.native_menu_item_get_submenu(self._handle)
        return Menu._owned(raw)

    @property
    def native_object(self) -> int | None:
        """The platform object behind this handle (NSWindow*, HWND, ...)."""
        return _C.native_menu_item_get_native_object(self._handle)

    def add_listener(self, callback: Callable[[MenuEvent], None]) -> int:
        """Calls `callback` with every MenuEvent this MenuItem emits.

        Returns the listener id for `remove_listener()`.
        """

        def trampoline(raw, _user_data):
            event = MenuEvent._from_c(raw.contents)
            if event is not None:
                callback(event)

        return _rt.add_listener(
            _C.native_menu_item_add_listener,
            _C.native_menu_event_callback_t,
            trampoline,
            self._handle,
        )

    def remove_listener(self, listener_id: int) -> bool:
        """Unregisters a listener. Returns False if unknown."""
        return _rt.remove_listener(
            _C.native_menu_item_remove_listener,
            listener_id,
            self._handle,
        )


class Menu(_rt.NativeObject):
    """Owned reference to a native Menu.

    `dispose()` (or `with`) releases it; otherwise it is released when the
    wrapper is garbage collected.
    """

    __slots__ = ()
    _free = staticmethod(_C.native_menu_free)

    def __init__(self) -> None:
        handle = _C.native_menu_create()
        if not handle:
            raise _rt.NativeApiError("failed to create a Menu")
        self._adopt(handle)

    @classmethod
    def with_native_menu(cls, native_menu: int | None) -> Menu:
        handle = _C.native_menu_create_with_native_menu(native_menu)
        if not handle:
            raise _rt.NativeApiError("failed to create a Menu")
        return cls._owned(handle)

    @property
    def id(self) -> MenuId:
        raw = _C.native_menu_get_id(self._handle)
        return raw

    def set_backend(self, backend: MenuBackend) -> bool:
        raw = _C.native_menu_set_backend(self._handle, int(backend))
        return raw

    @property
    def backend(self) -> MenuBackend:
        raw = _C.native_menu_get_backend(self._handle)
        return _rt.to_enum(MenuBackend, raw)

    @staticmethod
    def is_backend_supported(backend: MenuBackend) -> bool:
        raw = _C.native_menu_is_backend_supported(int(backend))
        return raw

    def add_item(self, item: MenuItem | None) -> None:
        _C.native_menu_add_item(self._handle, _rt.handle_of(item))

    def insert_item(self, index: int, item: MenuItem | None) -> None:
        _C.native_menu_insert_item(self._handle, index, _rt.handle_of(item))

    def remove_item(self, item: MenuItem | None) -> bool:
        raw = _C.native_menu_remove_item(self._handle, _rt.handle_of(item))
        return raw

    def remove_item_by_id(self, item_id: MenuItemId) -> bool:
        raw = _C.native_menu_remove_item_by_id(self._handle, item_id)
        return raw

    def remove_item_at(self, index: int) -> bool:
        raw = _C.native_menu_remove_item_at(self._handle, index)
        return raw

    def clear(self) -> None:
        _C.native_menu_clear(self._handle)

    def add_separator(self) -> None:
        _C.native_menu_add_separator(self._handle)

    def insert_separator(self, index: int) -> None:
        _C.native_menu_insert_separator(self._handle, index)

    @property
    def item_count(self) -> int:
        raw = _C.native_menu_get_item_count(self._handle)
        return raw

    def get_item_at(self, index: int) -> MenuItem | None:
        raw = _C.native_menu_get_item_at(self._handle, index)
        return MenuItem._owned(raw)

    def get_item_by_id(self, item_id: MenuItemId) -> MenuItem | None:
        raw = _C.native_menu_get_item_by_id(self._handle, item_id)
        return MenuItem._owned(raw)

    @property
    def all_items(self) -> list[MenuItem]:
        raw = _C.native_menu_get_all_items(self._handle)
        return _rt.take_handles(
            raw,
            raw.menu_items,
            MenuItem,
            _C.native_menu_item_list_release,
        )

    def open(
        self,
        strategy: _positioning_strategy.PositioningStrategy,
        placement: _placement.Placement,
    ) -> bool:
        raw = _C.native_menu_open(self._handle, strategy._handle, int(placement))
        return raw

    def close(self) -> bool:
        raw = _C.native_menu_close(self._handle)
        return raw

    @property
    def native_object(self) -> int | None:
        """The platform object behind this handle (NSWindow*, HWND, ...)."""
        return _C.native_menu_get_native_object(self._handle)

    def add_listener(self, callback: Callable[[MenuEvent], None]) -> int:
        """Calls `callback` with every MenuEvent this Menu emits.

        Returns the listener id for `remove_listener()`.
        """

        def trampoline(raw, _user_data):
            event = MenuEvent._from_c(raw.contents)
            if event is not None:
                callback(event)

        return _rt.add_listener(
            _C.native_menu_add_listener,
            _C.native_menu_event_callback_t,
            trampoline,
            self._handle,
        )

    def remove_listener(self, listener_id: int) -> bool:
        """Unregisters a listener. Returns False if unknown."""
        return _rt.remove_listener(
            _C.native_menu_remove_listener,
            listener_id,
            self._handle,
        )
