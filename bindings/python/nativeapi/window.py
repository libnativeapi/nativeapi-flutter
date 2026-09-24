# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from window.h."""

from __future__ import annotations

import enum
from dataclasses import dataclass

from . import _capi as _C
from . import _runtime as _rt
from . import color as _color
from . import geometry as _geometry
from . import window_shadow as _window_shadow
from . import window_shape as _window_shape

WindowId = int


class TitleBarStyle(enum.IntEnum):
    NORMAL = 0
    HIDDEN = 1


class VisualEffect(enum.IntEnum):
    NONE = 0
    BLUR = 1
    ACRYLIC = 2
    MICA = 3
    MICA_ALT = 4
    HUD = 5
    POPOVER = 6
    MENU = 7


class ResizeEdge(enum.IntEnum):
    TOP = 0
    LEFT = 1
    RIGHT = 2
    BOTTOM = 3
    TOP_LEFT = 4
    TOP_RIGHT = 5
    BOTTOM_LEFT = 6
    BOTTOM_RIGHT = 7


@dataclass(frozen=True)
class WindowEvent:
    """Base of every WindowEvent; listeners receive one of its subclasses."""

    window_id: WindowId

    @staticmethod
    def _from_c(raw: _C.native_window_event_t) -> WindowEvent | None:
        if raw.type == 0:
            return WindowFocusedEvent(raw.window_id)
        if raw.type == 1:
            return WindowBlurredEvent(raw.window_id)
        if raw.type == 2:
            return WindowMinimizedEvent(raw.window_id)
        if raw.type == 3:
            return WindowMaximizedEvent(raw.window_id)
        if raw.type == 4:
            return WindowRestoredEvent(raw.window_id)
        if raw.type == 5:
            return WindowMovedEvent(
                raw.window_id,
                _geometry.Point._from_c(raw.data.moved.new_position),
            )
        if raw.type == 6:
            return WindowResizedEvent(
                raw.window_id,
                _geometry.Size._from_c(raw.data.resized.new_size),
            )
        if raw.type == 7:
            return WindowCreatedEvent(raw.window_id)
        if raw.type == 8:
            return WindowClosedEvent(raw.window_id)
        return None


@dataclass(frozen=True)
class WindowFocusedEvent(WindowEvent):
    pass


@dataclass(frozen=True)
class WindowBlurredEvent(WindowEvent):
    pass


@dataclass(frozen=True)
class WindowMinimizedEvent(WindowEvent):
    pass


@dataclass(frozen=True)
class WindowMaximizedEvent(WindowEvent):
    pass


@dataclass(frozen=True)
class WindowRestoredEvent(WindowEvent):
    pass


@dataclass(frozen=True)
class WindowMovedEvent(WindowEvent):
    new_position: _geometry.Point


@dataclass(frozen=True)
class WindowResizedEvent(WindowEvent):
    new_size: _geometry.Size


@dataclass(frozen=True)
class WindowCreatedEvent(WindowEvent):
    pass


@dataclass(frozen=True)
class WindowClosedEvent(WindowEvent):
    pass


