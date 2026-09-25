/// A workbench of native views driven from plain Dart: see README.md.
library;

import 'dart:async';
import 'dart:io';

import 'package:nativeapi/nativeapi.dart';

import 'src/avatar.dart';
import 'src/event_log.dart';
import 'src/inspector.dart';
import 'src/notes.dart';
import 'src/playground.dart';
import 'src/sign_in.dart';
import 'src/tasks.dart';
import 'src/theme.dart';
import 'src/ui.dart';

/// Builds the workbench. Runs on the UI thread, through runNativeApp().
void app() {
  if (!View.isSupported()) {
    stderr.writeln('Native views are not supported on this platform.');
    exit(1);
  }
  final workbench = Workbench.open();
  if (workbench == null) {
    stderr.writeln('Could not create the window.');
    exit(1);
  }
  switch (Platform.environment['VIEW_EXAMPLE_AUTOPLAY']) {
    case '1':
      workbench.autoplay();
    case 'exit':
      // For checks without a screen capture: play, print, quit.
      workbench.autoplay(thenQuit: true);
  }
}

final class Workbench {
  Workbench._(this.window);

  final Window window;
  late final SignInSection _signIn;
  late final TasksSection _tasks;
  late final PlaygroundSection _playground;
  late final NotesSection _notes;
  late final ImageView _avatar;
  late final Label _subtitle;
  late final Label _status;
  late final Button _themeButton;
  late final Button _inspectorButton;
  Inspector? _inspector;
  var _avatarSeed = 0;

  static Workbench? open() {
    final window = Window.create();
    final root = window?.contentView;
    if (window == null || root == null) return null;
    final workbench = Workbench._(window).._build(root);

    window
      ..title = 'Native Views Workbench'
      ..contentSize = const Size(width: 960, height: 640)
      ..minimumSize = const Size(width: 820, height: 600);
    window.center();
    window.show();
    workbench._watchWindows();
    // The stage had no width until the window got its size.
    workbench._playground.refreshFrames();
    workbench._signIn.focus();
    eventLog.note(
      'app',
      'started on the ${View.getDefaultBackend().name} backend',
    );
    return workbench;
  }

  void _build(View root) {
    root
      ..layout = ViewLayout.column
      ..padding = all(16)
      ..spacing = 12;

    _signIn = SignInSection(
      onSignedIn: (user) => _subtitle.text = 'Signed in as $user',
      onSignedOut: () => _subtitle.text = _defaultSubtitle,
    );
    _tasks = TasksSection();
    _playground = PlaygroundSection();
    _notes = NotesSection();

    for (final child in [
      _header(),
      row(
        'columns',
        spacing: 12,
        flex: 1,
        children: [
          column(
            'columns.left',
            spacing: 12,
            flex: 1,
            children: [_signIn.view, _tasks.view, spacer('columns.left.fill')],
          ),
          column(
            'columns.right',
            spacing: 12,
            flex: 1,
            children: [
              _playground.view,
              _notes.view,
              spacer('columns.right.fill'),
            ],
          ),
        ],
      ),
      _footer(),
    ]) {
      root.addSubview(child);
    }

    // Every section sits on a tint of the accent.
    theme.bind((accent) {
      for (final section in [
        _signIn.view,
        _tasks.view,
        _playground.view,
        _notes.view,
      ]) {
        section.backgroundColor = wash(accent.color, 18);
      }
      _themeButton.text = 'Accent: ${accent.name}';
      _avatar.image = paintAvatar(hue: accent.hue, seed: _avatarSeed);
    });
    eventLog.addListener(_updateStatus);
    _updateStatus();
  }

  static const _defaultSubtitle =
      'Labels, buttons, text fields and image views, laid out in rows and '
      'columns — no Flutter.';

