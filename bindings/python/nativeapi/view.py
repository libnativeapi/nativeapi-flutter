# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from view.h."""

from __future__ import annotations

import enum
from collections.abc import Callable
from dataclasses import dataclass

from . import _capi as _C
from . import _runtime as _rt
from . import color as _color
from . import geometry as _geometry
from . import image as _image
from . import window as _window

ViewId = int


class ViewLayout(enum.IntEnum):
    ABSOLUTE = 0
    ROW = 1
    COLUMN = 2


class ViewAlignment(enum.IntEnum):
    STRETCH = 0
    START = 1
    CENTER = 2
    END = 3


class TextAlignment(enum.IntEnum):
    START = 0
    CENTER = 1
    END = 2


@dataclass(frozen=True)
class ViewEvent:
    """Base of every ViewEvent; listeners receive one of its subclasses."""

    view_id: ViewId

    @staticmethod
    def _from_c(raw: _C.native_view_event_t) -> ViewEvent | None:
        if raw.type == 0:
            return ViewFocusedEvent(raw.view_id)
        if raw.type == 1:
            return ViewBlurredEvent(raw.view_id)
        if raw.type == 2:
            return ButtonClickedEvent(raw.view_id)
        if raw.type == 3:
            return TextFieldChangedEvent(
                raw.view_id,
                _rt.decode(raw.data.text_field_changed.text),
            )
        if raw.type == 4:
            return TextFieldSubmittedEvent(raw.view_id)
        return None


@dataclass(frozen=True)
class ViewFocusedEvent(ViewEvent):
    pass


@dataclass(frozen=True)
class ViewBlurredEvent(ViewEvent):
    pass


@dataclass(frozen=True)
class ButtonClickedEvent(ViewEvent):
    pass


@dataclass(frozen=True)
class TextFieldChangedEvent(ViewEvent):
    text: str


@dataclass(frozen=True)
class TextFieldSubmittedEvent(ViewEvent):
    pass


