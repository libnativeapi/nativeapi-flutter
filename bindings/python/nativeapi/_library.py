"""Finds and loads the nativeapi shared library, and declares its symbols."""

from __future__ import annotations

import ctypes
import os
import sys
from pathlib import Path

_PACKAGE = Path(__file__).resolve().parent

if sys.platform == "darwin":
    _NAMES = ["libnativeapi.dylib"]
elif sys.platform == "win32":
    _NAMES = ["nativeapi.dll"]
else:
    _NAMES = ["libnativeapi.so"]


def _candidates() -> list[Path]:
    paths: list[Path] = []
    override = os.environ.get("NATIVEAPI_LIBRARY")
    if override:
        paths.append(Path(override))
    # An installed wheel ships the library next to this file; a source
    # checkout finds it in the CMake build directory.
    build = _PACKAGE.parent / "build"
    for directory in (_PACKAGE, build, build / "Release"):
        paths.extend(directory / name for name in _NAMES)
    return paths


def _load() -> ctypes.CDLL:
    candidates = _candidates()
    for path in candidates:
        if path.is_file():
            return ctypes.CDLL(str(path))
    looked = "\n  ".join(str(path) for path in candidates)
    raise ImportError(
        f"nativeapi: no native library for {sys.platform}. Install the wheel, build it "
        f"with `cmake -S {_PACKAGE.parent} -B {_PACKAGE.parent / 'build'} && "
        f"cmake --build {_PACKAGE.parent / 'build'}`, or set NATIVEAPI_LIBRARY. "
        f"Looked in:\n  {looked}"
    )


lib = _load()


def function(name: str, restype, argtypes: list):
    """The C function `name`, typed; a stub raising on call when the library
    lacks it (a symbol the platform does not implement)."""
    try:
        fn = getattr(lib, name)
    except AttributeError:

        def missing(*_args, **_kwargs):
            raise NotImplementedError(
                f"nativeapi: {name} is not available on {sys.platform}"
            )

        missing.__name__ = name
        return missing
    fn.restype = restype
    fn.argtypes = argtypes
    return fn


def constant(name: str, ctype):
    """The exported C constant `name`, read as `ctype`."""
    return ctype.in_dll(lib, name)
