import 'package:flutter/material.dart';
import 'package:nativeapi/nativeapi.dart';

void main() {
  runApp(const UrlOpenerExampleApp());
}

class UrlOpenerExampleApp extends StatelessWidget {
  const UrlOpenerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'URL Opener Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        useMaterial3: true,
      ),
      home: const UrlOpenerExamplePage(),
    );
  }
}

class UrlOpenerExamplePage extends StatefulWidget {
  const UrlOpenerExamplePage({super.key});

  @override
  State<UrlOpenerExamplePage> createState() => _UrlOpenerExamplePageState();
}

class _UrlOpenerExamplePageState extends State<UrlOpenerExamplePage> {
  final TextEditingController _urlController = TextEditingController(
    text: 'https://flutter.dev',
  );
  late final UrlOpener _urlOpener;

  bool _isSupported = false;
  bool _isOpening = false;
  String _status = 'Checking platform support...';
  UrlOpenResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _urlOpener = UrlOpener.instance;
    _refreshSupport();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _refreshSupport() {
    final supported = _urlOpener.isSupported;
    setState(() {
      _isSupported = supported;
      _status = supported
          ? 'URL opening is supported on this platform.'
          : 'URL opening is not supported on this platform.';
    });
  }

  void _openUrl() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _status = 'Enter a URL first.';
        _lastResult = null;
      });
      return;
    }

    setState(() {
      _isOpening = true;
      _status = 'Opening $url ...';
      _lastResult = null;
    });

    final result = _urlOpener.open(url);

    setState(() {
      _isOpening = false;
      _lastResult = result;
      _status = result.success
          ? 'Successfully handed URL to the system.'
          : 'Open failed.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('URL Opener Example')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Open URLs through nativeapi',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'This example uses the Flutter wrapper in package:nativeapi to check support and open a URL with the system handler.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'URL',
              hintText: 'https://example.com',
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.tonal(
                onPressed: _refreshSupport,
                child: const Text('Check support'),
              ),
              FilledButton(
                onPressed: _isOpening || !_isSupported ? null : _openUrl,
                child: const Text('Open URL'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'Supported', value: _isSupported.toString()),
                  const SizedBox(height: 8),
                  _InfoRow(label: 'Status', value: _status),
                  if (_lastResult != null) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: 'Success',
                      value: _lastResult!.success.toString(),
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: 'Error code',
                      value: _lastResult!.errorCode.name,
                    ),
                    if (_lastResult!.errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Error message',
                        value: _lastResult!.errorMessage,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
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
