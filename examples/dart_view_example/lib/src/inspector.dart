// A second window, also built from native views, that watches the first: the
// live view tree with every frame, the event log, and a finder that flashes a
// view by name.

import 'dart:async';

import 'package:nativeapi/nativeapi.dart';

import 'event_log.dart';
import 'theme.dart';
import 'ui.dart';

final class Inspector {
  Inspector._(this.window, this._target);

  final Window window;

  /// The window whose views are inspected.
  final Window _target;
  late final TextField _tree;
  late final Label _stats;
  late final TextField _log;
  late final TextField _query;
  late final Label _found;
  Timer? _refresh;
  final _flashes = <ViewId, (Timer, Color)>{};

  /// Opens the inspector next to [target]. Returns null if the window could
  /// not be created.
  static Inspector? open(Window target) {
    final window = Window.create();
    final root = window?.contentView;
    if (window == null || root == null) return null;
    final inspector = Inspector._(window, target).._build(root);

    window
      ..title = 'View Inspector'
      ..contentSize = const Size(width: 460, height: 760)
      ..minimumSize = const Size(width: 360, height: 480);
    final beside = target.bounds;
    window.position = Point(x: beside.x + beside.width + 16, y: beside.y);
    window.show();
    eventLog.addListener(inspector._schedule);
    inspector._schedule();
    return inspector;
  }

  void _build(View root) {
    root
      ..layout = ViewLayout.column
      ..padding = all(14)
      ..spacing = 8;

    _stats = label('inspector.stats', '', color: muted, flex: 1)
      ..alignment = ViewAlignment.center;
    _tree = field('inspector.tree', multiline: true, editable: false, flex: 3);
    _query = field(
      'inspector.query',
      placeholder: 'Find a view by name, e.g. "submit" or "box"',
      flex: 1,
      onChanged: (_) => _find(flash: false),
      onSubmitted: () => _find(flash: true),
    );
    _found = label(
      'inspector.found',
      'Enter flashes the first match.',
      color: muted,
      fontSize: 11,
    );
    _log = field('inspector.log', multiline: true, editable: false, flex: 2);

    final heading = label('inspector.heading', 'VIEW TREE', fontSize: 11);
    final eventsHeading = label(
      'inspector.eventsHeading',
      'EVENTS',
      fontSize: 11,
      flex: 1,
    )..alignment = ViewAlignment.center;
    theme.bind((accent) {
      heading.textColor = accent.color;
      eventsHeading.textColor = accent.color;
    });

    for (final child in [
      row(
        'inspector.header',
        spacing: 8,
        children: [
          heading..alignment = ViewAlignment.center,
          _stats,
          button('inspector.refresh', 'Refresh', _render),
        ],
      ),
      _tree,
      row(
        'inspector.finder',
        spacing: 8,
        children: [
          _query,
          button('inspector.flash', 'Flash', () => _find(flash: true)),
        ],
      ),
      _found,
      row(
        'inspector.logHeader',
        spacing: 8,
        children: [
          eventsHeading,
          button('inspector.clear', 'Clear', eventLog.clear),
        ],
      ),
      _log,
    ]) {
      root.addSubview(child);
    }
  }

  /// Re-renders soon, once per burst of changes: typing sends an event per
  /// keystroke, and a resize one per frame.
  void _schedule() {
    _refresh ??= Timer(const Duration(milliseconds: 120), () {
      _refresh = null;
      _render();
    });
  }

  void refreshSoon() => _schedule();

  void close() {
    eventLog.removeListener(_schedule);
    _refresh?.cancel();
    for (final (timer, _) in _flashes.values) {
      timer.cancel();
    }
    window.hide();
  }

  void _render() {
    final root = _target.contentView;
    if (root == null) return;
    final tree = describeTree(root);
    _tree.text = tree.lines.join('\n');
    _stats.text = '${tree.count} views, ${tree.depth} levels deep';
    _log.text = eventLog.entries.reversed.join('\n');
  }

  View? _find({required bool flash}) {
    final view = registry.find(_query.text ?? '');
    if (view == null) {
      _found.text = (_query.text ?? '').trim().isEmpty
          ? 'Enter flashes the first match.'
          : 'No view matches.';
      return null;
    }
    _found.text = 'Match: ${registry.nameOf(view.id)}';
    if (flash) _flash(view);
    return view;
  }

  /// Paints [view] yellow for a moment, then puts its own colour back.
  void _flash(View view) {
    final id = view.id;
    final previous = _flashes.remove(id);
    previous?.$1.cancel();
    final original = previous?.$2 ?? view.backgroundColor;
    view.backgroundColor = highlight;
    eventLog.note('inspector', 'flashed ${registry.nameOf(id)}');
    _flashes[id] = (
      Timer(const Duration(milliseconds: 900), () {
        _flashes.remove(id);
        view.backgroundColor = original;
      }),
      original,
    );
  }
}

/// One line per view under [root], indented by depth, with how many views
/// there are and how deep the tree goes.
({List<String> lines, int count, int depth}) describeTree(View root) {
  final lines = <String>[];
  var count = 0, deepest = 0;
  void walk(View view, int depth) {
    count++;
    if (depth > deepest) deepest = depth;
    lines.add('${'  ' * depth}${_describe(view)}');
    for (final child in view.subviews) {
      walk(child, depth + 1);
    }
  }

  walk(root, 0);
  return (lines: lines, count: count, depth: deepest);
}

/// Name, type, frame, layout, flex, state and text of one view.
String _describe(View view) {
  final id = view.id;
  final known = registry.viewOf(id);
  final kind = switch (known) {
    Label() => 'Label',
    Button() => 'Button',
    TextField() => 'TextField',
    ImageView() => 'ImageView',
    _ => 'View',
  };
  final name = known == null && view.parent == null
      ? 'root'
      : registry.nameOf(id);
  final f = view.frame;
  final parts = <String>[
    '$name  $kind',
    '${f.x.round()},${f.y.round()} ${f.width.round()}×${f.height.round()}',
  ];
  if (view.subviewCount > 0 && view.layout != ViewLayout.absolute) {
    parts.add('${view.layout.name} gap ${view.spacing.round()}');
  }
  if (view.flex > 0) parts.add('flex ${view.flex.round()}');
  if (!view.isVisible) parts.add('hidden');
  if (!view.isEnabled) parts.add('disabled');
  if (view.isFocused) parts.add('focused');
  final text = switch (known) {
    Label(:final text) || Button(:final text) => text,
    TextField(:final text, :final isSecure) =>
      isSecure && (text ?? '').isNotEmpty ? '••••' : text,
    _ => null,
  };
  if (text != null && text.isNotEmpty) {
    final line = text.replaceAll('\n', '⏎');
    parts.add('"${line.length > 24 ? '${line.substring(0, 23)}…' : line}"');
  }
  return parts.join('  ·  ');
}
