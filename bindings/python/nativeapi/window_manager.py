# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from window_manager.h."""

from __future__ import annotations

from collections.abc import Callable

from . import _capi as _C
from . import _runtime as _rt
from . import geometry as _geometry
from . import window as _window


class WindowManager:
    """The process-wide WindowManager; every member is static."""

    def __init__(self) -> None:
        raise TypeError("WindowManager is a singleton; call its static methods")

    @staticmethod
    def get(id: _window.WindowId) -> _window.Window | None:
        raw = _C.native_window_manager_get(id)
        return _window.Window._owned(raw)

    @staticmethod
    def get_all() -> list[_window.Window]:
        raw = _C.native_window_manager_get_all()
        return _rt.take_handles(
            raw,
            raw.windows,
            _window.Window,
            _C.native_window_list_release,
        )

    @staticmethod
    def get_current() -> _window.Window | None:
        raw = _C.native_window_manager_get_current()
        return _window.Window._owned(raw)

    @staticmethod
    def get_window_at_point(
        point: _geometry.Point,
        excluded_window_id: _window.WindowId,
    ) -> _window.Window | None:
        raw = _C.native_window_manager_get_window_at_point(
            point._to_c(),
            excluded_window_id,
        )
        return _window.Window._owned(raw)

    @staticmethod
    def set_will_show_hook(hook: Callable[[int], None] | None) -> None:
        native_hook = _C.native_uint_callback_t()
        if hook is not None:
            native_hook = _rt.make_callback(
                _C.native_uint_callback_t,
                lambda a0, _user_data: hook(a0),
            )
        _C.native_window_manager_set_will_show_hook(
            native_hook,
            _rt.user_data(native_hook),
            _rt.release_user_data,
        )

    @staticmethod
    def set_will_hide_hook(hook: Callable[[int], None] | None) -> None:
        native_hook = _C.native_uint_callback_t()
        if hook is not None:
            native_hook = _rt.make_callback(
                _C.native_uint_callback_t,
                lambda a0, _user_data: hook(a0),
            )
        _C.native_window_manager_set_will_hide_hook(
            native_hook,
            _rt.user_data(native_hook),
            _rt.release_user_data,
        )

    @staticmethod
    def has_will_show_hook() -> bool:
        raw = _C.native_window_manager_has_will_show_hook()
        return raw

    @staticmethod
    def has_will_hide_hook() -> bool:
        raw = _C.native_window_manager_has_will_hide_hook()
        return raw

    @staticmethod
    def handle_will_show(id: _window.WindowId) -> None:
        _C.native_window_manager_handle_will_show(id)

    @staticmethod
    def handle_will_hide(id: _window.WindowId) -> None:
        _C.native_window_manager_handle_will_hide(id)

    @staticmethod
    def call_original_show(id: _window.WindowId) -> bool:
        raw = _C.native_window_manager_call_original_show(id)
        return raw

    @staticmethod
    def call_original_hide(id: _window.WindowId) -> bool:
        raw = _C.native_window_manager_call_original_hide(id)
        return raw

    @staticmethod
    def add_listener(callback: Callable[[_window.WindowEvent], None]) -> int:
        """Calls `callback` with every WindowEvent this WindowManager emits.

        Returns the listener id for `remove_listener()`.
        """

        def trampoline(raw, _user_data):
            event = _window.WindowEvent._from_c(raw.contents)
            if event is not None:
                callback(event)

        return _rt.add_listener(
            _C.native_window_manager_add_listener,
            _C.native_window_event_callback_t,
            trampoline,
        )

    @staticmethod
    def remove_listener(listener_id: int) -> bool:
        """Unregisters a listener. Returns False if unknown."""
        return _rt.remove_listener(
            _C.native_window_manager_remove_listener,
            listener_id,
        )
