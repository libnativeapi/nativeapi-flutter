// Small builders over the native views, so that the sections read as a tree,
// plus the registry that gives every view a name for the inspector and the log.

import 'package:nativeapi/nativeapi.dart';

import 'event_log.dart';

// --- Palette ----------------------------------------------------------------

const transparent = Color(r: 0, g: 0, b: 0, a: 0);
const white = Color(r: 255, g: 255, b: 255, a: 255);
const muted = Color(r: 128, g: 128, b: 134, a: 255);
const success = Color(r: 36, g: 138, b: 61, a: 255);
const danger = Color(r: 204, g: 51, b: 51, a: 255);
const highlight = Color(r: 255, g: 214, b: 10, a: 160);

/// A tint of [color] light enough to sit behind text.
Color wash(Color color, [int alpha = 28]) =>
    Color(r: color.r, g: color.g, b: color.b, a: alpha);

EdgeInsets all(double value) =>
    EdgeInsets(top: value, right: value, bottom: value, left: value);

EdgeInsets symmetric({double vertical = 0, double horizontal = 0}) =>
    EdgeInsets(
      top: vertical,
      right: horizontal,
      bottom: vertical,
      left: horizontal,
    );

// --- Names ------------------------------------------------------------------

/// Every view the example creates, by id, with a human name. The tree the
/// inspector prints comes from the views themselves (`subviews`, `frame`); the
/// names and the concrete types come from here.
final class ViewRegistry {
  final _entries = <ViewId, (String, View)>{};
  final _actions = <String, void Function()>{};

  T add<T extends View>(T view, String name) {
    _entries[view.id] = (name, view);
    return view;
  }

  String nameOf(ViewId id) => _entries[id]?.$1 ?? '#$id';

  View? viewOf(ViewId id) => _entries[id]?.$2;

  /// The first view whose name contains [query], case-insensitively.
  View? find(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final (name, view) in _entries.values) {
      if (name.toLowerCase().contains(needle)) return view;
    }
    return null;
  }

  /// Runs what clicking the button named [name] runs, for autoplay. Returns
  /// false if there is no such button or it is disabled.
  bool press(String name) {
    final action = _actions[name];
    final enabled = _entries.values.any(
      (entry) => entry.$1 == name && entry.$2.isEnabled,
    );
    if (action == null || !enabled) return false;
    action();
    return true;
  }

  /// Drops [view] and everything under it, once it has left the tree for good.
  void forget(View view) {
    for (final child in view.subviews) {
      forget(child);
    }
    final entry = _entries.remove(view.id);
    if (entry != null) _actions.remove(entry.$1);
  }
}

final registry = ViewRegistry();

// --- Builders ---------------------------------------------------------------

View container(
  String name, {
  ViewLayout layout = ViewLayout.column,
  double spacing = 0,
  EdgeInsets? padding,
  Color? background,
  double flex = 0,
  Size? size,
  ViewAlignment? alignment,
  List<View> children = const [],
}) {
  final view = registry.add(View.create()!, name)
    ..layout = layout
    ..spacing = spacing
    ..flex = flex;
  if (padding != null) view.padding = padding;
  if (background != null) view.backgroundColor = background;
  if (size != null) view.preferredSize = size;
  if (alignment != null) view.alignment = alignment;
  for (final child in children) {
    view.addSubview(child);
  }
  return view;
}

View column(
  String name, {
  double spacing = 0,
  EdgeInsets? padding,
  Color? background,
  double flex = 0,
  Size? size,
  List<View> children = const [],
}) => container(
  name,
  spacing: spacing,
  padding: padding,
  background: background,
  flex: flex,
  size: size,
  children: children,
);

View row(
  String name, {
  double spacing = 0,
  EdgeInsets? padding,
  Color? background,
  double flex = 0,
  Size? size,
  List<View> children = const [],
}) => container(
  name,
  layout: ViewLayout.row,
  spacing: spacing,
  padding: padding,
  background: background,
  flex: flex,
  size: size,
  children: children,
);

/// Empty space that takes the leftover room of a row or column.
View spacer(String name, {double flex = 1}) =>
    registry.add(View.create()!, name)..flex = flex;

Label label(
  String name,
  String text, {
  double? fontSize,
  Color? color,
  TextAlignment? align,
  double flex = 0,
  ViewAlignment? alignment,
}) {
  final view = registry.add(Label.create(text)!, name)..flex = flex;
  if (fontSize != null) view.fontSize = fontSize;
  if (color != null) view.textColor = color;
  if (align != null) view.textAlignment = align;
  if (alignment != null) view.alignment = alignment;
  return view;
}

Button button(
  String name,
  String text,
  void Function() onPressed, {
  String? tooltip,
  ViewAlignment alignment = ViewAlignment.center,
}) {
  final view = registry.add(Button.create(text)!, name)
    ..alignment = alignment
    ..tooltip = tooltip;
  listen(view, (event) {
    if (event is ButtonClickedEvent) onPressed();
  });
  registry._actions[name] = onPressed;
  return view;
}

TextField field(
  String name, {
  String text = '',
  String? placeholder,
  bool secure = false,
  bool multiline = false,
  bool editable = true,
  double flex = 0,
  Size? size,
  void Function(String text)? onChanged,
  void Function()? onSubmitted,
}) {
  final view = registry.add(TextField.create(text)!, name)
    ..placeholder = placeholder
    ..isSecure = secure
    ..isMultiline = multiline
    ..isEditable = editable
    ..flex = flex;
  if (size != null) view.preferredSize = size;
  listen(view, (event) {
    switch (event) {
      case TextFieldChangedEvent(:final text):
        onChanged?.call(text ?? '');
      case TextFieldSubmittedEvent():
        onSubmitted?.call();
      default:
    }
  });
  return view;
}

/// A titled block of the workbench: a heading over [body], on a faint tint.
View section(String name, String title, View body, {Label? heading}) {
  return column(
    name,
    spacing: 8,
    padding: all(12),
    children: [heading ?? sectionHeading(name, title), body],
  );
}

Label sectionHeading(String name, String title) =>
    label('$name.heading', title.toUpperCase(), fontSize: 11, color: muted);

/// Registers [handler] for [view]'s events, after writing each one to the log.
void listen(View view, void Function(ViewEvent event) handler) {
  view.addListener((event) {
    eventLog.record(event);
    handler(event);
  });
}
