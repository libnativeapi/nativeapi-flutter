# AUTO-GENERATED. DO NOT EDIT.
# Any manual changes WILL BE LOST when this file is regenerated.
"""Generated from image.h."""

from __future__ import annotations

from . import _capi as _C
from . import _runtime as _rt
from . import geometry as _geometry


class Image(_rt.NativeObject):
    """Owned reference to a native Image.

    `dispose()` (or `with`) releases it; otherwise it is released when the
    wrapper is garbage collected.
    """

    __slots__ = ()
    _free = staticmethod(_C.native_image_free)

    @staticmethod
    def from_file(file_path: str) -> Image | None:
        raw = _C.native_image_from_file(_rt.encode(file_path))
        return Image._owned(raw)

    @staticmethod
    def from_base64(base64_data: str) -> Image | None:
        raw = _C.native_image_from_base64(_rt.encode(base64_data))
        return Image._owned(raw)

    @property
    def size(self) -> _geometry.Size:
        raw = _C.native_image_get_size(self._handle)
        return _geometry.Size._from_c(raw)

    @property
    def format(self) -> str:
        raw = _C.native_image_get_format(self._handle)
        return _rt.take_str(raw)

    def to_base64(self) -> str:
        raw = _C.native_image_to_base64(self._handle)
        return _rt.take_str(raw)

    def save_to_file(self, file_path: str) -> bool:
        raw = _C.native_image_save_to_file(self._handle, _rt.encode(file_path))
        return raw

    @property
    def native_object(self) -> int | None:
        """The platform object behind this handle (NSWindow*, HWND, ...)."""
        return _C.native_image_get_native_object(self._handle)