class View(_rt.NativeObject):
    """Owned reference to a native View.

    `dispose()` (or `with`) releases it; otherwise it is released when the
    wrapper is garbage collected.
    """

    __slots__ = ()
    _free = staticmethod(_C.native_view_free)

    def __init__(self) -> None:
        handle = _C.native_view_create()
        if not handle:
            raise _rt.NativeApiError("failed to create a View")
        self._adopt(handle)

    @classmethod
    def with_native_view(cls, native_view: int | None) -> View:
        handle = _C.native_view_create_with_native_view(native_view)
        if not handle:
            raise _rt.NativeApiError("failed to create a View")
        return cls._owned(handle)

    @staticmethod
    def is_supported() -> bool:
        raw = _C.native_view_is_supported()
        return raw

    @property
    def id(self) -> ViewId:
        raw = _C.native_view_get_id(self._handle)
        return raw

    def add_subview(self, subview: View | None) -> None:
        _C.native_view_add_subview(self._handle, _rt.handle_of(subview))

    def insert_subview(self, index: int, subview: View | None) -> None:
        _C.native_view_insert_subview(self._handle, index, _rt.handle_of(subview))

    def remove_subview(self, subview: View | None) -> bool:
        raw = _C.native_view_remove_subview(self._handle, _rt.handle_of(subview))
        return raw

    def remove_subview_at(self, index: int) -> bool:
        raw = _C.native_view_remove_subview_at(self._handle, index)
        return raw

    def clear_subviews(self) -> None:
        _C.native_view_clear_subviews(self._handle)

    @property
    def subview_count(self) -> int:
        raw = _C.native_view_get_subview_count(self._handle)
        return raw

    def get_subview_at(self, index: int) -> View | None:
        raw = _C.native_view_get_subview_at(self._handle, index)
        return View._owned(raw)

    @property
    def subviews(self) -> list[View]:
        raw = _C.native_view_get_subviews(self._handle)
        return _rt.take_handles(raw, raw.views, View, _C.native_view_list_release)

    @property
    def parent(self) -> View | None:
        raw = _C.native_view_get_parent(self._handle)
        return View._owned(raw)

    @property
    def window(self) -> _window.Window | None:
        raw = _C.native_view_get_window(self._handle)
        return _window.Window._owned(raw)

    def set_frame(self, frame: _geometry.Rectangle) -> None:
        _C.native_view_set_frame(self._handle, frame._to_c())

    @property
    def frame(self) -> _geometry.Rectangle:
        raw = _C.native_view_get_frame(self._handle)
        return _geometry.Rectangle._from_c(raw)

    def set_preferred_size(self, size: _geometry.Size) -> None:
        _C.native_view_set_preferred_size(self._handle, size._to_c())

    @property
    def preferred_size(self) -> _geometry.Size:
        raw = _C.native_view_get_preferred_size(self._handle)
        return _geometry.Size._from_c(raw)

    @property
    def intrinsic_size(self) -> _geometry.Size:
        raw = _C.native_view_get_intrinsic_size(self._handle)
        return _geometry.Size._from_c(raw)

    def set_flex(self, flex: float) -> None:
        _C.native_view_set_flex(self._handle, flex)

    @property
    def flex(self) -> float:
        raw = _C.native_view_get_flex(self._handle)
        return raw

    def set_alignment(self, alignment: ViewAlignment) -> None:
        _C.native_view_set_alignment(self._handle, int(alignment))

    @property
    def alignment(self) -> ViewAlignment:
        raw = _C.native_view_get_alignment(self._handle)
        return _rt.to_enum(ViewAlignment, raw)

    def set_layout(self, layout: ViewLayout) -> None:
        _C.native_view_set_layout(self._handle, int(layout))

    @property
    def layout(self) -> ViewLayout:
        raw = _C.native_view_get_layout(self._handle)
        return _rt.to_enum(ViewLayout, raw)

    def set_spacing(self, spacing: float) -> None:
        _C.native_view_set_spacing(self._handle, spacing)

    @property
    def spacing(self) -> float:
        raw = _C.native_view_get_spacing(self._handle)
        return raw

    def set_padding(self, padding: _geometry.EdgeInsets) -> None:
        _C.native_view_set_padding(self._handle, padding._to_c())

    @property
    def padding(self) -> _geometry.EdgeInsets:
        raw = _C.native_view_get_padding(self._handle)
        return _geometry.EdgeInsets._from_c(raw)

    def set_visible(self, is_visible: bool) -> None:
        _C.native_view_set_visible(self._handle, is_visible)

    @property
    def is_visible(self) -> bool:
        raw = _C.native_view_is_visible(self._handle)
        return raw

    def set_enabled(self, is_enabled: bool) -> None:
        _C.native_view_set_enabled(self._handle, is_enabled)

    @property
    def is_enabled(self) -> bool:
        raw = _C.native_view_is_enabled(self._handle)
        return raw

    def set_background_color(self, color: _color.Color) -> None:
        _C.native_view_set_background_color(self._handle, color._to_c())

    @property
    def background_color(self) -> _color.Color:
        raw = _C.native_view_get_background_color(self._handle)
        return _color.Color._from_c(raw)

    def set_tooltip(self, tooltip: str | None) -> None:
        _C.native_view_set_tooltip(self._handle, _rt.encode_optional(tooltip))

    @property
    def tooltip(self) -> str | None:
        raw = _C.native_view_get_tooltip(self._handle)
        return _rt.take_optional_str(raw)

    def focus(self) -> None:
        _C.native_view_focus(self._handle)

    def blur(self) -> None:
        _C.native_view_blur(self._handle)

    @property
    def is_focused(self) -> bool:
        raw = _C.native_view_is_focused(self._handle)
        return raw

    @property
    def native_object(self) -> int | None:
        """The platform object behind this handle (NSWindow*, HWND, ...)."""
        return _C.native_view_get_native_object(self._handle)

    @frame.setter
    def frame(self, value: _geometry.Rectangle) -> None:
        self.set_frame(value)

    @preferred_size.setter
    def preferred_size(self, value: _geometry.Size) -> None:
        self.set_preferred_size(value)

    @flex.setter
    def flex(self, value: float) -> None:
        self.set_flex(value)

    @alignment.setter
    def alignment(self, value: ViewAlignment) -> None:
        self.set_alignment(value)

    @layout.setter
    def layout(self, value: ViewLayout) -> None:
        self.set_layout(value)

    @spacing.setter
    def spacing(self, value: float) -> None:
        self.set_spacing(value)

    @padding.setter
    def padding(self, value: _geometry.EdgeInsets) -> None:
        self.set_padding(value)

    @background_color.setter
    def background_color(self, value: _color.Color) -> None:
        self.set_background_color(value)

    @tooltip.setter
    def tooltip(self, value: str | None) -> None:
        self.set_tooltip(value)

    def add_listener(self, callback: Callable[[ViewEvent], None]) -> int:
        """Calls `callback` with every ViewEvent this View emits.

        Returns the listener id for `remove_listener()`.
        """

        def trampoline(raw, _user_data):
            event = ViewEvent._from_c(raw.contents)
            if event is not None:
                callback(event)

        return _rt.add_listener(
            _C.native_view_add_listener,
            _C.native_view_event_callback_t,
            trampoline,
            self._handle,
        )

    def remove_listener(self, listener_id: int) -> bool:
        """Unregisters a listener. Returns False if unknown."""
        return _rt.remove_listener(
            _C.native_view_remove_listener,
            listener_id,
            self._handle,
        )


