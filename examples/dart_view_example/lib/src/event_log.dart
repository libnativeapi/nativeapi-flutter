// Everything that happens in the workbench, in order: view events as the
// native side reports them, and notes from the example's own logic.

import 'package:nativeapi/nativeapi.dart';

import 'ui.dart';

final class LogEntry {
  LogEntry(this.source, this.message) : time = DateTime.now();

  final DateTime time;
  final String source;
  String message;
  int repeats = 1;

  @override
  String toString() {
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp =
        '${two(time.hour)}:${two(time.minute)}:${two(time.second)}.'
        '${time.millisecond.toString().padLeft(3, '0')}';
    final times = repeats > 1 ? '  ×$repeats' : '';
    return '$stamp  $source  $message$times';
  }
}

final class EventLog {
  static const capacity = 300;

  final entries = <LogEntry>[];
  final _listeners = <void Function()>[];
  var _total = 0;

  /// How many entries were ever recorded, including the ones dropped.
  int get total => _total;

  void addListener(void Function() listener) => _listeners.add(listener);

  void removeListener(void Function() listener) => _listeners.remove(listener);

  void record(ViewEvent event) {
    final source = registry.nameOf(event.viewId);
    switch (event) {
      case TextFieldChangedEvent(:final text):
        final typed = _clip(text ?? '');
        // Typing sends one event per keystroke: fold a run of them into the
        // latest text.
        final last = entries.isEmpty ? null : entries.last;
        if (last != null &&
            last.source == source &&
            last.message.startsWith('changed')) {
          last
            ..message = 'changed → "$typed"'
            ..repeats += 1;
          _total++;
          _notify();
          return;
        }
        _add(source, 'changed → "$typed"');
      case TextFieldSubmittedEvent():
        _add(source, 'submitted');
      case ButtonClickedEvent():
        _add(source, 'clicked');
      case ViewFocusedEvent():
        _add(source, 'focused');
      case ViewBlurredEvent():
        _add(source, 'blurred');
    }
  }

  void note(String source, String message) => _add(source, message);

  void clear() {
    entries.clear();
    _notify();
  }

  void _add(String source, String message) {
    entries.add(LogEntry(source, message));
    _total++;
    if (entries.length > capacity) entries.removeAt(0);
    _notify();
  }

  void _notify() {
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }

  static String _clip(String text) {
    final line = text.replaceAll('\n', '⏎');
    return line.length <= 32 ? line : '${line.substring(0, 31)}…';
  }
}

final eventLog = EventLog();
