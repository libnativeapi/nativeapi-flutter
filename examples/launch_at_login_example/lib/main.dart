import 'package:flutter/material.dart';
import 'package:nativeapi/nativeapi.dart';

void main() {
  runApp(const LaunchAtLoginExampleApp());
}

class LaunchAtLoginExampleApp extends StatelessWidget {
  const LaunchAtLoginExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LaunchAtLogin Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C3AED)),
        useMaterial3: true,
      ),
      home: const LaunchAtLoginExamplePage(),
    );
  }
}

class LaunchAtLoginExamplePage extends StatefulWidget {
  const LaunchAtLoginExamplePage({super.key});

  @override
  State<LaunchAtLoginExamplePage> createState() =>
      _LaunchAtLoginExamplePageState();
}

class _LaunchAtLoginExamplePageState extends State<LaunchAtLoginExamplePage> {
  late final LaunchAtLogin _launchAtLogin;

  bool _isSupported = false;
  bool _isEnabled = false;
  bool _isBusy = false;
  String _status = 'Initializing...';

  // Config fields
  final _displayNameController = TextEditingController();
  final _executablePathController = TextEditingController();
  final _argumentsController = TextEditingController();

  // Current values (read from API)
  String _currentId = '';
  String _currentDisplayName = '';
  String _currentExecutablePath = '';
  String _currentArguments = '';

  @override
  void initState() {
    super.initState();
    _launchAtLogin = LaunchAtLogin();
    _refreshState();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _executablePathController.dispose();
    _argumentsController.dispose();
    _launchAtLogin.dispose();
    super.dispose();
  }

  void _refreshState() {
    setState(() {
      _isSupported = LaunchAtLogin.isSupported;
      if (_isSupported) {
        _isEnabled = _launchAtLogin.isEnabled;
        _currentId = _launchAtLogin.id;
        _currentDisplayName = _launchAtLogin.displayName;
        _currentExecutablePath = _launchAtLogin.executablePath;
        _currentArguments = _launchAtLogin.arguments.join(' ');

        // Sync text fields with current values
        _displayNameController.text = _currentDisplayName;
        _executablePathController.text = _currentExecutablePath;
        _argumentsController.text = _currentArguments;

        final enabledStatus = _isEnabled ? 'enabled' : 'disabled';
        _status = 'Launch-at-login is $enabledStatus.';
      } else {
        _status = 'Launch-at-login is not supported on this platform.';
      }
    });
  }

  Future<void> _setDisplayName() async {
    final name = _displayNameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('Display name cannot be empty.');
      return;
    }
    setState(() => _isBusy = true);
    final success = _launchAtLogin.setDisplayName(name);
    setState(() => _isBusy = false);
    if (success) {
      _showSnackBar('Display name updated.');
      _refreshState();
    } else {
      _showSnackBar('Failed to set display name.');
    }
  }

  Future<void> _setProgram() async {
    final path = _executablePathController.text.trim();
    if (path.isEmpty) {
      _showSnackBar('Executable path cannot be empty.');
      return;
    }
    final args = _argumentsController.text.trim();
    final argsList = args.isNotEmpty ? args.split(RegExp(r'\s+')) : <String>[];
    setState(() => _isBusy = true);
    final success = _launchAtLogin.setProgram(path, argsList);
    setState(() => _isBusy = false);
    if (success) {
      _showSnackBar('Program configured.');
      _refreshState();
    } else {
      _showSnackBar('Failed to set program.');
    }
  }

  Future<void> _toggleEnabled(bool enable) async {
    setState(() => _isBusy = true);
    final success = enable ? _launchAtLogin.enable() : _launchAtLogin.disable();
    setState(() => _isBusy = false);
    if (success) {
      _showSnackBar(
        enable ? 'Launch-at-login enabled.' : 'Launch-at-login disabled.',
      );
      _refreshState();
    } else {
      _showSnackBar('Operation failed.');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('LaunchAtLogin Example')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Manage launch-at-login', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Use the LaunchAtLogin API to register your app to launch automatically at user login.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Status card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Supported', value: _isSupported.toString()),
                  if (_isSupported) ...[
                    const SizedBox(height: 8),
                    _InfoRow(label: 'Status', value: _status),
                    const SizedBox(height: 8),
                    _InfoRow(label: 'ID', value: _currentId),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: 'Display name',
                      value: _currentDisplayName.isNotEmpty
                          ? _currentDisplayName
                          : '(not set)',
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: 'Executable path',
                      value: _currentExecutablePath.isNotEmpty
                          ? _currentExecutablePath
                          : '(not set)',
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: 'Arguments',
                      value: _currentArguments.isNotEmpty
                          ? _currentArguments
                          : '(none)',
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_isSupported) ...[
            const SizedBox(height: 24),

            // Enable / Disable toggle
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enable / Disable',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: _isBusy || _isEnabled
                                ? null
                                : () => _toggleEnabled(true),
                            child: const Text('Enable'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: _isBusy || !_isEnabled
                                ? null
                                : () => _toggleEnabled(false),
                            child: const Text('Disable'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Configure display name
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Display Name', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Display name',
                        hintText: 'My Application',
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: _isBusy ? null : _setDisplayName,
                      child: const Text('Set display name'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Configure program
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Program Configuration',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _executablePathController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Executable path',
                        hintText: '/usr/bin/myapp',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _argumentsController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Arguments (space-separated)',
                        hintText: '--flag1 --flag2',
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: _isBusy ? null : _setProgram,
                      child: const Text('Set program'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Refresh
            Center(
              child: FilledButton.icon(
                onPressed: _isBusy ? null : _refreshState,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh state'),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        SelectableText(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
