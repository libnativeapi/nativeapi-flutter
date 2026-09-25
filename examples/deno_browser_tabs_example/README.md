# deno_browser_tabs_example

Chrome-style tabs across several windows, built on nativeapi's `WindowDragSession`
and `WindowManager.getWindowAtPoint` — the `deno desktop` counterpart of
`flutter_browser_tabs_example`.

Two browser windows open, with four and two tabs.

- **Reorder**: drag a tab along its strip.
- **Tear off**: drag a tab more than 28 px above or below the strip; it becomes a new
  window of the same size with the tab under the cursor. A window's only tab takes the
  whole window along instead.
- **Merge**: drag a torn-off tab over another window's strip; it joins that strip at the
  cursor while you are still dragging, and you can keep reordering or pull it out
  again.
- **Move a window**: drag the empty part of a strip.
- `+` adds a tab; closing a window's last tab closes the window; the app quits with the
  last window.

A press starts a pointer-only `WindowDragSession`, and every step after it is driven by
the session's cursor position — after a merge, the target window's page never saw the
press. Each webview is its own page, so a tab's page state (edited address, likes,
scroll position, running timer) lives in Deno and follows the tab: `Page state #n · …
· moved between windows k×`.

The strip takes the title bar's place: on macOS under a transparent title bar with room
for the traffic lights (`setContentUnderTitleBar(true)`); elsewhere the title bar is
hidden and the strip carries its own close button.

## Running

```bash
npm install     # at the repository root: builds the nativeapi addon
cd examples/deno_browser_tabs_example
deno task dev
```

Requires Deno 2.9+ (`deno desktop`). macOS is the platform this was checked on.
