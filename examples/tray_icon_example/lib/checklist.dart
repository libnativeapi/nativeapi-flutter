import 'dart:io';

import 'package:flutter/foundation.dart';

enum CheckStatus { open, pass, fail }

class CheckItem {
  CheckItem(this.id, this.label, {this.manual = false, this.note});

  final String id;
  final String label;

  /// Manual items need eyes on the tray; the rest tick themselves.
  final bool manual;

  /// Short platform remark shown next to the label.
  final String? note;

  CheckStatus status = CheckStatus.open;
  String detail = '';
}

/// The acceptance checklist.
///
/// Auto items are settled by the controller from real events and return
/// values; manual items are marked from the Checklist tab.
class Checklist extends ChangeNotifier {
  static const supported = 'supported';
  static const create = 'create';
  static const managed = 'managed';
  static const clicked = 'clicked';
  static const rightClicked = 'rightClicked';
  static const doubleClicked = 'doubleClicked';
  static const menuOpenClose = 'menuOpenClose';
  static const menuItems = 'menuItems';
  static const triggers = 'triggers';
  static const openMenu = 'openMenu';
  static const closeMenu = 'closeMenu';
  static const visible = 'visible';
  static const readBack = 'readBack';
  static const bounds = 'bounds';
  static const frames = 'frames';

  final List<CheckItem> items = [
    CheckItem(supported, 'TrayManager.isSupported'),
    CheckItem(create, 'TrayIcon.create returns an icon'),
    CheckItem(managed, 'TrayManager get and getAll know it'),
    CheckItem(clicked, 'Clicked event'),
    CheckItem(rightClicked, 'Right clicked event'),
    CheckItem(doubleClicked, 'Double clicked event'),
    CheckItem(menuOpenClose, 'Menu opened and closed'),
    CheckItem(menuItems, 'Menu item, checkbox, submenu'),
    CheckItem(triggers, 'All four triggers open the menu'),
    CheckItem(openMenu, 'openContextMenu returns true'),
    CheckItem(closeMenu, 'closeContextMenu closes it'),
    CheckItem(visible, 'setVisible round trip'),
    CheckItem(
      readBack,
      Platform.isWindows ? 'Tooltip reads back' : 'Title and tooltip read back',
    ),
    CheckItem(bounds, 'getBounds is not empty'),
    CheckItem(frames, '100 frames at the target rate'),
    CheckItem('m.still', 'Icon swaps: asset, drawn, base64', manual: true),
    CheckItem('m.animation', 'Tray animation matches preview', manual: true),
    CheckItem('m.three', 'Three icons animate at once', manual: true),
    if (!Platform.isWindows)
      CheckItem(
        'm.title',
        'Title next to the icon',
        manual: true,
        note: 'macOS',
      ),
    CheckItem('m.tooltip', 'Tooltip on hover', manual: true),
    CheckItem('m.hidden', 'Hidden icon leaves the tray', manual: true),
    CheckItem('m.removed', 'Removed icon leaves the tray', manual: true),
  ];

  // Partial progress of the multi-part items.
  final Map<String, Set<String>> _parts = {};

  CheckItem operator [](String id) => items.firstWhere((i) => i.id == id);

  int get passed => items.where((i) => i.status == CheckStatus.pass).length;
  int get failed => items.where((i) => i.status == CheckStatus.fail).length;

  void pass(String id, [String detail = '']) =>
      _set(id, CheckStatus.pass, detail);

  void fail(String id, String detail) => _set(id, CheckStatus.fail, detail);

  /// Updates the detail of an item that is still open.
  void note(String id, String detail) {
    final item = this[id];
    if (item.status != CheckStatus.open || item.detail == detail) return;
    item.detail = detail;
    notifyListeners();
  }

  /// Records [part] of a multi-part item; passes once [total] are in.
  void part(String id, String part, int total) {
    final parts = _parts.putIfAbsent(id, () => {})..add(part);
    if (parts.length >= total) {
      pass(id, '$total/$total');
    } else {
      note(id, '${parts.length}/$total');
    }
  }

  /// Counts an occurrence of an event item (detail becomes "×n").
  void count(String id) {
    final parts = _parts.putIfAbsent(id, () => {});
    parts.add('${parts.length}');
    _set(id, CheckStatus.pass, '×${parts.length}');
  }

  void mark(String id, CheckStatus status) {
    final item = this[id];
    _set(id, item.status == status ? CheckStatus.open : status, '');
  }

  void reset() {
    _parts.clear();
    for (final item in items) {
      item.status = CheckStatus.open;
      item.detail = '';
    }
    notifyListeners();
  }

  void _set(String id, CheckStatus status, String detail) {
    final item = this[id];
    if (item.status == status && item.detail == detail) return;
    item.status = status;
    item.detail = detail;
    // One line per change on stdout, so a GUI test can assert on the list
    // without having to read ticks off the screen.
    debugPrint('[checklist] $id ${status.name} $detail');
    notifyListeners();
  }

  String get summary {
    final open = items.length - passed - failed;
    return '$passed pass · $failed fail · $open open';
  }

  /// Plain-text report for pasting into an issue or a PR.
  String report() {
    final buffer = StringBuffer()
      ..writeln('tray_icon_example checklist')
      ..writeln(
        '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      )
      ..writeln(summary)
      ..writeln();
    for (final item in items) {
      final mark = switch (item.status) {
        CheckStatus.pass => 'PASS',
        CheckStatus.fail => 'FAIL',
        CheckStatus.open => 'open',
      };
      final kind = item.manual ? 'manual' : 'auto';
      final detail = item.detail.isEmpty ? '' : '  (${item.detail})';
      buffer.writeln('[$mark] ${item.label}  <$kind>$detail');
    }
    return buffer.toString();
  }
}
