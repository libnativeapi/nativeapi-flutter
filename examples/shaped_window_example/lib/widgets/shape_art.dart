import 'package:flutter/widgets.dart';

import '../shape_geometry.dart';

class ShapeLook {
  const ShapeLook(this.name, this.colors);
  final String name;
  final List<Color> colors;
  static ShapeLook forShape(DemoShape shape) => switch (shape) {
    DemoShape.circle => const ShapeLook('Aurora', [
      Color(0xFF6546F5),
      Color(0xFFBF46E9),
      Color(0xFFFF8799),
    ]),
    DemoShape.star => const ShapeLook('Sunset', [
      Color(0xFFEA4564),
      Color(0xFFFF843E),
      Color(0xFFFFCD70),
    ]),
    DemoShape.bubble => const ShapeLook('Ocean', [
      Color(0xFF154BBC),
      Color(0xFF188BC6),
      Color(0xFF64E4CB),
    ]),
    DemoShape.heart => const ShapeLook('Berry', [
      Color(0xFF7525A3),
      Color(0xFFD53788),
      Color(0xFFFFA8CB),
    ]),
    DemoShape.flower => const ShapeLook('Lime', [
      Color(0xFF176655),
      Color(0xFF45993B),
      Color(0xFFCCE868),
    ]),
    DemoShape.hexagon => const ShapeLook('Glacier', [
      Color(0xFF3542AD),
      Color(0xFF657DED),
      Color(0xFF9FD9FF),
    ]),
    DemoShape.squircle => const ShapeLook('Honey', [
      Color(0xFFB96616),
      Color(0xFFEBA92E),
      Color(0xFFFFDD86),
    ]),
    DemoShape.blob => const ShapeLook('Lagoon', [
      Color(0xFF116C70),
      Color(0xFF25A99E),
      Color(0xFF84EBC7),
    ]),
    DemoShape.burst => const ShapeLook('Coral', [
      Color(0xFFC32E56),
      Color(0xFFF36776),
      Color(0xFFFFAE9D),
    ]),
    DemoShape.droplet => const ShapeLook('Rain', [
      Color(0xFF2340A2),
      Color(0xFF467DED),
      Color(0xFF90CEFF),
    ]),
    DemoShape.diamond => const ShapeLook('Peach', [
      Color(0xFFC24D70),
      Color(0xFFEF9175),
      Color(0xFFFFD5AE),
    ]),
    DemoShape.shield => const ShapeLook('Forest', [
      Color(0xFF245140),
      Color(0xFF438568),
      Color(0xFFB2D69A),
    ]),
  };
}

/// Static vector decoration: no extra animation ticker or image assets.
class ShapeArt extends StatelessWidget {
  const ShapeArt({super.key, required this.look, this.child});
  final ShapeLook look;
  final Widget? child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: look.colors,
      ),
    ),
    child: CustomPaint(painter: _Sparkles(), child: child),
  );
}

class _Sparkles extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x18FFFFFF);
    canvas.drawCircle(
      Offset(size.width * .83, size.height * .18),
      size.width * .31,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * .10, size.height * .86),
      size.width * .37,
      paint,
    );
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x24FFFFFF);
    canvas.drawCircle(
      Offset(size.width * .78, size.height * .22),
      size.width * .39,
      paint,
    );
    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0x38FFFFFF);
    for (var x = 16.0; x < size.width; x += 20) {
      for (var y = 16.0; y < size.height; y += 20) {
        canvas.drawCircle(Offset(x, y), .8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_Sparkles oldDelegate) => false;
}
