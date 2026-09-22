# multiple_window_example

Three windows created with Flutter's experimental multi-window API, laid out on the
primary display by nativeapi: `WindowManager.setWillShowHook` catches each window
just before it is shown, sizes and positions it against
`Display.workArea`, and then lets the show through with `callOriginalShow`.

## Running

Flutter's multi-window API is experimental. This example is written against the
**stable** channel (checked with Flutter 3.47.5). Stable does not offer
`flutter config --enable-windowing`, so `main()` turns the API on itself by setting
Flutter's internal `isWindowingEnabled` before the binding starts. The main channel
has since renamed parts of this API (`RegularWindowController` became
`WindowController`, `RegularWindow` became `Window`), so the example does not compile
there.

```bash
flutter channel stable && flutter upgrade
flutter run -d macos   # or windows, linux
```

This example is excluded from the repository's melos scripts because CI pins an
older stable release.

## Using it

The primary window takes the top row (60% of the work area, full width); the
secondary and tertiary windows share the bottom row. Each window's button opens
the next one.

A will-show hook *replaces* the platform's show: a window whose hook does not call
`WindowManager.instance.callOriginalShow(windowId)` never appears.