class Label(View):
    """Owned reference to a native Label.

    `dispose()` (or `with`) releases it; otherwise it is released when the
    wrapper is garbage collected.
    """

    __slots__ = ()

    def __init__(self, text: str) -> None:
        handle = _C.native_label_create(_rt.encode(text))
        if not handle:
            raise _rt.NativeApiError("failed to create a Label")
        self._adopt(handle)

    def set_text(self, text: str) -> None:
        _C.native_label_set_text(self._handle, _rt.encode(text))

    @property
    def text(self) -> str:
        raw = _C.native_label_get_text(self._handle)
        return _rt.take_str(raw)

    def set_text_color(self, color: _color.Color) -> None:
        _C.native_label_set_text_color(self._handle, color._to_c())

    @property
    def text_color(self) -> _color.Color:
        raw = _C.native_label_get_text_color(self._handle)
        return _color.Color._from_c(raw)

    def set_font_size(self, size: float) -> None:
        _C.native_label_set_font_size(self._handle, size)

    @property
    def font_size(self) -> float:
        raw = _C.native_label_get_font_size(self._handle)
        return raw

    def set_text_alignment(self, alignment: TextAlignment) -> None:
        _C.native_label_set_text_alignment(self._handle, int(alignment))

    @property
    def text_alignment(self) -> TextAlignment:
        raw = _C.native_label_get_text_alignment(self._handle)
        return _rt.to_enum(TextAlignment, raw)

    @text.setter
    def text(self, value: str) -> None:
        self.set_text(value)

    @text_color.setter
    def text_color(self, value: _color.Color) -> None:
        self.set_text_color(value)

    @font_size.setter
    def font_size(self, value: float) -> None:
        self.set_font_size(value)

    @text_alignment.setter
    def text_alignment(self, value: TextAlignment) -> None:
        self.set_text_alignment(value)


class Button(View):
    """Owned reference to a native Button.

    `dispose()` (or `with`) releases it; otherwise it is released when the
    wrapper is garbage collected.
    """

    __slots__ = ()

    def __init__(self, text: str) -> None:
        handle = _C.native_button_create(_rt.encode(text))
        if not handle:
            raise _rt.NativeApiError("failed to create a Button")
        self._adopt(handle)

    def set_text(self, text: str) -> None:
        _C.native_button_set_text(self._handle, _rt.encode(text))

    @property
    def text(self) -> str:
        raw = _C.native_button_get_text(self._handle)
        return _rt.take_str(raw)

    @text.setter
    def text(self, value: str) -> None:
        self.set_text(value)


