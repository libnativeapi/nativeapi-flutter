# deno_window_title_bar_example

Every state a window's title bar can be in, on one screen, for testing by hand — the
`deno desktop` counterpart of `flutter_window_title_bar_example`.

- **Normal** — the platform's standard title bar.
- **Content under title bar** — `setContentUnderTitleBar(true)`: the bar keeps its window
  buttons and its height but stops drawing, and the page reaches the top edge behind
  them. macOS only; elsewhere the chip is greyed out.
- **Hidden** — `setTitleBarStyle(TitleBarStyle.Hidden)`: no title bar and no window
  buttons.

The page draws a strip of its own that is always there: drag it to move the window
(`Window.startDragging()`), double-click it to maximize, and Quit to end the app. The
panel reports `titleBarStyle`, `isContentUnderTitleBar`, `isWindowControlButtonsVisible`,
`isContentUnderTitleBarSupported()` and `contentSize` after every change —
`contentSize` is what shows that switching states keeps the frame and moves the title
bar height into or out of the content.

## Running

```bash
npm install     # at the repository root: builds the nativeapi addon
cd examples/deno_window_title_bar_example
deno task dev
```

Requires Deno 2.9+ (`deno desktop`). macOS is the platform this was checked on.