  View _header() {
    _avatar = registry.add(ImageView.create()!, 'header.avatar')
      ..preferredSize = const Size(width: 56, height: 56)
      ..alignment = ViewAlignment.center
      ..tooltip = 'Painted in Dart, encoded as PNG, shown by ImageView';
    final title = label('header.title', 'Native Views Workbench', fontSize: 22);
    _subtitle = label('header.subtitle', _defaultSubtitle, color: muted);
    _themeButton = button('header.accent', '', () {
      theme.next();
      eventLog.note('header', 'accent → ${theme.accent.name}');
    }, tooltip: 'Repaint everything in the next accent colour');
    final accentBar = container(
      'header.bar',
      size: const Size(width: 0, height: 3),
    );
    theme.bind((accent) {
      title.textColor = accent.color;
      accentBar.backgroundColor = accent.color;
    });
    return column(
      'header',
      spacing: 10,
      children: [
        row(
          'header.row',
          spacing: 14,
          children: [
            _avatar,
            column(
              'header.text',
              spacing: 4,
              flex: 1,
              children: [title, _subtitle],
            )..alignment = ViewAlignment.center,
            button('header.newAvatar', 'New avatar', () {
              _avatarSeed++;
              _avatar.image = paintAvatar(
                hue: theme.accent.hue,
                seed: _avatarSeed,
              );
              eventLog.note('header', 'avatar #$_avatarSeed');
            }),
            _themeButton,
          ],
        ),
        accentBar,
      ],
    );
  }

  View _footer() {
    _status = label('footer.status', '', color: muted, fontSize: 11, flex: 1)
      ..alignment = ViewAlignment.center;
    _inspectorButton = button(
      'footer.inspector',
      'Open inspector',
      toggleInspector,
      tooltip: 'A second window, also native views, that watches this one',
    );
    return row(
      'footer',
      spacing: 8,
      children: [
        _status,
        _inspectorButton,
        button('footer.quit', 'Quit', () => Application.instance.quit(0)),
      ],
    );
  }

  void _updateStatus() {
    final platform = Platform.operatingSystem;
    _status.text =
        '$platform · ${View.getDefaultBackend().name} backend · '
        '${eventLog.total} events';
  }

  void toggleInspector() {
    final open = _inspector;
    if (open != null) {
      open.close();
      _inspectorClosed();
      return;
    }
    _inspector = Inspector.open(window);
    if (_inspector != null) {
      _inspectorButton.text = 'Close inspector';
      eventLog.note('app', 'inspector opened');
    }
  }

  void _inspectorClosed() {
    _inspector = null;
    _inspectorButton.text = 'Open inspector';
    eventLog.note('app', 'inspector closed');
  }

  void _watchWindows() {
    WindowManager.instance.addListener((event) {
      switch (event) {
        case WindowClosedEvent(:final windowId) when windowId == window.id:
          Application.instance.quit(0);
        case WindowClosedEvent(:final windowId)
            when windowId == _inspector?.window.id:
          _inspectorClosed();
        case WindowResizedEvent(:final windowId) when windowId == window.id:
          // The flexible boxes and columns follow the window's size.
          _playground.refreshFrames();
          _inspector?.refreshSoon();
        default:
      }
    });
  }

  /// Walks through the workbench on its own, running what the buttons run:
  /// for a demo recording, or to check a build without synthetic input.
  void autoplay({bool thenQuit = false}) {
    void press(String name) {
      if (!registry.press(name)) eventLog.note('autoplay', 'no $name');
    }

    final steps = <(int, void Function())>[
      (700, () => _tasks.add('Write the view example')),
      (400, () => _tasks.add('Run it on macOS, Windows and Linux')),
      (400, () => _tasks.add('Record a demo')),
      (600, () => press('tasks.item1.toggle')),
      (600, () => press('tasks.item3.up')),
      (700, toggleInspector),
      (700, () => _signIn.signInAs('ada', 'lovelace')),
      (1400, () => press('playground.layout')),
      (900, () => press('playground.align')),
      (900, () => press('playground.hideB')),
      (900, () => press('playground.layout')),
      (700, () => press('playground.shuffle')),
      (700, () => press('playground.spacing')),
      (700, () => press('notes.stamp')),
      (600, () => press('header.newAvatar')),
      (800, () => press('header.accent')),
      (800, () => press('header.accent')),
    ];
    if (thenQuit) steps.add((1000, _printAndQuit));
    var at = 0;
    for (final (delay, step) in steps) {
      at += delay;
      Timer(Duration(milliseconds: at), step);
    }
  }

  void _printAndQuit() {
    final root = window.contentView;
    if (root != null) {
      final tree = describeTree(root);
      print('--- ${tree.count} views, ${tree.depth} levels deep');
      tree.lines.forEach(print);
    }
    print('--- ${eventLog.total} events');
    eventLog.entries.forEach(print);
    Application.instance.quit(0);
  }
}
