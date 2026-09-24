# nativeapi (Python)

Native desktop APIs — windows, tray icons, menus, displays, global shortcuts,
dialogs, preferences and secure storage — for **Python 3.10+**, on macOS,
Windows and Linux.

Pure `ctypes` over the [libnativeapi](https://github.com/libnativeapi) C ABI:
no compiled extension module, so one wheel per platform serves every Python 3
version. The typed Python layer is generated from the C++ headers of core by
`./codegen`; only `nativeapi/_library.py`, `nativeapi/_runtime.py` and the
event loop shim in `src/` are hand-written.

> **Status: prototype.** The whole API surface is generated, but it has not
> been published and the API may still change.

```python
import asyncio

from nativeapi import Application, Size, Window, WindowClosedEvent, WindowManager


async def main() -> int:
    window = Window()
    window.set_title("Hello")
    window.set_size(Size(800, 600), False)
    window.center()

    def on_event(event):
        if isinstance(event, WindowClosedEvent):
            Application.quit()

    WindowManager.add_listener(on_event)
    return await Application.run_async(window)  # asyncio keeps running


asyncio.run(main())
```

## Model

- **Objects** (`Window`, `Menu`, `TrayIcon`, …) wrap a handle. The default
  constructor is `Window()`; other constructors are class methods
  (`Preferences.with_scope("app")`). A failed creation raises
  `NativeApiError`. The reference is released by `dispose()` / `with`, or when
  the wrapper is garbage collected. Calls on a released handle fail safely.
- **Getters** without arguments are properties (`window.title`,
  `window.bounds`, `window.is_visible`); everything else is a method
  (`window.set_title(...)`).
- **Values** (`Point`, `Size`, `Rectangle`, `Color`, …) are dataclasses.
- **Enums** are `IntEnum`s (`TitleBarStyle.HIDDEN`); bit sets are `IntFlag`s
  (`ModifierKey.SHIFT | ModifierKey.ALT`).
- **Events** are frozen dataclasses, one subclass per kind, so they work
  with `match`: `case WindowMovedEvent(window_id=id, new_position=p)`.
- **Singletons** (`Application`, `WindowManager`, `DisplayManager`, …) are
  classes with static methods.

## The event loop

- `Application.run(window=None)` blocks in the platform loop and returns the
  exit code. Listeners run on the main thread in between. Ctrl+C terminates
  the process.
- `await Application.run_async(window=None)` pumps the platform loop from the
  running asyncio loop instead, so tasks, timers and I/O keep running while
  windows are up. It resolves with the exit code once `Application.quit(code)`
  is called. An exception raised in a listener goes to the asyncio loop's
  exception handler.

Both must be called on the main thread.

## Building

```bash
cd examples/python_window_example && uv run main.py   # builds the wheel, runs the example
```

For work on the binding itself, build the library in place and run from the
source tree; `nativeapi/_library.py` finds it in `build/`:

```bash
cmake -S bindings/python -B bindings/python/build && cmake --build bindings/python/build
cd bindings/python && PYTHONPATH=. uvx --with pytest pytest
```

`NATIVEAPI_LIBRARY=/path/to/libnativeapi.dylib` overrides the lookup.

## Contributing

Development happens in [nativeapi-workspace](https://github.com/libnativeapi/nativeapi-workspace), which holds every binding and the code generator and checks out the core library as a submodule:

```bash
git clone --recursive https://github.com/libnativeapi/nativeapi-workspace.git
```

Files marked `AUTO-GENERATED. DO NOT EDIT.` are generated from the C++ headers in [nativeapi](https://github.com/libnativeapi/nativeapi-core). To change the API, send a pull request there; maintainers regenerate the bindings.

- API requests and native behavior bugs → [nativeapi-core issues](https://github.com/libnativeapi/nativeapi-core/issues)
- Bugs specific to one binding → [nativeapi-workspace issues](https://github.com/libnativeapi/nativeapi-workspace/issues)
- Not sure → [nativeapi-core issues](https://github.com/libnativeapi/nativeapi-core/issues)
