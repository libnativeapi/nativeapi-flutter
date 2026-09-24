import 'dart:io';

import 'package:flutter/material.dart' hide Image;
import 'package:nativeapi_flutter/nativeapi_flutter.dart';

/// Drag and drop with the two widgets of `nativeapi`:
///
/// - the left panel is a [DropRegion]: drop files or text on it;
/// - the cards on the right are [DragOutArea]s: drag them into a file manager,
///   an editor, or onto the left panel.
///
/// tools/gui/flutter_drag_drop_test.* in the workspace repository drives this
/// example by its texts; keep them in sync.
void main() {
  runApp(const DragDropApp());
}

class DragDropApp extends StatelessWidget {
  const DragDropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const DragDropPage(),
    );
  }
}

class DragDropPage extends StatefulWidget {
  const DragDropPage({super.key});

  @override
  State<DragDropPage> createState() => _DragDropPageState();
}

class _DragDropPageState extends State<DragDropPage> {
  late final File _file = _createFile();
  bool _hovering = false;
  Offset? _hoverPosition;
  int _drops = 0;
  List<String> _droppedFiles = const [];
  String? _droppedText;
  String _lastDragResult = '-';

  static File _createFile() {
    final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'nativeapi-drag-drop-note.txt',
    );
    file.writeAsStringSync('A note dragged out of drag_drop_example.\n');
    return file;
  }

  @override
  void initState() {
    super.initState();
    final window = WindowManager.instance.getCurrent();
    if (window == null) return;
    window.title = 'nativeapi · Drag and drop';
    window.contentSize = const Size(760, 460).toNative();
    window.center();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildDropPanel(theme)),
            const SizedBox(width: 16),
            SizedBox(width: 260, child: _buildDragPanel(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildDropPanel(ThemeData theme) {
    final colors = theme.colorScheme;
    return DropRegion(
      onDragEntered: (position) => setState(() {
        _hovering = true;
        _hoverPosition = position;
      }),
      onDragUpdated: (position) => setState(() => _hoverPosition = position),
      onDragExited: () => setState(() {
        _hovering = false;
        _hoverPosition = null;
      }),
      onDropped: (details) => setState(() {
        _hovering = false;
        _hoverPosition = null;
        _drops++;
        _droppedFiles = details.filePaths;
        _droppedText = details.text;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _hovering
              ? colors.primaryContainer
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovering ? colors.primary : colors.outlineVariant,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _hovering ? 'Release to drop' : 'Drop files or text here',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              _hoverPosition == null
                  ? 'Supported: ${DropRegion.isSupported}'
                  : 'At ${_hoverPosition!.dx.round()}, ${_hoverPosition!.dy.round()}',
              style: theme.textTheme.bodySmall,
            ),
            const Divider(height: 24),
            Text('Drops: $_drops', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  for (final path in _droppedFiles)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.insert_drive_file_outlined),
                      title: Text(path.split(Platform.pathSeparator).last),
                      subtitle: Text(path),
                    ),
                  if (_droppedText != null)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.notes),
                      title: Text('Text: $_droppedText'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragPanel(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Drag out', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        _DragCard(
          icon: Icons.description_outlined,
          title: 'Drag this note',
          subtitle: _file.path.split(Platform.pathSeparator).last,
          child: (card) => DragOutArea(
            filePaths: [_file.path],
            onDragEnded: _onDragEnded,
            child: card,
          ),
        ),
        const SizedBox(height: 12),
        _DragCard(
          icon: Icons.short_text,
          title: 'Drag this text',
          subtitle: 'Hello from nativeapi',
          child: (card) => DragOutArea(
            text: 'Hello from nativeapi',
            onDragEnded: _onDragEnded,
            child: card,
          ),
        ),
        const SizedBox(height: 16),
        Text('Last drag: $_lastDragResult', style: theme.textTheme.bodyMedium),
        const Spacer(),
        Text(
          'Supported: ${DragOutArea.isSupported}',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  void _onDragEnded(DragOperation operation) {
    setState(() => _lastDragResult = operation.name);
  }
}

class _DragCard extends StatelessWidget {
  const _DragCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget Function(Widget card) child;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: child(
        Card(
          child: ListTile(
            leading: Icon(icon),
            title: Text(title),
            subtitle: Text(subtitle),
          ),
        ),
      ),
    );
  }
}
