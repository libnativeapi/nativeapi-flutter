"""Headless checks of the library and the generated layer: value
conversions, owned strings, handle lifetime. Nothing here needs a window
server."""

import enum

import pytest

import nativeapi
from nativeapi import (
    Color,
    KeyboardAccelerator,
    ModifierKey,
    NativeObject,
    Preferences,
    Size,
    TitleBarStyle,
    Window,
    WindowEvent,
    WindowMovedEvent,
)


def test_every_export_resolves():
    for name in nativeapi.__all__:
        assert getattr(nativeapi, name) is not None, name


def test_structs_round_trip_through_the_c_abi():
    assert Color.from_hex("#ff8000") == Color(255, 128, 0, 255)
    assert Color.from_rgba(1, 2, 3, 4).to_rgba() == 0x01020304
    assert Color.RED == Color(255, 0, 0, 255)
    assert Size(width=3) == Size(3.0, 0.0)


def test_owned_strings_in_structs():
    accelerator = KeyboardAccelerator(ModifierKey.SHIFT, "A")
    assert accelerator.to_string() == "Shift+A"
    assert not accelerator.is_empty()


def test_enums():
    assert issubclass(TitleBarStyle, enum.IntEnum)
    assert TitleBarStyle.HIDDEN == 1
    # Bit flags combine.
    assert issubclass(ModifierKey, enum.IntFlag)
    assert ModifierKey.SHIFT | ModifierKey.ALT == 5


def test_events_are_dataclasses():
    assert issubclass(WindowMovedEvent, WindowEvent)
    assert {"window_id", "new_position"} <= WindowMovedEvent.__dataclass_fields__.keys()


def test_argument_type_errors_raise_instead_of_crashing():
    with pytest.raises(TypeError):
        Color.from_hex(42)  # type: ignore[arg-type]


def test_owned_handles_are_released_exactly_once():
    preferences = Preferences.with_scope("nativeapi-python-smoke-test")
    assert isinstance(preferences, NativeObject)
    assert preferences.native_handle > 0
    preferences.set("greeting", "héllo")
    assert preferences.get("greeting", "") == "héllo"
    preferences.remove("greeting")
    preferences.dispose()
    assert preferences.native_handle == 0
    preferences.dispose()


def test_handles_work_as_context_managers():
    with Preferences.with_scope("nativeapi-python-smoke-test") as preferences:
        assert preferences.native_handle > 0
    assert preferences.native_handle == 0


def test_singletons_and_classes_without_constructors():
    with pytest.raises(TypeError):
        nativeapi.Application()
    assert callable(Window.with_native_window)


def test_getter_properties_with_a_setter_are_writable():
    item = nativeapi.MenuItem.with_label_and_type("Open", nativeapi.MenuItemType.NORMAL)
    item.label = "Open File"
    assert item.label == "Open File"
    item.set_label("Close")  # the method stays
    assert item.label == "Close"
    # A setter needing more than the value (SetSize(size, animate)) is not one.
    assert Window.size.fset is None
