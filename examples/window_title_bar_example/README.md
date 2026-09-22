# window_title_bar_example

Every state a window's title bar can be in, on one screen, for testing by hand.

- **Normal** — the platform's standard title bar.
- **Content under title bar** — `setContentUnderTitleBar(true)`: the bar keeps its
  window buttons and its height but stops drawing, and the content reaches the
  top edge behind them. macOS only; elsewhere the chip is greyed out because
  `Window.isContentUnderTitleBarSupported()` says so, and the call returns false.
- **Hidden** — `titleBarStyle = TitleBarStyle.hidden`: no title bar and no window
  buttons, on every platform.

Because Hidden takes the close button with it, the example draws a strip of its
own that is always there: drag it to move the window, and Quit to end the
application (core has no `Window.close()` yet). The strip starts clear of the
macOS window buttons when they are over the content.

The panel reports `titleBarStyle`, `isContentUnderTitleBar`,
`isWindowControlButtonsVisible`, `isContentUnderTitleBarSupported()` and
`contentSize` after every change — `contentSize` is what shows that switching
states keeps the window's frame and moves the title bar height into or out of
the content.

`isContentUnderTitleBar` keeps its value while Hidden is on — with no title bar
there is nothing for it to do — and takes effect again on Normal. That is the
documented behaviour, not a bug the example is showing.

The window control buttons have their own chips, which is also how the ordering
rule shows: setting a style resets the buttons to what that style implies, so an
override goes after it.

```bash
flutter run -d macos   # or windows, linux
```
