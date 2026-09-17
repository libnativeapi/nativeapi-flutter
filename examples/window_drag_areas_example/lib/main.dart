import 'package:flutter/material.dart';
import 'package:nativeapi/nativeapi.dart';

/// Thickness of the resize handles and their distance from the window edge.
///
/// The handles are inset so that they are clearly the widget's, not the native
/// window frame's. tools/gui/flutter_window_drag_areas_test.* in the workspace
/// repository presses in the middle of these bands; keep the numbers in sync.
const double kResizeEdgeSize = 12;
const double kResizeEdgeInset = 16;

void main() {
  runApp(const DragAreasApp());
}

class DragAreasApp extends StatelessWidget {
  const DragAreasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const DragAreasPage(),
    );
  }
}

class DragAreasPage extends StatefulWidget {
  const DragAreasPage({super.key});

  @override
  State<DragAreasPage> createState() => _DragAreasPageState();
}

class _DragAreasPageState extends State<DragAreasPage> {
  static const _limitedEdges = [
    ResizeEdge.right,
    ResizeEdge.bottom,
    ResizeEdge.bottomRight,
  ];

  int _clicks = 0;
  bool _limited = false;

  @override
  void initState() {
    super.initState();
    // Custom chrome: no native title bar or buttons, so moving and resizing
    // is left to the two drag areas.
    final window = WindowManager.instance.getCurrent();
    if (window == null) return;
    window.title = 'nativeapi · Drag areas';
    window.titleBarStyle = TitleBarStyle.hidden;
    window.isWindowControlButtonsVisible = false;
    window.minimumSize = const Size(480, 320);
    window.contentSize = const Size(720, 480);
    window.center();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      body: DragToResizeArea(
        resizeEdgeSize: kResizeEdgeSize,
        resizeEdgeMargin: const EdgeInsets.all(kResizeEdgeInset),
        resizeEdgeColor: theme.colorScheme.primary.withValues(alpha: 0.25),
        enableResizeEdges: _limited ? _limitedEdges : null,
        child: Padding(
          padding: const EdgeInsets.all(kResizeEdgeInset + kResizeEdgeSize),
          child: Material(
            color: theme.colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DragToMoveArea(
                  child: Container(
                    height: 44,
                    color: theme.colorScheme.primaryContainer,
                    alignment: Alignment.center,
                    child: const Text('Drag here to move'),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 12,
                      children: [
                        Text(
                          'Size: ${size.width.round()} x ${size.height.round()}',
                          style: theme.textTheme.titleMedium,
                        ),
                        const Text(
                          'Double-click the bar to maximize, drag the tinted '
                          'frame to resize.',
                        ),
                        // The middle of the resize area lets the pointer through.
                        Text('Clicks: $_clicks'),
                        FilledButton(
                          onPressed: () => setState(() => _clicks++),
                          child: const Text('+1'),
                        ),
                        OutlinedButton(
                          onPressed: () => setState(() => _limited = !_limited),
                          child: Text(
                            _limited ? 'Edges: right and bottom' : 'Edges: all',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
