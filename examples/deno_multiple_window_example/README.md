# deno_multiple_window_example

Three windows laid out on the primary display by nativeapi — the `deno desktop`
counterpart of `flutter_multiple_window_example`. `WindowManager.setWillShowHook`
catches each window just before it is shown, sizes and positions it against
`Display.workArea`, and lets the show through with `callOriginalShow`.

The primary window takes the top row (60% of the work area, full width); the secondary
and tertiary windows share the bottom row. Each window's button opens the next one;
hiding a window and showing it again goes through the hooks again. Every window lists
what the hooks saw.

A will-show hook *replaces* the platform's show: a window whose hook does not call
`WindowManager.callOriginalShow(windowId)` never appears. The window `deno desktop`
opens at startup is on screen before the hook is installed, so the primary window is
opened anew.

## Running

```bash
npm install     # at the repository root: builds the nativeapi addon
cd examples/deno_multiple_window_example
deno task dev
```

Requires Deno 2.9+ (`deno desktop`). macOS is the platform this was checked on.
