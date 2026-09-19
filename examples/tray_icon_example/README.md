# tray_icon_example

A playground for `TrayIcon` and `TrayManager`, built to do three jobs in one small
(400 × 640) window:

- **show animated tray icons** — Flutter renders every frame and hands it to the tray;
- **accept a platform** — every API has a control, and a checklist ticks itself;
- **record a demo** — everything is one click, no keyboard needed.

It uses `package:flutter/widgets.dart` only, no component library.

```bash
flutter run -d macos   # or windows, linux
```

## The window

| Part | What it is for |
| --- | --- |
| **Tray icons** strip | several icons at once; the rest of the window acts on the selected one |
| **Live preview** | the magnified image that was *just handed to the tray* — same frame, same pixels — with frame count, measured rate, render time, dropped frames, and Pause / Step |
| **Animate** tab | a gallery of live tiles (click one and the tray plays it), rate, resolution, colour, and one-click scenes |
| **Properties** tab | one row per API; the block on top shows what the native getters return, not what was written. *Window to icon* moves the window next to the icon the way a tray popup would: below it where the tray is at the top (macOS, GNOME), above it where it is at the bottom (Windows) |
| **Checklist** tab | auto items settle from real events and return values, manual items are marked by eye; *Copy report* gives a plain-text result with the OS version |
| Event footer | the last tray or menu event in large type, over a short log of API calls |

## Animated icons

`IconAnimator` runs a timer at the chosen rate. Per frame it draws on a canvas (or
screenshots a widget), encodes a PNG, wraps it in a nativeapi `Image` and assigns
`trayIcon.icon`. A frame that is not finished when the next tick arrives counts as
dropped, so the numbers in the preview are the real cost of animating a tray icon.

- *Spinner, Pulse, Blink, Progress, Wave, Rotate* — canvas drawings over time.
- *Clock* — driven by data (the wall clock), not by a loop.
- *Any widget* — a live `Container` + `Text` widget captured through a
  `RepaintBoundary`: whatever Flutter can lay out can be a tray icon.
- Scenes pair an animation with a title that follows it (*Download*: `42%`,
  *Recording*: `00:12`); *Three icons* animates three icons together.

Windows tray icons have no title (`setTitle` is a no-op there, `getTitle` returns null),
so the title row and the title checks step aside on Windows.

macOS shows tray images as 18 pt templates, so there the colour row only changes the
preview's alpha shape and the menu bar picks the tint; resolution still matters (1x / 2x
/ 3x pixels for the same 18 pt).

## Files

| File | |
| --- | --- |
| `lib/tray_controller.dart` | every `TrayIcon` / `TrayManager` call, scenes, events, checklist wiring |
| `lib/icon_animator.dart` | the frame loop: canvas or widget → PNG → `TrayIcon.icon` |
| `lib/icon_animations.dart` | what the frames look like |
| `lib/context_menu.dart` | the tray's context menu (normal, checkbox, disabled, submenu) |
| `lib/checklist.dart` | checklist model and report |
| `lib/tabs/`, `lib/widgets/` | the UI |

## Testing and recording

The workspace repo drives this example with real mouse input:
`tools/gui/flutter_tray_icon_test.py` (asserts on the frame counters, the read-back
state and the `[checklist]` lines this app prints) and
`tools/gui/flutter_tray_icon_demo.py --record` (the demo video).
