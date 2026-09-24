# deno_detachable_window_example

Tear a panel out of the main window into a window of its own, move it around,
and dock it back — the `deno desktop` counterpart of
`flutter_detachable_window_example`.

## Running

```bash
npm install                 # at the repository root: links nativeapi and builds its addon
cd examples/deno_detachable_window_example
deno task dev               # run with hot reload
deno task build             # package dist/DetachableWindow.app
```

Requires Deno 2.9+ (`deno desktop`).

## Using it

- Drag the **Inspector** or **Stopwatch** header more than 8 px: the panel pops
  into its own window exactly where it was and follows the cursor.
- Drag a floating panel by its header over an empty slot: the slot highlights
  and the window turns translucent. Release to dock; release anywhere else and
  it keeps floating.
- **Pop out** / **Dock** do the same without a drag; closing a floating window
  docks its panel back.
- Notes, the click counter and the running stopwatch survive every move, and
  `moved k×` counts the moves.

## How it works

`deno desktop` owns the windows and web content (`Deno.BrowserWindow`, one
webview per window, `bindings` for webview → Deno calls). nativeapi supplies
what the web layer cannot:

| API | Role |
| --- | --- |
| `WindowDragSession` | Follows the mouse button globally, even after the drag's content moved to a new window; `start(window, anchor)` retargets it mid-gesture. |
| `WindowManager.getWindowAtPoint(point, excluded)` | What is under the cursor, looking through the dragged window. |
| `Window.contentBounds` / `setContentBounds` / `setOpacity` | Exact placement and the drop-target feedback. |

A webview's state cannot move between windows, so panel state lives in Deno
(`main.ts`) and every window renders it (`ui/app.js`). A `Deno.BrowserWindow` is
matched to its nativeapi `Window` by giving it a unique title for a moment.

Under `deno desktop` JavaScript does not run on the UI thread: the backend runs
the platform loop there. nativeapi detects this and runs every native call on
the UI thread, delivering events back to JS asynchronously.
