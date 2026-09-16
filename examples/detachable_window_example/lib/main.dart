// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'dart:ui' show AppExitType;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/_window.dart' as fw;
import 'package:nativeapi/nativeapi.dart' as na;

import 'src/demo/panels.dart';
import 'src/detachable/detachable.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runWidget(const DetachableWindowApp());
}

final ThemeData _theme = ThemeData(
  colorSchemeSeed: Colors.indigo,
  useMaterial3: true,
  visualDensity: VisualDensity.compact,
);

class _MainWindowDelegate with fw.WindowControllerDelegate {
  _MainWindowDelegate(this.onCloseRequested);

  final void Function(fw.WindowController controller) onCloseRequested;

  @override
  void onWindowCloseRequested(fw.WindowController controller) {
    onCloseRequested(controller);
  }
}

const Size _mainWindowSize = Size(840, 600);

/// A newest-first list of what the controller did, mirrored to the console.
class ActivityLog extends ValueNotifier<List<String>> {
  ActivityLog() : super(const []);

  void add(String message) {
    final now = TimeOfDay.now();
    final stamp =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    debugPrint('[detachable] $message');
    value = ['$stamp  $message', ...value.take(49)];
  }
}

class DetachableWindowApp extends StatefulWidget {
  const DetachableWindowApp({super.key});

  @override
  State<DetachableWindowApp> createState() => _DetachableWindowAppState();
}

class _DetachableWindowAppState extends State<DetachableWindowApp> {
  final _log = ActivityLog();

  late final List<HostWindow> _mainWindows = [
    _createMainWindow('A'),
    _createMainWindow('B'),
  ];

  HostWindow _createMainWindow(String name) {
    final controller = fw.WindowController(
      size: _mainWindowSize,
      constraints: const BoxConstraints(minWidth: 720, minHeight: 480),
      title: 'nativeapi · Window $name',
      delegate: _MainWindowDelegate(_closeMainWindow),
    );
    return HostWindow(
      controller: controller,
      builder: (context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _theme,
        home: MainPage(name: name, log: _log),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _placeMainWindowsSideBySide();
  }

  void _placeMainWindowsSideBySide() {
    final area = na.DisplayManager.instance.getPrimary()?.workArea;
    if (area == null) return;
    const gap = 24.0;
    final count = _mainWindows.length;
    final frames = [
      for (final host in _mainWindows) nativeWindowOf(host.controller),
    ];
    final width = frames.first?.bounds.width ?? _mainWindowSize.width;
    // Overlap them when the screen is too narrow to fit them all.
    final step = ((area.width - width) / (count - 1)).clamp(0.0, width + gap);
    final left = area.left + (area.width - width - step * (count - 1)) / 2;
    for (var i = 0; i < count; i++) {
      frames[i]?.position = Offset(left + step * i, area.top + 60 + 40.0 * i);
    }
  }

  /// Closing a main window pops its panels out instead of losing them; the
  /// app ends with the last main window.
  void _closeMainWindow(fw.WindowController controller) {
    _controller.floatItemsInView(controller.rootView.viewId);
    _controller.unregisterHostWindow(controller);
    setState(() {
      _mainWindows.removeWhere((host) => host.controller == controller);
    });
    // Destroy only once the frame that removes its view has been built.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      controller.destroy();
      if (_mainWindows.isEmpty) {
        ServicesBinding.instance.exitApplication(AppExitType.required);
      }
    });
  }

  late final DetachController _controller = DetachController(
    items: [
      DetachableItem(
        id: 'inspector',
        title: 'Inspector',
        builder: (context) => const InspectorPanel(itemId: 'inspector'),
      ),
      DetachableItem(
        id: 'stopwatch',
        title: 'Stopwatch',
        builder: (context) => const StopwatchPanel(itemId: 'stopwatch'),
      ),
    ],
    initialSlots: const {'inspector': 'A-left', 'stopwatch': 'A-bottom'},
    logger: _log.add,
  );

  @override
  void dispose() {
    _controller.dispose();
    for (final host in _mainWindows) {
      host.controller.destroy();
    }
    _log.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetachableWindows(
      controller: _controller,
      hosts: List.of(_mainWindows),
      floatingWindowBuilder: (context, item, content) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _theme,
        home: content,
      ),
    );
  }
}

