import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nativeapi/nativeapi.dart' as native;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: DesktopFeaturesPage()));
}

/// Manual tests for the desktop APIs added in core bf8e4d3.
class DesktopFeaturesPage extends StatefulWidget {
  const DesktopFeaturesPage({super.key});

  @override
  State<DesktopFeaturesPage> createState() => _DesktopFeaturesPageState();
}

class _DesktopFeaturesPageState extends State<DesktopFeaturesPage> {
  final _notifications = native.NotificationManager.instance;
  final _log = <String>[];
  native.Window? _parent;
  native.MessageDialog? _dialog;
  Timer? _poll;
  Timer? _progressTimer;
  int? _listener;
  bool _notificationsReady = false;
  bool _input = true;
  bool _checkbox = true;
  double _progress = -2;
  native.DialogModality _modality = native.DialogModality.window;
  native.MessageDialogResult _defaultButton =
      native.MessageDialogResult.primary;

  @override
  void initState() {
    super.initState();
    // Calling a native method constructs the core Application singleton (COM).
    native.Application.instance.isRunning();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _parent = native.WindowManager.instance.getCurrent();
      _record('Parent window: ${_parent?.id ?? "unavailable"}');
      if (_notifications.isSupported()) {
        _listener = _notifications.addListener((event) {
          if (event is native.NotificationActivatedEvent) {
            _record('Notification activated: ${event.argument}');
          }
        });
        _notificationsReady = _notifications.initialize();
        _record(
          'Initialize notifications: $_notificationsReady ${_notifications.getLastError() ?? ""}',
        );
      }
    });
  }

  void _record(String message) {
    if (!mounted) return;
    setState(() {
      _log.insert(
        0,
        '${DateTime.now().toIso8601String().substring(11, 19)}  $message',
      );
      if (_log.length > 100) _log.removeLast();
    });
  }

  void _pick(native.FileDialogMode mode) {
    final picker = native.FileDialog.create(mode);
    if (picker == null) return _record('Failed to create picker');
    try {
      if (!picker.setParentWindow(_parent)) {
        _record('Picker parent rejected');
        return;
      }
      picker.modality = native.DialogModality.window;
      if (mode != native.FileDialogMode.selectFolder &&
          !picker.setFileTypes(
            mode == native.FileDialogMode.saveFile
                ? ['.txt']
                : ['.txt', '.png'],
          )) {
        _record('File filters rejected');
        return;
      }
      if (mode == native.FileDialogMode.saveFile &&
          !picker.setSuggestedFileName('nativeapi-test.txt')) {
        _record('Suggested filename rejected');
        return;
      }
      final opened = picker.open();
      _record(
        '${mode.name}: open=$opened, result=${picker.result.name}\n'
        '${picker.paths.join("\n")}\n${picker.lastError ?? ""}',
      );
    } finally {
      picker.dispose();
    }
  }

  void _openDialog({required bool extended, bool automatic = false}) {
    if (_dialog != null) return;
    // The initial frame can precede window activation. Resolve the parent when
    // the user opens a dialog instead of relying on that startup snapshot.
    final current = native.WindowManager.instance.getCurrent();
    if (current != null) {
      _parent?.dispose();
      _parent = current;
    }
    if (_parent == null) return _record('No active parent window found');
    final dialog = native.MessageDialog.create(
      'Native API test',
      'Try each button, edit the input and toggle the checkbox.',
    );
    if (dialog == null) return _record('Failed to create dialog');
    _dialog = dialog;
    dialog.setParentWindow(_parent);
    dialog.modality = automatic
        ? native.DialogModality.none
        : extended
        ? _modality
        : native.DialogModality.window;
    if (extended) {
      final configured =
          dialog.setParentWindow(_parent) &&
          dialog.setButtons('Primary', 'Secondary', 'Close') &&
          dialog.setDefaultButton(_defaultButton) &&
          dialog.setInputEnabled(_input) &&
          dialog.setInputText('Edit this text') &&
          dialog.setCheckbox(_checkbox ? 'Remember my choice' : '', false) &&
          dialog.setProgress(automatic ? 0 : _progress);
      if (!configured) {
        dialog.dispose();
        _dialog = null;
        return _record('Dialog configuration rejected');
      }
    }
    if (!dialog.open()) {
      dialog.dispose();
      _dialog = null;
      return _record('Open failed. Check the WinUI runtime and parent window.');
    }
    _record('Dialog opened; isOpen=${dialog.isOpen}');
    if (extended && dialog.isOpen) {
      _poll = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (!dialog.isOpen) _finishDialog();
      });
      if (automatic) {
        var step = 0;
        _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (
          timer,
        ) {
          if (!dialog.isOpen) {
            timer.cancel();
            return;
          }
          step++;
          dialog.setProgress((step / 10).clamp(0.0, 1.0));
          if (step >= 10) {
            timer.cancel();
            _record('Automatic close: ${dialog.close()}');
          }
        });
      }
    } else {
      _finishDialog();
    }
  }

  void _finishDialog() {
    _poll?.cancel();
    _poll = null;
    _progressTimer?.cancel();
    _progressTimer = null;
    final dialog = _dialog;
    if (dialog == null) return;
    _record(
      'Dialog result=${dialog.result.name}, input="${dialog.inputText}", '
      'checked=${dialog.isCheckboxChecked}',
    );
    dialog.dispose();
    setState(() => _dialog = null);
  }

  @override
  void dispose() {
    _poll?.cancel();
    _progressTimer?.cancel();
    _dialog?.close();
    _dialog?.dispose();
    if (_listener != null) _notifications.removeListener(_listener!);
    if (_notificationsReady) _notifications.shutdown();
    _parent?.dispose();
    super.dispose();
  }

  Widget _section(String title, List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final extended = native.MessageDialog.isExtendedSupported();
    return Scaffold(
      appBar: AppBar(title: const Text('Desktop features test')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Windows: file pickers work with either backend. Extended dialogs, '
            'notifications and title-bar colors require the WinUI 3 build. '
            'Dialogs cover the current window. Use the automatic test for live progress and Close.',
          ),
          _section('File and folder pickers', [
            Text('Supported: ${native.FileDialog.isSupported()}'),
            const Text(
              'Open filters: .txt / .png. Save suggests nativeapi-test.txt; '
              'the WinRT save picker may create an empty file. Cancellation is logged separately.',
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final mode in native.FileDialogMode.values)
                  FilledButton(
                    onPressed: native.FileDialog.isSupported()
                        ? () => _pick(mode)
                        : null,
                    child: Text(mode.name),
                  ),
              ],
            ),
          ]),
          _section('Message dialog', [
            Text('Extended controls supported: $extended'),
            Wrap(
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<native.DialogModality>(
                  value: _modality,
                  items: native.DialogModality.values
                      .map(
                        (v) => DropdownMenuItem(value: v, child: Text(v.name)),
                      )
                      .toList(),
                  onChanged: _dialog == null
                      ? (v) => setState(() => _modality = v!)
                      : null,
                ),
                DropdownButton<native.MessageDialogResult>(
                  value: _defaultButton,
                  items: native.MessageDialogResult.values
                      .where((v) => v != native.MessageDialogResult.none)
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text('Default: ${v.name}'),
                        ),
                      )
                      .toList(),
                  onChanged: _dialog == null
                      ? (v) => setState(() => _defaultButton = v!)
                      : null,
                ),
                FilterChip(
                  label: const Text('Input'),
                  selected: _input,
                  onSelected: _dialog == null
                      ? (v) => setState(() => _input = v)
                      : null,
                ),
                FilterChip(
                  label: const Text('Checkbox'),
                  selected: _checkbox,
                  onSelected: _dialog == null
                      ? (v) => setState(() => _checkbox = v)
                      : null,
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final value in [-2.0, -1.0, 0.0, 0.5, 1.0])
                  ChoiceChip(
                    label: Text(
                      value == -2
                          ? 'Hidden'
                          : value == -1
                          ? 'Indeterminate'
                          : '${(value * 100).round()}%',
                    ),
                    selected: _progress == value,
                    onSelected: (_) {
                      setState(() => _progress = value);
                      if (_dialog != null) {
                        _record('Set progress: ${_dialog!.setProgress(value)}');
                      }
                    },
                  ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: _dialog == null
                      ? () => _openDialog(extended: false)
                      : null,
                  child: const Text('Basic dialog'),
                ),
                FilledButton(
                  onPressed: extended && _dialog == null
                      ? () => _openDialog(extended: true)
                      : null,
                  child: const Text('Extended dialog'),
                ),
                FilledButton(
                  onPressed: extended && _dialog == null
                      ? () => _openDialog(extended: true, automatic: true)
                      : null,
                  child: const Text('Auto progress + close (5s)'),
                ),
                OutlinedButton(
                  onPressed: _dialog == null
                      ? null
                      : () => _record('Close: ${_dialog!.close()}'),
                  child: const Text('Close dialog'),
                ),
              ],
            ),
          ]),
          _section('Notifications', [
            Text(
              'Build support: ${_notifications.isSupported()}; initialized: $_notificationsReady',
            ),
            const Text(
              'Send twice to replace the same tag. Click the banner or action button '
              'and check the activation argument below. OS notification settings may suppress banners.',
            ),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: !_notificationsReady
                      ? null
                      : () {
                          final ok = _notifications.show(
                            'Native API test',
                            'Sent at ${DateTime.now()}',
                            'nativeapi-test',
                            'Test action',
                          );
                          _record(
                            'Send/replace: $ok ${_notifications.getLastError() ?? ""}',
                          );
                        },
                  child: const Text('Send / replace'),
                ),
                OutlinedButton(
                  onPressed: !_notificationsReady
                      ? null
                      : () {
                          final ok = _notifications.remove('nativeapi-test');
                          _record(
                            'Remove: $ok ${_notifications.getLastError() ?? ""}',
                          );
                        },
                  child: const Text('Remove'),
                ),
              ],
            ),
          ]),
          _section('Results', [
            TextButton(
              onPressed: () => setState(_log.clear),
              child: const Text('Clear'),
            ),
            SelectableText(
              _log.isEmpty ? 'Results appear here.' : _log.join('\n\n'),
            ),
          ]),
        ],
      ),
    );
  }
}
