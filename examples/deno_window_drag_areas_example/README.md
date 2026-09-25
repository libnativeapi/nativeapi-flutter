# deno_window_drag_areas_example

Custom window chrome drawn by the page — the `deno desktop` counterpart of
`flutter_window_drag_areas_example`:

- the coloured bar moves the window (`Window.startDragging()`); a double click
  maximizes and restores it;
- the tinted frame is eight resize handles (four edges, four corners) that hand the
  gesture to `Window.startResizing(edge)`. They are inset from the window edge on
  purpose, so it is clear the page does the resizing, not the native frame. The button
  switches between all handles and right/bottom only.

The native title bar and window buttons are hidden; the minimum size is 480 × 320.

## Running

```bash
npm install     # at the repository root: builds the nativeapi addon
cd examples/deno_window_drag_areas_example
deno task dev
```

Requires Deno 2.9+ (`deno desktop`). macOS is the platform this was checked on.
