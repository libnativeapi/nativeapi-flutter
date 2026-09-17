# window_drag_areas_example

Custom window chrome with the two drag widgets of `nativeapi`:

- `DragToMoveArea` — the coloured bar moves the window; a double click maximizes
  and restores it.
- `DragToResizeArea` — the tinted frame is eight native resize handles (four
  edges, four corners). They are inset from the window edge on purpose, so it is
  clear the widget does the resizing, not the native frame. The button switches
  `enableResizeEdges` between all handles and right/bottom only.

The native title bar and window buttons are hidden, the minimum size is
480 × 320.

```bash
flutter run -d macos   # or windows, linux
```

The real-desktop test of this example lives in the workspace repository:
`tools/gui/flutter_window_drag_areas_test.py` (macOS) and `.ps1` (Windows). It
presses in the middle of the handle bands, so keep `kResizeEdgeSize` and
`kResizeEdgeInset` in `lib/main.dart` in sync with it.
