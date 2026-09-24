# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from shortcut_manager.h."""

from __future__ import annotations

from collections.abc import Callable

from . import _capi as _C
from . import _runtime as _rt
from . import shortcut as _shortcut

ShortcutId = int


class ShortcutManager:
    """The process-wide ShortcutManager; every member is static."""

    def __init__(self) -> None:
        raise TypeError("ShortcutManager is a singleton; call its static methods")

    @staticmethod
    def is_supported() -> bool:
        raw = _C.native_shortcut_manager_is_supported()
        return raw

    @staticmethod
    def register_with_accelerator_and_callback(
        accelerator: str,
        callback: Callable[[], None],
    ) -> _shortcut.Shortcut | None:
        native_callback = _rt.retain_callback(
            _C.native_void_callback_t,
            lambda _user_data: callback(),
        )
        raw = _C.native_shortcut_manager_register_with_accelerator_and_callback(
            _rt.encode(accelerator),
            native_callback,
            None,
        )
        return _shortcut.Shortcut._owned(raw)

    @staticmethod
    def register_with_options(
        options: _shortcut.ShortcutOptions,
    ) -> _shortcut.Shortcut | None:
        raw = _C.native_shortcut_manager_register_with_options(options._to_c())
        return _shortcut.Shortcut._owned(raw)

    @staticmethod
    def unregister_with_id(id: _shortcut.ShortcutId) -> bool:
        raw = _C.native_shortcut_manager_unregister_with_id(id)
        return raw

    @staticmethod
    def unregister_with_accelerator(accelerator: str) -> bool:
        raw = _C.native_shortcut_manager_unregister_with_accelerator(
            _rt.encode(accelerator),
        )
        return raw

    @staticmethod
    def unregister_all() -> int:
        raw = _C.native_shortcut_manager_unregister_all()
        return raw

    @staticmethod
    def get_with_id(id: _shortcut.ShortcutId) -> _shortcut.Shortcut | None:
        raw = _C.native_shortcut_manager_get_with_id(id)
        return _shortcut.Shortcut._owned(raw)

    @staticmethod
    def get_with_accelerator(accelerator: str) -> _shortcut.Shortcut | None:
        raw = _C.native_shortcut_manager_get_with_accelerator(_rt.encode(accelerator))
        return _shortcut.Shortcut._owned(raw)

    @staticmethod
    def get_all() -> list[_shortcut.Shortcut]:
        raw = _C.native_shortcut_manager_get_all()
        return _rt.take_handles(
            raw,
            raw.shortcuts,
            _shortcut.Shortcut,
            _C.native_shortcut_list_release,
        )

    @staticmethod
    def get_by_scope(scope: _shortcut.ShortcutScope) -> list[_shortcut.Shortcut]:
        raw = _C.native_shortcut_manager_get_by_scope(int(scope))
        return _rt.take_handles(
            raw,
            raw.shortcuts,
            _shortcut.Shortcut,
            _C.native_shortcut_list_release,
        )

    @staticmethod
    def is_available(accelerator: str) -> bool:
        raw = _C.native_shortcut_manager_is_available(_rt.encode(accelerator))
        return raw

    @staticmethod
    def is_valid_accelerator(accelerator: str) -> bool:
        raw = _C.native_shortcut_manager_is_valid_accelerator(_rt.encode(accelerator))
        return raw

    @staticmethod
    def set_enabled(enabled: bool) -> None:
        _C.native_shortcut_manager_set_enabled(enabled)

    @staticmethod
    def is_enabled() -> bool:
        raw = _C.native_shortcut_manager_is_enabled()
        return raw

    @staticmethod
    def emit_shortcut_activated(id: _shortcut.ShortcutId, accelerator: str) -> None:
        _C.native_shortcut_manager_emit_shortcut_activated(id, _rt.encode(accelerator))

    @staticmethod
    def add_listener(callback: Callable[[_shortcut.ShortcutEvent], None]) -> int:
        """Calls `callback` with every ShortcutEvent this ShortcutManager emits.

        Returns the listener id for `remove_listener()`.
        """

        def trampoline(raw, _user_data):
            event = _shortcut.ShortcutEvent._from_c(raw.contents)
            if event is not None:
                callback(event)

        return _rt.add_listener(
            _C.native_shortcut_manager_add_listener,
            _C.native_shortcut_event_callback_t,
            trampoline,
        )

    @staticmethod
    def remove_listener(listener_id: int) -> bool:
        """Unregisters a listener. Returns False if unknown."""
        return _rt.remove_listener(
            _C.native_shortcut_manager_remove_listener,
            listener_id,
        )
