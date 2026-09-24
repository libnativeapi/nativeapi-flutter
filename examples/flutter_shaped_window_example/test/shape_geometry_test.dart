import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shaped_window_example/shape_geometry.dart';

void main() {
  test(
    'all silhouettes paint transparent corners and an opaque centre',
    () async {
      for (final extent in [320.0, 400.0]) {
        for (final shape in DemoShape.values) {
          final recorder = ui.PictureRecorder();
          final canvas = ui.Canvas(recorder);
          canvas.clipPath(
            ShapeClipper(shape, extent).getClip(Size.square(extent)),
          );
          canvas.drawRect(
            Offset.zero & Size.square(extent),
            Paint()..color = const Color(0xFF7756F7),
          );
          final picture = recorder.endRecording();
          final image = await picture.toImage(extent.toInt(), extent.toInt());
          final data = (await image.toByteData())!;
          int alpha(int x, int y) =>
              data.getUint8((y * extent.toInt() + x) * 4 + 3);
          expect(alpha(5, 5), 0, reason: '$shape $extent corner');
          expect(alpha(extent ~/ 2, extent ~/ 2), 255);
          // Distinguishes the concave star/bubble from the circular bottom.
          if ([
            DemoShape.circle,
            DemoShape.star,
            DemoShape.bubble,
          ].contains(shape)) {
            expect(
              alpha(extent ~/ 2, (extent * .92).toInt()),
              shape == DemoShape.circle ? 255 : 0,
            );
          }
          image.dispose();
          picture.dispose();
        }
      }
    },
  );

  test('bubble tail remains visible and geometry invalidates on resize', () {
    const clipper = ShapeClipper(DemoShape.bubble, 400);
    final path = clipper.getClip(const Size.square(400));
    expect(path.contains(const Offset(80, 360)), isTrue);
    expect(path.contains(const Offset(200, 360)), isFalse);
    expect(path.fillType, PathFillType.evenOdd);
    expect(
      clipper.shouldReclip(const ShapeClipper(DemoShape.bubble, 320)),
      isTrue,
    );
    expect(
      clipper.shouldReclip(const ShapeClipper(DemoShape.circle, 400)),
      isTrue,
    );
    expect(
      clipper.shouldReclip(const ShapeClipper(DemoShape.bubble, 400)),
      isFalse,
    );
  });
  test(
    'morph endpoints preserve contours and all intermediate frames are valid',
    () {
      for (final extent in [320.0, 400.0]) {
        final contours = morphContours(extent);
        expect(contours.values.map((p) => p.length).toSet().length, 1);
        expect(contours.values.first.length, lessThan(4096));
        for (final shape in DemoShape.values) {
          final original = ShapeClipper(
            shape,
            extent,
          ).getClip(Size.square(extent));
          final sampled = PolygonClipper(contours[shape]!)
              .getClip(Size.square(extent));
          for (double y = 1.25; y < extent; y += 7) {
            for (double x = 1.25; x < extent; x += 7) {
              expect(
                sampled.contains(Offset(x, y)),
                original.contains(Offset(x, y)),
                reason: '$shape at $x,$y',
              );
            }
          }
        }
        for (final from in contours.values) {
          for (final to in contours.values) {
            expect(interpolateContour(from, to, 0), from);
            expect(interpolateContour(from, to, 1), to);
            for (final t in [.1, .25, .5, .75, .9]) {
              final frame = interpolateContour(from, to, t);
              expect(
                frame.every(
                  (p) =>
                      p.dx.isFinite &&
                      p.dy.isFinite &&
                      p.dx >= 0 &&
                      p.dy >= 0 &&
                      p.dx <= extent &&
                      p.dy <= extent,
                ),
                isTrue,
              );
              expect(
                PolygonClipper(frame)
                    .getClip(Size.square(extent))
                    .contains(Offset(extent / 2, extent / 2)),
                isTrue,
              );
            }
          }
        }
        final interrupted = interpolateContour(
          contours[DemoShape.circle]!,
          contours[DemoShape.star]!,
          .37,
        );
        expect(
          interpolateContour(interrupted, contours[DemoShape.bubble]!, 0),
          interrupted,
        );
      }
    },
  );
  test(
    'resize contours retain vertex correspondence and can retarget mid-frame',
    () {
      final small = morphContours(320);
      final large = morphContours(400);
      final fractional = morphContours(357.25);
      for (final shape in [...DemoShape.values, null]) {
        expect(small[shape]!.length, large[shape]!.length);
        expect(small[shape]!.length, fractional[shape]!.length);
        for (final t in [0.0, .25, .5, .75, 1.0]) {
          final extent = 320 + 80 * t;
          final frame = interpolateContour(small[shape]!, large[shape]!, t);
          final expected = morphContours(extent)[shape]!;
          for (var i = 0; i < frame.length; i++) {
            expect((frame[i] - expected[i]).distance, lessThan(1e-9));
          }
          // Reverse size and change shape while moving: the new transition must
          // start at the displayed polygon, without a jump or mismatched vertices.
          expect(interpolateContour(frame, small[DemoShape.star]!, 0), frame);
        }
      }
    },
  );
}
