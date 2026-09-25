// A multi-line field with a live character budget, and buttons that edit it
// from code (which, unlike typing, emits no TextFieldChangedEvent).

import 'package:nativeapi/nativeapi.dart';

import 'event_log.dart';
import 'ui.dart';

final class NotesSection {
  static const budget = 140;

  NotesSection() {
    _notes = field(
      'notes.text',
      placeholder: 'Anything on your mind? Enter starts a new line here.',
      multiline: true,
      size: const Size(width: 0, height: 72),
      onChanged: (_) => _count(),
    );
    _counter = label('notes.counter', '', align: TextAlignment.end, flex: 1);
    _readOnly = button('notes.readOnly', 'Lock', () {
      _notes.isEditable = !_notes.isEditable;
      _readOnly.text = _notes.isEditable ? 'Lock' : 'Unlock';
      eventLog.note('notes', _notes.isEditable ? 'editable' : 'read-only');
    }, tooltip: 'Toggle isEditable: a read-only field can still be selected');
    final shout = button('notes.shout', 'UPPER', () {
      _notes.text = (_notes.text ?? '').toUpperCase();
      _count();
    }, tooltip: 'Set the text from code');
    final stamp = button('notes.stamp', 'Timestamp', () {
      final now = DateTime.now();
      final time =
          '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}';
      final text = _notes.text ?? '';
      _notes.text = text.isEmpty ? '[$time] ' : '$text\n[$time] ';
      _count();
      _notes.focus();
    });

    view = section(
      'notes',
      'Notes',
      column(
        'notes.body',
        spacing: 8,
        children: [
          _notes,
          row(
            'notes.footer',
            spacing: 6,
            children: [_readOnly, shout, stamp, _counter],
          ),
        ],
      ),
    );
    _counter.alignment = ViewAlignment.center;
    _count();
  }

  late final View view;
  late final TextField _notes;
  late final Label _counter;
  late final Button _readOnly;

  void _count() {
    final text = _notes.text ?? '';
    final words = text
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    final left = budget - text.runes.length;
    _counter
      ..text =
          '$words word${words == 1 ? '' : 's'} · '
          '${left >= 0 ? '$left left' : '${-left} over'}'
      ..textColor = left < 0
          ? danger
          : left < 20
          ? const Color(r: 230, g: 140, b: 0, a: 255)
          : muted;
  }
}
