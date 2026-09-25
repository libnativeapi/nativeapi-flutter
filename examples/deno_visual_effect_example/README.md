# deno_visual_effect_example

A window whose background is a translucent material, set with
`Window.setVisualEffect` — the `deno desktop` counterpart of
`flutter_visual_effect_example`.

- One chip per `VisualEffect`; the ones `Window.isVisualEffectSupported` rules out here
  are greyed out.
- The material only shows where the page paints nothing, so the window's webview is
  created transparent (`transparent: true`, a creation-only `BrowserWindow` option) and
  the page paints only its panel while an effect is on.
- The material runs to the top edge: `setContentUnderTitleBar(true)`.
- **Show backdrop** puts a plain red window behind this one (a nativeapi `Window`, made
  its parent), which shows which materials blur what is behind the window.

Creation-only options do not apply to the window `deno desktop` opens at startup, so
the example opens its own window and closes the startup one (`desktop.ts`).

## Known issues (macOS)

- The window is transparent, and macOS may let clicks fall through it to whatever is
  behind (see `deno_shaped_window_example`); not checked with a real mouse yet.

## Running

```bash
npm install     # at the repository root: builds the nativeapi addon
cd examples/deno_visual_effect_example
deno task dev
```

Requires Deno 2.9+ (`deno desktop`). macOS is the platform this was checked on.
