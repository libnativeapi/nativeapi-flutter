import 'dart:math' as math;

import 'package:flutter/widgets.dart';

enum DemoShape {
  circle,
  star,
  bubble,
  heart,
  flower,
  hexagon,
  squircle,
  blob,
  burst,
  droplet,
  diamond,
  shield,
}

/// Both the native clip and the preview use these content-local logical points.
List<Offset> shapePoints(DemoShape shape, double size) {
  final c = size / 2;
  final points = switch (shape) {
    DemoShape.circle => List.generate(128, (i) {
      final a = i * math.pi * 2 / 128;
      return Offset(c + (c - 4) * math.cos(a), c + (c - 4) * math.sin(a));
    }),
    DemoShape.star => List.generate(10, (i) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final r = (c - 4) * (i.isEven ? 1 : 0.60);
      return Offset(c + r * math.cos(a), c + r * math.sin(a));
    }),
    DemoShape.heart => List.generate(96, (i) {
      final t = i * math.pi * 2 / 96;
      final x = 16 * math.pow(math.sin(t), 3);
      final y =
          13 * math.cos(t) -
          5 * math.cos(2 * t) -
          2 * math.cos(3 * t) -
          math.cos(4 * t);
      return Offset(size * (.5 + x / 36), size * (.48 - y / 36));
    }),
    DemoShape.flower => _radial(
      size,
      96,
      (a) => .39 + .075 * math.cos(6 * (a + math.pi / 2)),
    ),
    DemoShape.hexagon => _radial(size, 6, (_) => .47),
    DemoShape.squircle => List.generate(96, (i) {
      final a = -math.pi / 2 + i * math.pi * 2 / 96;
      double axis(double v) => v.sign * math.pow(v.abs(), .5).toDouble();
      return Offset(
        c + size * .43 * axis(math.cos(a)),
        c + size * .43 * axis(math.sin(a)),
      );
    }),
    DemoShape.blob => _radial(
      size,
      96,
      (a) => .39 + .045 * math.sin(3 * a + 1) + .025 * math.cos(5 * a),
    ),
    DemoShape.burst => _radial(
      size,
      24,
      (a) => .40 + .065 * math.cos(12 * (a + math.pi / 2)),
    ),
    DemoShape.droplet => List.generate(96, (i) {
      final t = i * math.pi * 2 / 96;
      return Offset(
        size * (.5 + .46 * math.sin(t) * (.72 - .28 * math.cos(t))),
        size * (.5 - .46 * math.cos(t)),
      );
    }),
    DemoShape.diamond => _radial(size, 4, (_) => .47),
    DemoShape.shield => [
      Offset(size * .5, size * .07),
      Offset(size * .9, size * .16),
      Offset(size * .85, size * .60),
      Offset(size * .7, size * .8),
      Offset(size * .5, size * .95),
      Offset(size * .3, size * .8),
      Offset(size * .15, size * .60),
      Offset(size * .1, size * .16),
    ],
    DemoShape.bubble => [
      Offset(size * .12, size * .08),
      Offset(size * .88, size * .08),
      Offset(size * .96, size * .16),
      Offset(size * .96, size * .72),
      Offset(size * .88, size * .80),
      Offset(size * .40, size * .80),
      Offset(size * .16, size * .96),
      Offset(size * .21, size * .80),
      Offset(size * .12, size * .80),
      Offset(size * .04, size * .72),
      Offset(size * .04, size * .16),
    ],
  };
  return switch (shape) {
    DemoShape.star ||
    DemoShape.bubble ||
    DemoShape.hexagon ||
    DemoShape.burst ||
    DemoShape.diamond ||
    DemoShape.shield => _roundCorners(points),
    _ => points,
  };
}

// Quadratic corner arcs are sampled into the same polygon used by Flutter and
// the native window, so visual clipping, hit testing and shadows stay aligned.
List<Offset> _roundCorners(List<Offset> points) {
  final rounded = <Offset>[];
  for (var i = 0; i < points.length; i++) {
    final corner = points[i];
    final before = points[(i + points.length - 1) % points.length];
    final after = points[(i + 1) % points.length];
    final entry = Offset.lerp(corner, before, .20)!;
    final exit = Offset.lerp(corner, after, .20)!;
    for (var j = 0; j <= 6; j++) {
      final t = j / 6;
      rounded.add(
        entry * ((1 - t) * (1 - t)) +
            corner * (2 * (1 - t) * t) +
            exit * (t * t),
      );
    }
  }
  return rounded;
}

