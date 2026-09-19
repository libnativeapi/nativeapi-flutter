import 'dart:io';

import 'package:flutter/widgets.dart';

import '../icon_animations.dart';
import '../icon_animator.dart';
import '../tray_controller.dart';
import 'option_chip.dart';
import 'palette.dart';

/// Magnified view of the selected tray icon.
///
/// It paints [IconAnimator.lastFrame] — the very image that was just handed to
/// the tray — so the window and the tray can be compared frame by frame.
class LivePreview extends StatefulWidget {
  const LivePreview({super.key, required this.controller});

  final TrayController controller;

  @override
  State<LivePreview> createState() => _LivePreviewState();
}

class _LivePreviewState extends State<LivePreview> {
  bool? _darkBar;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final entry = widget.controller.selected;
    final darkBar = _darkBar ?? palette.isDark;

    return Container(
      height: 112,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: entry == null
          ? Center(
              child: Text(
                'No tray icon. Add one to start.',
                style: TextStyle(color: palette.muted),
              ),
            )
          : ListenableBuilder(
              listenable: entry.animator,
              builder: (context, _) => Row(
                children: [
                  Stack(
                    children: [
                      // Live widgets being screenshotted for "Any widget".
                      // They have to be painted, so they sit under the
                      // (opaque) preview box instead of being Offstage.
                      for (final other in widget.controller.entries)
                        if (other.animator.animation == IconAnimation.widget)
                          Positioned(
                            left: 30,
                            top: 30,
                            child: RepaintBoundary(
                              key: other.animator.captureKey,
                              child: CounterBadge(
                                time: other.animator.time,
                                color: other.animator.color,
                                size: kIconPoints,
                              ),
                            ),
                          ),
                      _frameBox(entry.animator, darkBar, palette),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _details(entry, darkBar, palette)),
                ],
              ),
            ),
    );
  }

  Widget _frameBox(IconAnimator animator, bool darkBar, Palette palette) {
    final frame = animator.lastFrame;
    // macOS uses the image as a template: only alpha counts and the menu bar
    // picks the tint. Other platforms show the pixels as they are.
    final tint = Platform.isMacOS
        ? (darkBar ? const Color(0xFFFFFFFF) : const Color(0xFF000000))
        : null;
    return Container(
      width: 84,
      height: 84,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: darkBar ? const Color(0xFF2A2A2C) : const Color(0xFFECECEE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: frame == null
          ? null
          : RawImage(
              image: frame,
              width: 60,
              height: 60,
              fit: BoxFit.contain,
              // Show the real pixels; smoothing would hide the resolution.
              filterQuality: FilterQuality.none,
              color: tint,
              colorBlendMode: tint == null ? null : BlendMode.srcIn,
            ),
    );
  }

  Widget _details(TrayEntry entry, bool darkBar, Palette palette) {
    final animator = entry.animator;
    final controller = widget.controller;
    final name = animator.animation?.label ?? '${_stillLabel(entry)} icon';
    final state = !animator.isPlaying
        ? 'still'
        : animator.paused
        ? 'paused'
        : 'playing';
    final px = animator.lastFrame?.width ?? animator.pixelSize;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$name · $state',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        if (animator.isPlaying) ...[
          Text(
            'frame ${animator.frames} · '
            '${animator.measuredFps.toStringAsFixed(1)} fps',
            style: palette.mono,
          ),
          Text(
            'render ${animator.renderMs.toStringAsFixed(1)} ms · $px×$px px',
            style: palette.mono,
          ),
          Text(
            'dropped ${animator.dropped} · same frame as tray',
            style: palette.mono,
          ),
        ] else ...[
          Text('$px×$px px · same image as tray', style: palette.mono),
          Text('pick an animation below to play it', style: palette.mono),
        ],
        const Spacer(),
        Wrap(
          spacing: 5,
          children: [
            OptionChip(
              label: animator.paused ? 'Resume' : 'Pause',
              onTap: animator.isPlaying ? animator.togglePaused : null,
            ),
            OptionChip(
              label: 'Step',
              onTap: animator.isPlaying ? animator.step : null,
            ),
            OptionChip(
              label: 'Stop',
              // Back to the asset icon; a scene also gives back the title
              // and tooltip it took.
              onTap: !animator.isPlaying
                  ? null
                  : entry.scene != null
                  ? controller.resetScene
                  : () => controller.setStill(StillIcon.asset),
            ),
            OptionChip(
              label: darkBar ? 'Dark bar' : 'Light bar',
              onTap: () => setState(() => _darkBar = !darkBar),
            ),
          ],
        ),
      ],
    );
  }

  String _stillLabel(TrayEntry entry) => switch (entry.still) {
    StillIcon.asset => 'Asset',
    StillIcon.drawn => 'Drawn',
    StillIcon.base64 => 'Base64',
    null => 'Last frame',
  };
}
