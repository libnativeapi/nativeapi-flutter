# deno_drag_drop_example

Drag and drop between the window and other applications — the `deno desktop`
counterpart of `flutter_drag_drop_example`:

- the left panel takes drops: files from Finder / Explorer / a file manager, or text
  from an editor. It highlights while a drag is over it and lists what was dropped;
- the two cards on the right drag out: the note as a file into a file manager, the text
  into an editor, or either onto the left panel. "Last drag" shows what the target did
  (`copy`, or `none` when nothing was dropped).

nativeapi's `DropTarget` lays a transparent layer over the whole window, above the
webview, so drops never reach the page (which would otherwise navigate to a dropped
file); Deno matches drop positions against the panel's rectangle. A card starts a
native drag with `DragSource.startDragging` once the pointer has moved past a few
pixels.

## Known issues (macOS)

- Drops do not reach nativeapi's `DropTarget`: the web view under its layer registers
  drag types of its own and takes them. Dragging **out** of the window starts
  (`DragSource`), but a drop on the left panel is not reported. Needs a change in
  core's drop layer.

## Running

```bash
npm install     # at the repository root: builds the nativeapi addon
cd examples/deno_drag_drop_example
deno task dev
```

Requires Deno 2.9+ (`deno desktop`). macOS is the platform this was checked on.