List<Offset> _radial(double size, int count, double Function(double) radius) =>
    List.generate(count, (i) {
      final a = -math.pi / 2 + i * math.pi * 2 / count;
      final r = size * radius(a);
      return Offset(size / 2 + r * math.cos(a), size / 2 + r * math.sin(a));
    });

/// Uses exactly the polygon sent to native input hit testing, including its
/// even-odd fill rule. The surrounding window must clear to transparent.
class ShapeClipper extends CustomClipper<Path> {
  const ShapeClipper(this.shape, this.extent);

  final DemoShape shape;
  final double extent;

  @override
  Path getClip(Size size) => Path()
    ..fillType = PathFillType.evenOdd
    ..addPolygon(shapePoints(shape, extent), true);

  @override
  bool shouldReclip(ShapeClipper oldClipper) =>
      shape != oldClipper.shape || extent != oldClipper.extent;
}

/// All contours share perimeter landmarks, including every original vertex.
/// This preserves the rounded contours at the endpoints without twisting differently
/// sized polygons around each other. Null denotes the restored rectangle.
Map<DemoShape?, List<Offset>> morphContours(double extent) {
  // Compute landmarks in a fixed reference size so point counts and correspondence
  // remain identical at every window size, including mid-resize retargeting.
  const reference = 320.0;
  final polygons = <DemoShape?, List<Offset>>{
    for (final shape in DemoShape.values) shape: shapePoints(shape, reference),
    null: [
      Offset(reference / 2, 0),
      Offset(reference, 0),
      Offset(reference, reference),
      Offset(0, reference),
      Offset.zero,
    ],
  };
  // Give every clockwise contour the same top-centre starting landmark.
  final circle = polygons[DemoShape.circle]!;
  polygons[DemoShape.circle] = [...circle.skip(96), ...circle.take(96)];
  final bubble = polygons[DemoShape.bubble]!;
  polygons[DemoShape.bubble] = [
    Offset(reference / 2, reference * .08),
    ...bubble.skip(7),
    ...bubble.take(7),
  ];
  final lengths = <DemoShape?, List<double>>{};
  final landmarks = <double>{for (int i = 0; i < 128; i++) i / 128};
  for (final entry in polygons.entries) {
    final points = entry.value;
    final distances = <double>[0];
    for (int i = 0; i < points.length; i++) {
      distances.add(
        distances.last + (points[(i + 1) % points.length] - points[i]).distance,
      );
    }
    final total = distances.last;
    final fractions = distances.map((d) => d / total).toList();
    lengths[entry.key] = fractions;
    landmarks.addAll(fractions.take(points.length));
  }
  final parameters = landmarks.toList()..sort();
  return polygons.map((shape, points) {
    final fractions = lengths[shape]!;
    int edge = 0;
    final samples = <Offset>[];
    for (final t in parameters) {
      while (edge + 1 < points.length && fractions[edge + 1] <= t) {
        edge++;
      }
      samples.add(
        Offset.lerp(
          points[edge],
          points[(edge + 1) % points.length],
          (t - fractions[edge]) / (fractions[edge + 1] - fractions[edge]),
        )!,
      );
    }
    return MapEntry(
      shape,
      samples.map((p) {
        // Circle/star keep their absolute 4 px inset; bubble/rectangle scale fully.
        if (shape == DemoShape.circle || shape == DemoShape.star) {
          return Offset(extent / 2, extent / 2) +
              (p - const Offset(reference / 2, reference / 2)) *
                  ((extent - 8) / (reference - 8));
        }
        return p * (extent / reference);
      }).toList(),
    );
  });
}

List<Offset> interpolateContour(List<Offset> from, List<Offset> to, double t) {
  assert(from.length == to.length);
  return List.generate(from.length, (i) => Offset.lerp(from[i], to[i], t)!);
}

/// The exact current animation frame, also sent to the native window.
class PolygonClipper extends CustomClipper<Path> {
  const PolygonClipper(this.points);
  final List<Offset> points;

  @override
  Path getClip(Size size) => Path()
    ..fillType = PathFillType.evenOdd
    ..addPolygon(points, true);

  @override
  bool shouldReclip(PolygonClipper oldClipper) => points != oldClipper.points;
}
