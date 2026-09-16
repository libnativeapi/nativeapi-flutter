import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../detachable/detachable.dart';

/// Chrome shared by the demo panels: a header to grab, and proof that the
/// panel's `State` is the same object wherever it is shown.
class PanelFrame extends StatelessWidget {
  const PanelFrame({
    super.key,
    required this.itemId,
    required this.title,
    required this.icon,
    required this.stateLabel,
    required this.child,
  });

  final String itemId;
  final String title;
  final IconData icon;
  final String stateLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = DetachScope.of(context);
    final floating = controller.isFloating(itemId);
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DetachHandle(
            itemId: itemId,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: floating
                  ? colors.tertiaryContainer
                  : colors.primaryContainer,
              child: Row(
                children: [
                  Icon(
                    Icons.drag_indicator,
                    size: 18,
                    color: colors.onPrimaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Icon(icon, size: 18, color: colors.onPrimaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (floating)
                    IconButton(
                      tooltip: 'Dock back',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.login, size: 18),
                      onPressed: () => controller.dockAnywhere(itemId),
                    )
                  else
                    IconButton(
                      tooltip: 'Open in a window',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      onPressed: () => controller.float(itemId),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Text(
              stateLabel,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colors.outline),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Tracks which window a `State` is currently shown in, to count the moves.
mixin WindowMoveCounter<T extends StatefulWidget> on State<T> {
  static int _nextInstance = 1;

  final int instance = _nextInstance++;
  final DateTime createdAt = DateTime.now();
  int windowMoves = 0;
  int? _viewId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewId = View.of(context).viewId;
    if (_viewId != null && _viewId != viewId) windowMoves++;
    _viewId = viewId;
  }

  String get stateLabel {
    String two(int v) => v.toString().padLeft(2, '0');
    final t = createdAt;
    return 'State #$instance · created ${two(t.hour)}:${two(t.minute)}:${two(t.second)}'
        ' · moved between windows $windowMoves×';
  }
}

class InspectorPanel extends StatefulWidget {
  const InspectorPanel({super.key, required this.itemId});

  final String itemId;

  @override
  State<InspectorPanel> createState() => _InspectorPanelState();
}

class _InspectorPanelState extends State<InspectorPanel>
    with WindowMoveCounter {
  final _name = TextEditingController(text: 'Untitled layer');
  final _scroll = ScrollController();
  int _counter = 0;
  double _opacity = 0.8;
  int _selected = 3;
  bool _visible = true;

  @override
  void dispose() {
    _name.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // Keeps the layer list (and its scroll position) the same element when the
  // layout switches between the narrow and the wide arrangement.
  final _layersKey = GlobalKey(debugLabel: 'layers');

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final controls = <Widget>[
      TextField(
        controller: _name,
        decoration: const InputDecoration(
          labelText: 'Layer name',
          isDense: true,
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Text('Clicks: $_counter', style: text.titleMedium),
          const Spacer(),
          FilledButton.tonal(
            onPressed: () => setState(() => _counter++),
            child: const Text('+1'),
          ),
        ],
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Visible'),
        value: _visible,
        onChanged: (v) => setState(() => _visible = v),
      ),
      Text('Opacity ${(_opacity * 100).round()}%'),
      Slider(value: _opacity, onChanged: (v) => setState(() => _opacity = v)),
    ];
    final layers = Card.outlined(
      key: _layersKey,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListView.builder(
        controller: _scroll,
        itemCount: 40,
        itemBuilder: (context, i) => ListTile(
          dense: true,
          selected: i == _selected,
          leading: const Icon(Icons.layers_outlined, size: 18),
          title: Text('Layer ${i + 1}'),
          onTap: () => setState(() => _selected = i),
        ),
      ),
    );

    return PanelFrame(
      itemId: widget.itemId,
      title: 'Inspector',
      icon: Icons.tune,
      stateLabel: stateLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 480) {
            // Wide and short, e.g. a bottom or top strip: side by side.
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 280,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: controls,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                    child: layers,
                  ),
                ),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              ...controls,
              const SizedBox(height: 4),
              Text(
                'Layers (scroll position is kept too)',
                style: text.labelLarge,
              ),
              const SizedBox(height: 4),
              SizedBox(height: 220, child: layers),
            ],
          );
        },
      ),
    );
  }
}

class StopwatchPanel extends StatefulWidget {
  const StopwatchPanel({super.key, required this.itemId});

  final String itemId;

  @override
  State<StopwatchPanel> createState() => _StopwatchPanelState();
}

class _StopwatchPanelState extends State<StopwatchPanel>
    with SingleTickerProviderStateMixin, WindowMoveCounter {
  late final Ticker _ticker = createTicker((_) => setState(() {}));
  final _stopwatch = Stopwatch();
  final _laps = <Duration>[];

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
        _ticker.stop();
      } else {
        _stopwatch.start();
        _ticker.start();
      }
    });
  }

  static String _format(Duration d) {
    String two(int v) => v.toString().padLeft(2, '0');
    final centis = (d.inMilliseconds % 1000) ~/ 10;
    return '${two(d.inMinutes)}:${two(d.inSeconds % 60)}.${two(centis)}';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final clock = FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _format(_stopwatch.elapsed),
            style: text.displaySmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text('Keeps running while the panel moves', style: text.bodySmall),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: _toggle,
                child: Text(_stopwatch.isRunning ? 'Pause' : 'Start'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () =>
                    setState(() => _laps.insert(0, _stopwatch.elapsed)),
                child: const Text('Lap'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(() {
                  _stopwatch.reset();
                  _laps.clear();
                }),
                child: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
    final laps = _laps.isEmpty
        ? Center(child: Text('No laps yet', style: text.bodySmall))
        : ListView.builder(
            itemCount: _laps.length,
            itemBuilder: (context, i) => ListTile(
              dense: true,
              leading: Text('#${_laps.length - i}'),
              title: Text(_format(_laps[i])),
            ),
          );

    return PanelFrame(
      itemId: widget.itemId,
      title: 'Stopwatch',
      icon: Icons.timer_outlined,
      stateLabel: stateLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > constraints.maxHeight * 1.6) {
            // Wide and short: clock on the left, laps on the right.
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Center(child: clock),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(flex: 2, child: laps),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
                child: clock,
              ),
              const Divider(height: 24),
              Expanded(child: laps),
            ],
          );
        },
      ),
    );
  }
}