class TextField(View):
    """Owned reference to a native TextField.

    `dispose()` (or `with`) releases it; otherwise it is released when the
    wrapper is garbage collected.
    """

    __slots__ = ()

    def __init__(self, text: str) -> None:
        handle = _C.native_text_field_create(_rt.encode(text))
        if not handle:
            raise _rt.NativeApiError("failed to create a TextField")
        self._adopt(handle)

    def set_text(self, text: str) -> None:
        _C.native_text_field_set_text(self._handle, _rt.encode(text))

    @property
    def text(self) -> str:
        raw = _C.native_text_field_get_text(self._handle)
        return _rt.take_str(raw)

    def set_text_color(self, color: _color.Color) -> None:
        _C.native_text_field_set_text_color(self._handle, color._to_c())

    @property
    def text_color(self) -> _color.Color:
        raw = _C.native_text_field_get_text_color(self._handle)
        return _color.Color._from_c(raw)

    def set_font_size(self, size: float) -> None:
        _C.native_text_field_set_font_size(self._handle, size)

    @property
    def font_size(self) -> float:
        raw = _C.native_text_field_get_font_size(self._handle)
        return raw

    def set_text_alignment(self, alignment: TextAlignment) -> None:
        _C.native_text_field_set_text_alignment(self._handle, int(alignment))

    @property
    def text_alignment(self) -> TextAlignment:
        raw = _C.native_text_field_get_text_alignment(self._handle)
        return _rt.to_enum(TextAlignment, raw)

    def set_placeholder(self, placeholder: str | None) -> None:
        _C.native_text_field_set_placeholder(
            self._handle,
            _rt.encode_optional(placeholder),
        )

    @property
    def placeholder(self) -> str | None:
        raw = _C.native_text_field_get_placeholder(self._handle)
        return _rt.take_optional_str(raw)

    def set_editable(self, is_editable: bool) -> None:
        _C.native_text_field_set_editable(self._handle, is_editable)

    @property
    def is_editable(self) -> bool:
        raw = _C.native_text_field_is_editable(self._handle)
        return raw

    def set_secure(self, is_secure: bool) -> None:
        _C.native_text_field_set_secure(self._handle, is_secure)

    @property
    def is_secure(self) -> bool:
        raw = _C.native_text_field_is_secure(self._handle)
        return raw

    def set_multiline(self, is_multiline: bool) -> None:
        _C.native_text_field_set_multiline(self._handle, is_multiline)

    @property
    def is_multiline(self) -> bool:
        raw = _C.native_text_field_is_multiline(self._handle)
        return raw

    @text.setter
    def text(self, value: str) -> None:
        self.set_text(value)

    @text_color.setter
    def text_color(self, value: _color.Color) -> None:
        self.set_text_color(value)

    @font_size.setter
    def font_size(self, value: float) -> None:
        self.set_font_size(value)

    @text_alignment.setter
    def text_alignment(self, value: TextAlignment) -> None:
        self.set_text_alignment(value)

    @placeholder.setter
    def placeholder(self, value: str | None) -> None:
        self.set_placeholder(value)


class ImageView(View):
    """Owned reference to a native ImageView.

    `dispose()` (or `with`) releases it; otherwise it is released when the
    wrapper is garbage collected.
    """

    __slots__ = ()

    def __init__(self) -> None:
        handle = _C.native_image_view_create()
        if not handle:
            raise _rt.NativeApiError("failed to create a ImageView")
        self._adopt(handle)

    def set_image(self, image: _image.Image | None) -> None:
        _C.native_image_view_set_image(self._handle, _rt.handle_of(image))

    @property
    def image(self) -> _image.Image | None:
        raw = _C.native_image_view_get_image(self._handle)
        return _image.Image._owned(raw)

    @image.setter
    def image(self, value: _image.Image | None) -> None:
        self.set_image(value)