/// A main window: a panel slot on each side of a workspace.
class MainPage extends StatelessWidget {
  const MainPage({super.key, required this.name, required this.log});

  final String name;
  final ActivityLog log;

  @override
  Widget build(BuildContext context) {
    final divider = Theme.of(context).colorScheme.outlineVariant;
    final workspace = _Workspace(name: name, log: log);

    // The two windows lay their slots out differently on purpose: a panel
    // takes the size and shape of whatever slot it is docked in, and keeps
    // that size when it is torn off.
    return Scaffold(
      body: switch (name) {
        'A' => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 240, child: _slot('A-left', 'Sidebar')),
            VerticalDivider(width: 1, color: divider),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: workspace),
                  Divider(height: 1, color: divider),
                  SizedBox(
                    height: 210,
                    child: _slot('A-bottom', 'Bottom panel'),
                  ),
                ],
              ),
            ),
          ],
        ),
        _ => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 170, child: _slot('$name-top', 'Top strip')),
            Divider(height: 1, color: divider),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: workspace),
                  VerticalDivider(width: 1, color: divider),
                  SizedBox(
                    width: 330,
                    child: _slot('$name-right', 'Wide sidebar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      },
    );
  }

  static Widget _slot(String id, String label) => DockSlot(
    slotId: id,
    emptyBuilder: (context, isDropTarget) =>
        _EmptySlot(label: label, isDropTarget: isDropTarget),
  );
}

/// What a free slot looks like: its name and size on a plain fill covering the
/// whole slot, highlighted while a dragged panel would dock into it.
class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.label, required this.isDropTarget});

  final String label;
  final bool isDropTarget;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final dragging = DetachScope.of(context).isMovingWindow;
    final accent = isDropTarget ? colors.primary : colors.outline;
    return LayoutBuilder(
      builder: (context, slot) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        // Fill the slot edge to edge, with no margin or border: the
        // highlighted area is exactly what a docked panel (and its torn-off
        // window) occupies.
        color: isDropTarget
            ? colors.primaryContainer
            : dragging
            ? colors.primary.withValues(alpha: 0.06)
            : colors.surfaceContainerLowest,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isDropTarget
                        ? Icons.download
                        : Icons.dashboard_customize_outlined,
                    color: accent,
                    size: 32,
                  ),
                  const SizedBox(height: 6),
                  Text(label, style: text.titleSmall?.copyWith(color: accent)),
                  Text(
                    isDropTarget
                        ? 'Release to dock'
                        : '${slot.maxWidth.round()} × '
                              '${slot.maxHeight.round()}',
                    style: text.bodySmall?.copyWith(color: accent),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Workspace extends StatelessWidget {
  const _Workspace({required this.name, required this.log});

  final String name;
  final ActivityLog log;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final controller = DetachScope.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Window $name', style: text.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Drag a panel by its header to pop it out into a window of its own, '
            'and onto any empty slot, in this window or the other one, to dock '
            'it there. Panels keep their state throughout: text, counters, '
            'scroll position, and the running stopwatch. Closing a window pops '
            'its panels out.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in controller.items)
                Chip(
                  avatar: Icon(
                    controller.isFloating(item.id)
                        ? Icons.open_in_new
                        : Icons.push_pin_outlined,
                    size: 16,
                  ),
                  label: Text(
                    controller.isFloating(item.id)
                        ? '${item.title}: floating'
                        : '${item.title}: docked ${controller.slotOf(item.id)}',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Activity', style: text.titleMedium),
          const SizedBox(height: 8),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: ValueListenableBuilder<List<String>>(
                valueListenable: log,
                builder: (context, entries, _) => entries.isEmpty
                    ? Center(
                        child: Text(
                          'Nothing yet — try dragging a panel header.',
                          style: TextStyle(color: colors.outline),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: entries.length,
                        itemBuilder: (context, i) => Text(
                          entries[i],
                          style: text.bodySmall?.copyWith(fontFamily: 'Menlo'),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
