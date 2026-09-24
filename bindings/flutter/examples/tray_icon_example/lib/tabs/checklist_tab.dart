import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../checklist.dart';
import '../widgets/option_chip.dart';
import '../widgets/palette.dart';

/// Acceptance in one screen: what ticked itself, what still needs a look.
class ChecklistTab extends StatelessWidget {
  const ChecklistTab({super.key, required this.checklist});

  final Checklist checklist;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final auto = checklist.items.where((i) => !i.manual);
    final manual = checklist.items.where((i) => i.manual);

    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 3),
      child: Text(text, style: TextStyle(fontSize: 11, color: palette.muted)),
    );

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              header('Auto · ticks itself from events and return values'),
              for (final item in auto) _Row(item: item, checklist: checklist),
              Container(
                margin: const EdgeInsets.only(top: 6),
                height: 1,
                color: palette.border,
              ),
              header('Manual · look at the tray, then mark it'),
              for (final item in manual) _Row(item: item, checklist: checklist),
              const SizedBox(height: 6),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: palette.border)),
          ),
          child: Row(
            children: [
              Expanded(child: Text(checklist.summary, style: palette.mono)),
              OptionChip(
                label: 'Copy report',
                onTap: () =>
                    Clipboard.setData(ClipboardData(text: checklist.report())),
              ),
              const SizedBox(width: 5),
              OptionChip(label: 'Reset checklist', onTap: checklist.reset),
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item, required this.checklist});

  final CheckItem item;
  final Checklist checklist;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final detail = [
      if (item.note != null) item.note!,
      if (item.detail.isNotEmpty) item.detail,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Row(
        children: [
          CustomPaint(
            size: const Size.square(14),
            painter: _StatusMark(item.status, palette),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          if (detail.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                detail,
                style: palette.mono.copyWith(
                  color: item.status == CheckStatus.fail
                      ? palette.danger
                      : palette.muted,
                ),
              ),
            ),
          if (item.manual) ...[
            const SizedBox(width: 6),
            OptionChip(
              label: 'Pass',
              selected: item.status == CheckStatus.pass,
              onTap: () => checklist.mark(item.id, CheckStatus.pass),
            ),
            const SizedBox(width: 4),
            OptionChip(
              label: 'Fail',
              selected: item.status == CheckStatus.fail,
              onTap: () => checklist.mark(item.id, CheckStatus.fail),
            ),
          ],
        ],
      ),
    );
  }
}

/// Open ring, green tick or red cross.
class _StatusMark extends CustomPainter {
  _StatusMark(this.status, this.palette);

  final CheckStatus status;
  final Palette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    if (status == CheckStatus.open) {
      canvas.drawCircle(
        center,
        radius - 0.75,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = palette.border,
      );
      return;
    }
    final pass = status == CheckStatus.pass;
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = pass ? palette.success : palette.danger,
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = palette.background;
    final s = size.shortestSide;
    if (pass) {
      canvas.drawPath(
        Path()
          ..moveTo(s * 0.27, s * 0.52)
          ..lineTo(s * 0.44, s * 0.68)
          ..lineTo(s * 0.74, s * 0.34),
        stroke,
      );
    } else {
      canvas.drawLine(
        Offset(s * 0.32, s * 0.32),
        Offset(s * 0.68, s * 0.68),
        stroke,
      );
      canvas.drawLine(
        Offset(s * 0.68, s * 0.32),
        Offset(s * 0.32, s * 0.68),
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_StatusMark oldDelegate) =>
      oldDelegate.status != status || oldDelegate.palette != palette;
}
