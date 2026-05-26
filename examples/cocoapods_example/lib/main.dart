import 'package:flutter/material.dart';
import 'package:nativeapi/nativeapi.dart';

void main() {
  runApp(const CocoapodsExampleApp());
}

class CocoapodsExampleApp extends StatelessWidget {
  const CocoapodsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CocoaPods nativeapi smoke test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const NativeApiSmokeTestPage(),
    );
  }
}

class NativeApiSmokeTestPage extends StatefulWidget {
  const NativeApiSmokeTestPage({super.key});

  @override
  State<NativeApiSmokeTestPage> createState() => _NativeApiSmokeTestPageState();
}

class _NativeApiSmokeTestPageState extends State<NativeApiSmokeTestPage> {
  final List<_CheckResult> _results = [];
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _runChecks();
  }

  Future<void> _runChecks() async {
    setState(() {
      _isRunning = true;
      _results.clear();
    });

    final results = <_CheckResult>[
      _check('UrlOpener support', () {
        final supported = UrlOpener.instance.isSupported;
        return 'supported: $supported';
      }),
      _check('TrayManager support', () {
        final supported = TrayManager.instance.isSupported;
        return 'supported: $supported';
      }),
      _check('Accessibility state', () {
        final enabled = AccessibilityManager().isEnabled;
        return 'enabled: $enabled';
      }),
      _check('DisplayManager primary display', () {
        final primary = DisplayManager.instance.getPrimary();
        if (primary == null) {
          return 'no primary display';
        }
        return '${primary.name} ${primary.size.width.toInt()}x${primary.size.height.toInt()}';
      }),
      _check('WindowManager current window', () {
        final current = WindowManager.instance.getCurrent();
        return current == null ? 'no active native window' : current.title;
      }),
      _check('Preferences read/write', () {
        final prefs = Preferences.withScope('cocoapods_example');
        const key = 'smoke_test';
        final value = DateTime.now().toIso8601String();
        final wrote = prefs.set(key, value);
        final readValue = prefs.get(key);
        final removed = prefs.remove(key);
        prefs.dispose();
        return 'wrote: $wrote, matched: ${readValue == value}, removed: $removed';
      }),
    ];

    if (!mounted) {
      return;
    }

    setState(() {
      _results.addAll(results);
      _isRunning = false;
    });
  }

  _CheckResult _check(String name, String Function() body) {
    try {
      return _CheckResult.success(name, body());
    } catch (error, stackTrace) {
      debugPrintStack(label: '$name failed: $error', stackTrace: stackTrace);
      return _CheckResult.failure(name, error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CocoaPods nativeapi smoke test')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _results.length + 1,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Row(
              children: [
                FilledButton(
                  onPressed: _isRunning ? null : _runChecks,
                  child: Text(_isRunning ? 'Running...' : 'Run checks'),
                ),
                const SizedBox(width: 12),
                if (_isRunning)
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            );
          }

          final result = _results[index - 1];
          return ListTile(
            tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            leading: Icon(
              result.ok ? Icons.check_circle : Icons.error,
              color: result.ok ? Colors.green : Colors.red,
            ),
            title: Text(result.name),
            subtitle: Text(result.detail),
          );
        },
      ),
    );
  }
}

class _CheckResult {
  const _CheckResult({
    required this.name,
    required this.detail,
    required this.ok,
  });

  factory _CheckResult.success(String name, String detail) {
    return _CheckResult(name: name, detail: detail, ok: true);
  }

  factory _CheckResult.failure(String name, String detail) {
    return _CheckResult(name: name, detail: detail, ok: false);
  }

  final String name;
  final String detail;
  final bool ok;
}
