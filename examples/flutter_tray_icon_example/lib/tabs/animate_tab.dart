import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../icon_animations.dart';
import '../tray_controller.dart';
import '../widgets/option_chip.dart';
import '../widgets/palette.dart';

/// The gallery: every tile is alive, one click plays it in the tray.
class AnimateTab extends StatefulWidget {
  const AnimateTab({super.key, required this.controller});

  final TrayController controller;

  @override
  State<AnimateTab> createState() => _AnimateTabState();
}

class _AnimateTabState extends State<AnimateTab>
    with SingleTickerProviderStateMixin {
  // One clock for all tiles. They only preview the look; the tray frames come
  // from the selected icon's IconAnimator.
  final ValueNotifier<double> _time = ValueNotifier(0);
  late final Ticker _ticker;

  static const _colors = <String, Color?>{
    'Auto': null,
    'Blue': Color(0xFF2F7DE1),
    'Amber': Color(0xFFF0A020),
    'Red': Color(0xFFE5484D),
  };

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _time.value = elapsed.inMicroseconds / 1000000.0;
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  Widget _tile(IconAnimation animation, IconAnimation? playing) => SizedBox(
    height: 64,
    child: _Tile(
      animation: animation,
      time: _time,
      selected: playing == animation,
      onTap: () => widget.controller.play(animation),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final entry = controller.selected;
    if (entry == null) return const SizedBox.shrink();
    final animator = entry.animator;
    final palette = Palette.of(context);

    return ListenableBuilder(
      listenable: animator,
      builder: (context, _) => ListView(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: palette.border)),
            ),
            // Plain rows rather than a GridView: a UI probe reads box offsets,
            // and sliver grids keep their children's elsewhere.
            child: Column(
              children: [
                for (var row = 0; row < 2; row++) ...[
                  if (row > 0) const SizedBox(height: 6),
                  Row(
                    children: [
                      for (var column = 0; column < 4; column++) ...[
                        if (column > 0) const SizedBox(width: 6),
                        Expanded(
                          child: _tile(
                            IconAnimation.values[row * 4 + column],
                            animator.animation,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          OptionRow(
            label: 'Still icon',
            children: [
              for (final kind in StillIcon.values)
                OptionChip(
                  label: switch (kind) {
                    StillIcon.asset => 'Asset',
                    StillIcon.drawn => 'Drawn',
                    StillIcon.base64 => 'Base64',
                  },
                  selected: entry.still == kind,
                  onTap: () => controller.setStill(kind),
                ),
            ],
          ),
          OptionRow(
            label: 'Rate',
            children: [
              for (final fps in const [10, 24, 30, 60])
                OptionChip(
                  label: '$fps fps',
                  selected: animator.fps == fps,
                  onTap: () => controller.setFps(fps),
                ),
            ],
          ),
          OptionRow(
            label: 'Resolution',
            children: [
              for (final scale in const [1, 2, 3])
                OptionChip(
                  label: '${scale}x',
                  selected: animator.scale == scale,
                  onTap: () => controller.setScale(scale),
                ),
              Hint('${animator.pixelSize} px per side'),
            ],
          ),
          OptionRow(
            label: 'Color',
            children: [
              for (final MapEntry(:key, :value) in _colors.entries)
                OptionChip(
                  label: key,
                  selected:
                      animator.color == (value ?? TrayController.autoColor),
                  onTap: () =>
                      controller.setColor(value ?? TrayController.autoColor),
                ),
              if (Platform.isMacOS) const Hint('macOS tints it itself'),
            ],
          ),
          OptionRow(
            label: 'Scenes',
            children: [
              OptionChip(
                label: 'Download',
                selected: entry.scene == Scene.download,
                onTap: () => controller.playScene(Scene.download),
              ),
              OptionChip(
                label: 'Recording',
                selected: entry.scene == Scene.recording,
                onTap: () => controller.playScene(Scene.recording),
              ),
              OptionChip(
                label: 'Syncing',
                selected: entry.scene == Scene.syncing,
                onTap: () => controller.playScene(Scene.syncing),
              ),
              OptionChip(
                label: 'Three icons',
                onTap: controller.playThreeAtOnce,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatefulWidget {
  const _Tile({
    required this.animation,
    required this.time,
    required this.selected,
    required this.onTap,
  });

  final IconAnimation animation;
  final ValueNotifier<double> time;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final selected = widget.selected;
    final color = selected ? palette.accent : palette.text;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: selected
                ? palette.accentSurface
                : _hovered
                ? palette.hover
                : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? palette.accent : palette.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.animation == IconAnimation.widget
                  ? CounterBadge(time: widget.time, color: color, size: 28)
                  : RepaintBoundary(
                      child: CustomPaint(
                        size: const Size.square(28),
                        painter: IconAnimationPainter(
                          widget.animation,
                          widget.time,
                          color,
                        ),
                      ),
                    ),
              const SizedBox(height: 5),
              Text(
                widget.animation.label,
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? palette.accent : palette.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
