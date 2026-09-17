# drag_drop_example

Drag and drop between the window and other applications, with the two drag and
drop widgets of `nativeapi`:

- `DropRegion` — the left panel. Drop files (from Finder / Explorer / a file
  manager) or text (from an editor) on it; it highlights while a drag is over it
  and lists what was dropped.
- `DragOutArea` — the two cards on the right. Drag the note into a file manager
  to copy it there, or the text into an editor. Both can also be dropped on the
  left panel. "Last drag" shows what the target did (`copy`, or `none` when
  nothing was dropped).

```bash
flutter run -d macos   # or windows, linux
```

The real-desktop test of this example lives in the workspace repository:
`tools/gui/flutter_drag_drop_test.py` (macOS). It finds the panels by their
texts, so keep those in `lib/main.dart` in sync with it.