class Window(_rt.NativeObject):
    """Owned reference to a native Window.

    `dispose()` (or `with`) releases it; otherwise it is released when the
    wrapper is garbage collected.
    """

    __slots__ = ()
    _free = staticmethod(_C.native_window_free)

    def __init__(self) -> None:
        handle = _C.native_window_create()
        if not handle:
            raise _rt.NativeApiError("failed to create a Window")
        self._adopt(handle)

    @classmethod
    def with_native_window(cls, native_window: int | None) -> Window:
        handle = _C.native_window_create_with_native_window(native_window)
        if not handle:
            raise _rt.NativeApiError("failed to create a Window")
        return cls._owned(handle)

    @property
    def id(self) -> WindowId:
        raw = _C.native_window_get_id(self._handle)
        return raw

    def focus(self) -> None:
        _C.native_window_focus(self._handle)

    def blur(self) -> None:
        _C.native_window_blur(self._handle)

    @property
    def is_focused(self) -> bool:
        raw = _C.native_window_is_focused(self._handle)
        return raw

    def show(self) -> None:
        _C.native_window_show(self._handle)

    def show_inactive(self) -> None:
        _C.native_window_show_inactive(self._handle)

    def hide(self) -> None:
        _C.native_window_hide(self._handle)

    @property
    def is_visible(self) -> bool:
        raw = _C.native_window_is_visible(self._handle)
        return raw

    def maximize(self) -> None:
        _C.native_window_maximize(self._handle)

    def unmaximize(self) -> None:
        _C.native_window_unmaximize(self._handle)

    @property
    def is_maximized(self) -> bool:
        raw = _C.native_window_is_maximized(self._handle)
        return raw

    def minimize(self) -> None:
        _C.native_window_minimize(self._handle)

    def restore(self) -> None:
        _C.native_window_restore(self._handle)

    @property
    def is_minimized(self) -> bool:
        raw = _C.native_window_is_minimized(self._handle)
        return raw

    def set_full_screen(self, is_full_screen: bool) -> None:
        _C.native_window_set_full_screen(self._handle, is_full_screen)

    @property
    def is_full_screen(self) -> bool:
        raw = _C.native_window_is_full_screen(self._handle)
        return raw

    def set_bounds(self, bounds: _geometry.Rectangle) -> None:
        _C.native_window_set_bounds(self._handle, bounds._to_c())

    @property
    def bounds(self) -> _geometry.Rectangle:
        raw = _C.native_window_get_bounds(self._handle)
        return _geometry.Rectangle._from_c(raw)

    def set_content_bounds(self, bounds: _geometry.Rectangle) -> None:
        _C.native_window_set_content_bounds(self._handle, bounds._to_c())

    @property
    def content_bounds(self) -> _geometry.Rectangle:
        raw = _C.native_window_get_content_bounds(self._handle)
        return _geometry.Rectangle._from_c(raw)

    def set_size(self, size: _geometry.Size, animate: bool) -> None:
        _C.native_window_set_size(self._handle, size._to_c(), animate)

    @property
    def size(self) -> _geometry.Size:
        raw = _C.native_window_get_size(self._handle)
        return _geometry.Size._from_c(raw)

    def set_content_size(self, size: _geometry.Size) -> None:
        _C.native_window_set_content_size(self._handle, size._to_c())

    @property
    def content_size(self) -> _geometry.Size:
        raw = _C.native_window_get_content_size(self._handle)
        return _geometry.Size._from_c(raw)

    def set_minimum_size(self, size: _geometry.Size) -> None:
        _C.native_window_set_minimum_size(self._handle, size._to_c())

    @property
    def minimum_size(self) -> _geometry.Size:
        raw = _C.native_window_get_minimum_size(self._handle)
        return _geometry.Size._from_c(raw)

    def set_maximum_size(self, size: _geometry.Size) -> None:
        _C.native_window_set_maximum_size(self._handle, size._to_c())

    @property
    def maximum_size(self) -> _geometry.Size:
        raw = _C.native_window_get_maximum_size(self._handle)
        return _geometry.Size._from_c(raw)

    def set_aspect_ratio(self, aspect_ratio: float) -> None:
        _C.native_window_set_aspect_ratio(self._handle, aspect_ratio)

    @property
    def aspect_ratio(self) -> float:
        raw = _C.native_window_get_aspect_ratio(self._handle)
        return raw

    def set_resizable(self, is_resizable: bool) -> None:
        _C.native_window_set_resizable(self._handle, is_resizable)

    @property
    def is_resizable(self) -> bool:
        raw = _C.native_window_is_resizable(self._handle)
        return raw

    def set_movable(self, is_movable: bool) -> None:
        _C.native_window_set_movable(self._handle, is_movable)

    @property
    def is_movable(self) -> bool:
        raw = _C.native_window_is_movable(self._handle)
        return raw

    def set_minimizable(self, is_minimizable: bool) -> None:
        _C.native_window_set_minimizable(self._handle, is_minimizable)

    @property
    def is_minimizable(self) -> bool:
        raw = _C.native_window_is_minimizable(self._handle)
        return raw

    def set_maximizable(self, is_maximizable: bool) -> None:
        _C.native_window_set_maximizable(self._handle, is_maximizable)

    @property
    def is_maximizable(self) -> bool:
        raw = _C.native_window_is_maximizable(self._handle)
        return raw

    def set_full_screenable(self, is_full_screenable: bool) -> None:
        _C.native_window_set_full_screenable(self._handle, is_full_screenable)

    @property
    def is_full_screenable(self) -> bool:
        raw = _C.native_window_is_full_screenable(self._handle)
        return raw

    def set_closable(self, is_closable: bool) -> None:
        _C.native_window_set_closable(self._handle, is_closable)

    @property
    def is_closable(self) -> bool:
        raw = _C.native_window_is_closable(self._handle)
        return raw

    def set_window_control_buttons_visible(self, is_visible: bool) -> None:
        _C.native_window_set_window_control_buttons_visible(self._handle, is_visible)

    @property
    def is_window_control_buttons_visible(self) -> bool:
        raw = _C.native_window_is_window_control_buttons_visible(self._handle)
        return raw

    def set_always_on_top(self, is_always_on_top: bool) -> None:
        _C.native_window_set_always_on_top(self._handle, is_always_on_top)

    @property
    def is_always_on_top(self) -> bool:
        raw = _C.native_window_is_always_on_top(self._handle)
        return raw

    def set_always_on_bottom(self, is_always_on_bottom: bool) -> None:
        _C.native_window_set_always_on_bottom(self._handle, is_always_on_bottom)

    @property
    def is_always_on_bottom(self) -> bool:
        raw = _C.native_window_is_always_on_bottom(self._handle)
        return raw

    def set_parent_window(self, parent: Window | None) -> bool:
        raw = _C.native_window_set_parent_window(self._handle, _rt.handle_of(parent))
        return raw

    @property
    def parent_window(self) -> Window | None:
        raw = _C.native_window_get_parent_window(self._handle)
        return Window._owned(raw)

    def set_non_activating(self, is_non_activating: bool) -> None:
        _C.native_window_set_non_activating(self._handle, is_non_activating)

    @property
    def is_non_activating(self) -> bool:
        raw = _C.native_window_is_non_activating(self._handle)
        return raw

    def set_position(self, point: _geometry.Point) -> None:
        _C.native_window_set_position(self._handle, point._to_c())

    @property
    def position(self) -> _geometry.Point:
        raw = _C.native_window_get_position(self._handle)
        return _geometry.Point._from_c(raw)

    def center(self) -> None:
        _C.native_window_center(self._handle)

    def set_title(self, title: str) -> None:
        _C.native_window_set_title(self._handle, _rt.encode(title))

    @property
    def title(self) -> str:
        raw = _C.native_window_get_title(self._handle)
        return _rt.take_str(raw)

    def set_title_bar_colors(
        self,
        background: _color.Color,
        foreground: _color.Color,
    ) -> bool:
        raw = _C.native_window_set_title_bar_colors(
            self._handle,
            background._to_c(),
            foreground._to_c(),
        )
        return raw

    def reset_title_bar_colors(self) -> bool:
        raw = _C.native_window_reset_title_bar_colors(self._handle)
        return raw

    def set_title_bar_style(self, style: TitleBarStyle) -> None:
        _C.native_window_set_title_bar_style(self._handle, int(style))

    @property
    def title_bar_style(self) -> TitleBarStyle:
        raw = _C.native_window_get_title_bar_style(self._handle)
        return _rt.to_enum(TitleBarStyle, raw)

    def set_content_under_title_bar(self, is_content_under_title_bar: bool) -> bool:
        raw = _C.native_window_set_content_under_title_bar(
            self._handle,
            is_content_under_title_bar,
        )
        return raw

    @property
    def is_content_under_title_bar(self) -> bool:
        raw = _C.native_window_is_content_under_title_bar(self._handle)
        return raw

    @staticmethod
    def is_content_under_title_bar_supported() -> bool:
        raw = _C.native_window_is_content_under_title_bar_supported()
        return raw

    def set_has_shadow(self, has_shadow: bool) -> None:
        _C.native_window_set_has_shadow(self._handle, has_shadow)

    @property
    def has_shadow(self) -> bool:
        raw = _C.native_window_has_shadow(self._handle)
        return raw

    def set_custom_shadow(self, shadow: _window_shadow.WindowShadow | None) -> bool:
        raw = _C.native_window_set_custom_shadow(self._handle, _rt.handle_of(shadow))
        return raw

    @property
    def custom_shadow(self) -> _window_shadow.WindowShadow | None:
        raw = _C.native_window_get_custom_shadow(self._handle)
        return _window_shadow.WindowShadow._owned(raw)

    def set_opacity(self, opacity: float) -> None:
        _C.native_window_set_opacity(self._handle, opacity)

    @property
    def opacity(self) -> float:
        raw = _C.native_window_get_opacity(self._handle)
        return raw

    def set_visual_effect(self, effect: VisualEffect) -> bool:
        raw = _C.native_window_set_visual_effect(self._handle, int(effect))
        return raw

    @property
    def visual_effect(self) -> VisualEffect:
        raw = _C.native_window_get_visual_effect(self._handle)
        return _rt.to_enum(VisualEffect, raw)

    @staticmethod
    def is_visual_effect_supported(effect: VisualEffect) -> bool:
        raw = _C.native_window_is_visual_effect_supported(int(effect))
        return raw

    def set_shape(self, shape: _window_shape.WindowShape | None) -> bool:
        raw = _C.native_window_set_shape(self._handle, _rt.handle_of(shape))
        return raw

    @property
    def is_shaped(self) -> bool:
        raw = _C.native_window_is_shaped(self._handle)
        return raw

    @staticmethod
    def is_shape_supported() -> bool:
        raw = _C.native_window_is_shape_supported()
        return raw

    def set_input_shape(self, shape: _window_shape.WindowShape | None) -> bool:
        raw = _C.native_window_set_input_shape(self._handle, _rt.handle_of(shape))
        return raw

    @property
    def is_input_shaped(self) -> bool:
        raw = _C.native_window_is_input_shaped(self._handle)
        return raw

    @staticmethod
    def is_input_shape_supported() -> bool:
        raw = _C.native_window_is_input_shape_supported()
        return raw

    def set_background_color(self, color: _color.Color) -> None:
        _C.native_window_set_background_color(self._handle, color._to_c())

    @property
    def background_color(self) -> _color.Color:
        raw = _C.native_window_get_background_color(self._handle)
        return _color.Color._from_c(raw)

    def set_visible_on_all_workspaces(self, is_visible_on_all_workspaces: bool) -> None:
        _C.native_window_set_visible_on_all_workspaces(
            self._handle,
            is_visible_on_all_workspaces,
        )

    @property
    def is_visible_on_all_workspaces(self) -> bool:
        raw = _C.native_window_is_visible_on_all_workspaces(self._handle)
        return raw

    def set_visible_in_taskbar(self, is_visible_in_taskbar: bool) -> None:
        _C.native_window_set_visible_in_taskbar(self._handle, is_visible_in_taskbar)

    @property
    def is_visible_in_taskbar(self) -> bool:
        raw = _C.native_window_is_visible_in_taskbar(self._handle)
        return raw

    def set_ignore_mouse_events(self, is_ignore_mouse_events: bool) -> None:
        _C.native_window_set_ignore_mouse_events(self._handle, is_ignore_mouse_events)

    @property
    def is_ignore_mouse_events(self) -> bool:
        raw = _C.native_window_is_ignore_mouse_events(self._handle)
        return raw

    def set_focusable(self, is_focusable: bool) -> None:
        _C.native_window_set_focusable(self._handle, is_focusable)

    @property
    def is_focusable(self) -> bool:
        raw = _C.native_window_is_focusable(self._handle)
        return raw

    def start_dragging(self) -> None:
        _C.native_window_start_dragging(self._handle)

    def start_resizing(self, edge: ResizeEdge) -> None:
        _C.native_window_start_resizing(self._handle, int(edge))

    @property
    def native_object(self) -> int | None:
        """The platform object behind this handle (NSWindow*, HWND, ...)."""
        return _C.native_window_get_native_object(self._handle)
