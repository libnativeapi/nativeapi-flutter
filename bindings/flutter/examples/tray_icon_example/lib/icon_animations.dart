import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The animations the example can play on a tray icon.
///
/// All but [widget] are drawn straight onto a canvas by [paint]. [widget] is
/// different on purpose: its frames are screenshots of a live Flutter widget
/// ([CounterBadge]), which shows that anything Flutter can lay out can end up
/// in the tray.
enum IconAnimation {
  spinner('Spinner'),
  pulse('Pulse'),
  blink('Blink'),
  progress('Progress'),
  wave('Wave'),
  rotate('Rotate'),
  clock('Clock'),
  widget('Any widget');

  const IconAnimation(this.label);

  final String label;

  /// Progress of [progress] at time [t], 0..1. The Download scene reads it to
  /// keep the tray title ("42%") in step with the ring.
  static double progressAt(double t) => (t % 4.0) / 4.0;

  /// Draws the frame for time [t] (seconds) into a [size] x [size] box.
  void paint(Canvas canvas, double size, double t, Color color) {
    final center = Offset(size / 2, size / 2);
    final stroke = size * 0.13;
    final radius = size / 2 - stroke / 2 - size * 0.04;
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    final fill = Paint()
      ..color = color
      ..isAntiAlias = true;
    final faint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..isAntiAlias = true;
    final ring = Rect.fromCircle(center: center, radius: radius);

    switch (this) {
      case IconAnimation.spinner:
        canvas.drawCircle(center, radius, faint);
        canvas.drawArc(ring, t * 2 * math.pi, math.pi * 0.6, false, line);
      case IconAnimation.pulse:
        final k = 0.5 - 0.5 * math.cos(t * 2 * math.pi / 1.2);
        canvas.drawCircle(center, (size / 2 - 1) * (0.4 + 0.6 * k), fill);
      case IconAnimation.blink:
        if (t % 1.0 < 0.5) canvas.drawCircle(center, size * 0.36, fill);
      case IconAnimation.progress:
        canvas.drawCircle(center, radius, faint);
        canvas.drawArc(
          ring,
          -math.pi / 2,
          2 * math.pi * progressAt(t),
          false,
          line,
        );
      case IconAnimation.wave:
        const bars = 4;
        final gap = size / (bars * 2 + 1);
        for (var i = 0; i < bars; i++) {
          final k = 0.5 + 0.5 * math.sin(t * 2 * math.pi / 0.9 - i * 0.9);
          final h = size * (0.25 + 0.6 * k);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(gap * (1 + i * 2), (size - h) / 2, gap, h),
              Radius.circular(gap / 2),
            ),
            fill,
          );
        }
      case IconAnimation.rotate:
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(t * 2 * math.pi / 2.4);
        final side = size * 0.56;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: side, height: side),
            Radius.circular(size * 0.08),
          ),
          line..strokeJoin = StrokeJoin.round,
        );
        canvas.restore();
      case IconAnimation.clock:
        // Real data, not a loop: the hands show the wall clock.
        final now = DateTime.now();
        final seconds = now.second + now.millisecond / 1000.0;
        final minutes = now.minute + seconds / 60.0;
        final hours = now.hour % 12 + minutes / 60.0;
        canvas.drawCircle(center, radius, line..strokeWidth = stroke * 0.8);
        void hand(double turns, double length, double width) {
          final a = turns * 2 * math.pi - math.pi / 2;
          canvas.drawLine(
            center,
            center + Offset(math.cos(a), math.sin(a)) * (radius * length),
            line..strokeWidth = width,
          );
        }
        hand(hours / 12, 0.45, stroke * 0.8);
        hand(minutes / 60, 0.7, stroke * 0.8);
        hand(seconds / 60, 0.8, stroke * 0.4);
      case IconAnimation.widget:
        break; // Captured from CounterBadge, never painted here.
    }
  }
}

/// [CustomPainter] over [IconAnimation.paint], used by the gallery tiles.
class IconAnimationPainter extends CustomPainter {
  IconAnimationPainter(this.animation, this.time, this.color)
    : super(repaint: time);

  final IconAnimation animation;
  final ValueNotifier<double> time;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    animation.paint(canvas, size.shortestSide, time.value, color);
  }

  @override
  bool shouldRepaint(IconAnimationPainter oldDelegate) =>
      oldDelegate.animation != animation || oldDelegate.color != color;
}

/// The widget behind [IconAnimation.widget]: a ring with a digit that counts
/// the seconds and bounces on every change. It is built from a [Container] and
/// a [Text] and knows nothing about tray icons — the animator screenshots it
/// through a [RepaintBoundary] once per frame.
class CounterBadge extends StatelessWidget {
  const CounterBadge({
    super.key,
    required this.time,
    required this.color,
    required this.size,
  });

  final ValueNotifier<double> time;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: ValueListenableBuilder<double>(
        valueListenable: time,
        builder: (context, t, _) {
          final phase = t % 1.0;
          final bounce = phase < 0.25 ? math.sin(phase / 0.25 * math.pi) : 0.0;
          return Transform.scale(
            scale: 0.84 + 0.16 * bounce,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: size * 0.1),
              ),
              child: Text(
                '${t.floor() % 10}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: size * 0.58,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A five-pointed star, the still icon that is drawn on a canvas.
void paintStar(Canvas canvas, double size, Color color) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final r = size / 2 * (i.isEven ? 0.95 : 0.42);
    final a = -math.pi / 2 + i * math.pi / 5;
    final p = Offset(size / 2 + r * math.cos(a), size / 2 + r * math.sin(a));
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  canvas.drawPath(
    path..close(),
    Paint()
      ..color = color
      ..isAntiAlias = true,
  );
}
