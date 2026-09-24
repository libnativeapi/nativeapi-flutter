---
name: flutter-ui-probe
description: Find where widgets are on screen in a running debug Flutter desktop app (macOS, Windows, Linux) by reading its render tree through the VM service — no hard-coded coordinates, no screenshots, works with multi-window (multi-view) apps. Use this whenever you need to know what a Flutter example is currently showing, check that a label/counter/state text is present after an action, or get the coordinates of a header, tab, or button before clicking or dragging it with synthetic input. Reach for it before guessing pixel positions or OCR-ing a screenshot.
---

# flutter-ui-probe

`scripts/uiprobe.py` asks a **debug** Flutter app for `ext.flutter.debugDumpRenderTree`
and turns it into, per view (= per window), a list of `(text, (x, y, w, h))` rects in
logical pixels relative to the view's top-left corner.

It is both the eyes of a GUI test ("is `Clicks: 3` still there after the panel moved
to another window?") and the way to aim synthetic input (see the `gui-test` skill).

## Requirements

- The app is a debug build (`flutter build <os> --debug`, or `flutter run`). Profile
  and release builds have no `debugDumpRenderTree`.
- Its stdout goes to a file. The VM service URL (`http://127.0.0.1:<port>/<token>=/`)
  is read from that log, so launch it like
  `./app > app.log 2>&1 &` (or `Start-Process -RedirectStandardOutput`).
- Python 3, standard library only.

## Use

```bash
scripts/uiprobe.py app.log            # JSON, for scripts
scripts/uiprobe.py app.log --texts    # readable, for you
scripts/uiprobe.py app.log --dump     # raw render tree, when a text is missing
```

```python
import sys; sys.path.insert(0, '<this skill>/scripts')
from uiprobe import App
views = App('app.log').views()
view = next(v for v in views if v.has('Settings'))   # identify a window by a text it shows
x, y = view.center('Save')                            # view-local logical pixels
view.find('Like', prefix=True)                        # rect of the first text starting with…
```

Until the app has printed its VM service URL, the CLI prints `{"error": …}` and
`App.vm_url()` returns `None` — poll until it appears (a cold debug start takes a few
seconds; allow 30–40 s on a slow Windows machine).

## From view coordinates to the screen

A view rect is relative to the window's **content area**, in logical pixels:

- macOS: `screen = window frame origin + (frame height − view height) + point`
  — the content sits at the bottom of the frame, below the title bar; points are
  logical already.
- Windows: `screen = client origin + point × (dpi / 96)` — physical pixels.

`gui-test`'s helpers (`to_screen` / `ToScreen`) do this for you.

## Things that will trip you up

- **View identity is stable, window order is not.** `View.name` (`RenderView#6c9d9`)
  keeps its value while the window lives, so remember names, not list indexes, across
  probes. New windows show up as new names.
- **Re-probe after every action that changes layout.** Rects are a snapshot; after a
  tear-off, a dock, or a tab move the old coordinates are wrong, and sometimes the
  text now lives in a different view.
- **The same text can occur more than once** (a tab title in the strip and as the page
  heading). `find`/`center` return the first; filter `view.texts` yourself when it
  matters (e.g. `y < 40` for "the one in the tab strip").
- **Only text is reported.** To hit an icon or an empty drop zone, aim relative to a
  nearby text or use a fraction of the view size (`view.size`).
- Offsets come from `parentData` (`offset=` / `layoutOffset=`). Scroll offsets and
  transforms are *not* applied: text inside a scrolled list or a `Transform` is
  reported at its unscrolled position. Prefer targets outside scrollables, and check
  with `--dump` when a number looks off.
- The parser was written against the Flutter main-channel multi-window API (several
  render views in one isolate). It also works for a single-view app.
