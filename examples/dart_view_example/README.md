# dart_view_example

A workbench of native views driven from a plain Dart program: no Flutter, just
`dart run`. Everything on screen is a platform control (AppKit on macOS, Win32
on Windows, GTK 3 on Linux) created through `package:nativeapi`.

```bash
dart run bin/main.dart
```

## What it shows

The main window, **Native Views Workbench**, is one `Column` of nested `Row`s
and `Column`s:

- **Header**: an `ImageView` whose avatar is painted in Dart and encoded to a
  PNG in memory (`lib/src/avatar.dart`), a title and subtitle, and buttons that
  repaint the avatar and cycle the accent colour through every section.
- **Sign in**: validation as you type (`TextFieldChangedEvent`), Enter moves to
  the password and submits (`TextFieldSubmittedEvent`), a masked field that
  can be revealed (`isSecure`), and a fake round trip on a Dart `Timer` during
  which the form is disabled. "admin" is locked; passwords need 6 characters.
- **Tasks**: rows added, reordered (`removeSubview` + `insertSubview`) and
  removed at run time, each with buttons of its own, an empty state that is
  hidden and shown (`isVisible`), and a limit that disables the input.
- **Layout playground**: four boxes with flex 0, 1, 2 and 0 in a stage whose
  layout (row / column), alignment, spacing and padding the buttons change.
  "Hide B" shows that a hidden view takes no space, "Shuffle" reorders the
  boxes, and the line underneath reads back the frames the layout computed.
- **Notes**: a multi-line field with a live character budget, a read-only
  toggle (`isEditable`), and buttons that change the text from code, which
  emits no change event.

**Open inspector** opens a second window, **View Inspector**, also built from
native views. It shows the live view tree of the workbench (each view's name,
type, frame, layout, flex, state and text), and every view event in order,
newest first. Type part of a view's name (`submit`, `box`, `avatar`) and press
Enter to flash that view.

## How it runs without Flutter

`main()` hands the app to `runNativeApp()`:

```dart
void main() => runNativeApp(app);
```

`app()` then runs in an isolate of its own on the platform's UI thread, where
every nativeapi call and event callback happens. Timers, futures and streams
keep working while the platform loop is pumped between them. On macOS that
thread is the process's first thread, which AppKit insists on. The standalone
Dart VM keeps it parked while `main()` runs elsewhere, so `runNativeApp()`
takes it over. On Windows and Linux the app gets a thread of its own. See
`runNativeApp()` in `package:nativeapi` for the details.

## Code

| File | What |
| --- | --- |
| `bin/main.dart` | `runNativeApp(app)` |
| `lib/view_example.dart` | the workbench window: header, two columns of sections, footer, window events, autoplay |
| `lib/src/ui.dart` | builders (`row`, `column`, `label`, `button`, `field`, `section`) and the registry that names every view |
| `lib/src/sign_in.dart`, `tasks.dart`, `playground.dart`, `notes.dart` | the sections |
| `lib/src/inspector.dart` | the inspector window and `describeTree()` |
| `lib/src/event_log.dart` | the event log both windows share |
| `lib/src/theme.dart`, `avatar.dart` | accent colours, and the PNG painter |

## Autoplay

`VIEW_EXAMPLE_AUTOPLAY=1` walks through the workbench on its own: it adds and
reorders tasks, opens the inspector, signs in, changes the playground and
cycles the accent. It runs what the buttons run, so it suits a demo recording
or a check that needs no synthetic input. `VIEW_EXAMPLE_AUTOPLAY=exit` does
the same, then prints the view tree and the event log and quits through
`Application.instance.quit()`:

```bash
VIEW_EXAMPLE_AUTOPLAY=exit dart run bin/main.dart
```
