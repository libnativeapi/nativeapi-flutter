// A small to-do list: rows are views added, reordered and removed at run
// time, each with buttons of its own.

import 'package:nativeapi/nativeapi.dart';

import 'event_log.dart';
import 'theme.dart';
import 'ui.dart';

final class _Task {
  _Task(this.title);

  final String title;
  var done = false;
  late final View row;
  late final Label text;
  late final Button toggle;
  late final Button up;
}

final class TasksSection {
  static const maxTasks = 5;

  TasksSection() {
    _input = field(
      'tasks.input',
      placeholder: 'What needs doing? (Enter adds it)',
      flex: 1,
      onChanged: (_) => _refresh(),
      onSubmitted: _addFromInput,
    );
    _add = button('tasks.add', 'Add', _addFromInput);
    _list = column('tasks.list', spacing: 4);
    _empty = label(
      'tasks.empty',
      'Nothing to do. Add a task above.',
      color: muted,
      align: TextAlignment.center,
    );
    _summary = label('tasks.summary', '', color: muted, flex: 1);
    _clearDone = button('tasks.clearDone', 'Clear done', _removeDone);

    view = section(
      'tasks',
      'Tasks',
      column(
        'tasks.body',
        spacing: 8,
        children: [
          row(
            'tasks.entry',
            spacing: 8,
            children: [_input..alignment = ViewAlignment.center, _add],
          ),
          _empty,
          _list,
          row('tasks.footer', spacing: 8, children: [_summary, _clearDone]),
        ],
      ),
    );
    _summary.alignment = ViewAlignment.center;
    theme.bind((accent) {
      for (final task in _tasks) {
        _paint(task, accent);
      }
    });
    _refresh();
  }

  late final View view;
  late final TextField _input;
  late final Button _add;
  late final View _list;
  late final Label _empty;
  late final Label _summary;
  late final Button _clearDone;
  final _tasks = <_Task>[];
  var _created = 0;

  void add(String title) {
    title = title.trim();
    if (title.isEmpty || _tasks.length >= maxTasks) return;
    final task = _Task(title);
    final id = ++_created;
    task.text = label('tasks.item$id.title', title, flex: 1)
      ..alignment = ViewAlignment.center;
    task.toggle = button('tasks.item$id.toggle', 'Done', () {
      task.done = !task.done;
      eventLog.note('tasks', '${task.done ? 'done' : 'reopened'}: $title');
      _paint(task, theme.accent);
      _refresh();
    });
    task.up = button(
      'tasks.item$id.up',
      '↑',
      () => _moveUp(task),
      tooltip: 'Move up',
    );
    final remove = button(
      'tasks.item$id.remove',
      '✕',
      () => _remove(task),
      tooltip: 'Remove',
    );
    task.row = row(
      'tasks.item$id',
      spacing: 6,
      padding: symmetric(vertical: 2, horizontal: 6),
      children: [task.text, task.toggle, task.up, remove],
    );
    _tasks.add(task);
    _list.addSubview(task.row);
    _paint(task, theme.accent);
    eventLog.note('tasks', 'added: $title');
    _refresh();
  }

  void _addFromInput() {
    add(_input.text ?? '');
    _input.text = '';
    _refresh();
    _input.focus();
  }

  void _moveUp(_Task task) {
    final index = _tasks.indexOf(task);
    if (index <= 0) return;
    _tasks
      ..removeAt(index)
      ..insert(index - 1, task);
    // Reordering is remove + insert: the view keeps its state and listeners.
    _list
      ..removeSubview(task.row)
      ..insertSubview(index - 1, task.row);
    _refresh();
  }

  void _remove(_Task task) {
    _tasks.remove(task);
    _list.removeSubview(task.row);
    registry.forget(task.row);
    eventLog.note('tasks', 'removed: ${task.title}');
    _refresh();
  }

  void _removeDone() {
    for (final task in _tasks.where((task) => task.done).toList()) {
      _remove(task);
    }
  }

  void _paint(_Task task, Accent accent) {
    task.text
      ..text = task.done ? '✓ ${task.title}' : task.title
      ..textColor = task.done ? muted : transparent;
    task.toggle.text = task.done ? 'Undo' : 'Done';
    task.row.backgroundColor = task.done ? transparent : wash(accent.color, 22);
  }

  void _refresh() {
    final done = _tasks.where((task) => task.done).length;
    final full = _tasks.length >= maxTasks;
    _empty.isVisible = _tasks.isEmpty;
    _list.isVisible = _tasks.isNotEmpty;
    _add.isEnabled = !full && (_input.text ?? '').trim().isNotEmpty;
    _input.isEnabled = !full;
    _input.placeholder = full
        ? 'The list is full ($maxTasks tasks)'
        : 'What needs doing? (Enter adds it)';
    _clearDone.isEnabled = done > 0;
    _summary.text = _tasks.isEmpty
        ? ''
        : '${_tasks.length} task${_tasks.length == 1 ? '' : 's'}, $done done';
    for (final (index, task) in _tasks.indexed) {
      task.up.isEnabled = index > 0;
    }
  }
}
