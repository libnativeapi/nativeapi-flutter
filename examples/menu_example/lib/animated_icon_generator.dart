import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart' hide Image;
import 'package:nativeapi/nativeapi.dart';

/// A generator for creating animated icons for MenuItem.
///
/// This class provides several built-in pixel animations that can be
/// continuously updated on a MenuItem's icon.
///
/// Example:
/// ```dart
/// final generator = AnimatedIconGenerator(size: 32);
/// final menuItem = MenuItem('Animated Item');
///
/// // Start a spinner animation
/// generator.startSpinner(
///   onFrame: (image) {
///     menuItem.icon = image;
///   },
/// );
///
/// // Stop animation when done
/// generator.stop();
/// ```
class AnimatedIconGenerator {
  final int size;
  final Color foregroundColor;
  final Color backgroundColor;
  final double devicePixelRatio;

  Timer? _animationTimer;
  int _currentFrame = 0;

  AnimatedIconGenerator({
    this.size = 32, // Higher default size for better quality
    this.foregroundColor = Colors.blue,
    this.backgroundColor = Colors.transparent,
    double? devicePixelRatio,
  }) : devicePixelRatio = devicePixelRatio ?? ui.window.devicePixelRatio;

  /// Start a spinning loader animation.
  ///
  /// The animation continuously rotates a circular loader. Update interval
  /// controls how fast the animation runs (lower = faster).
  Future<void> startSpinner({
    required Future<void> Function(Image) onFrame,
    Duration updateInterval = const Duration(milliseconds: 100),
  }) async {
    stop();

    _animationTimer = Timer.periodic(updateInterval, (timer) async {
      final image = await _generateSpinnerFrame();
      await onFrame(image);
    });
  }

  /// Start a pulsing dot animation.
  ///
  /// Creates a pulsing circular dot that expands and contracts.
  Future<void> startPulse({
    required Future<void> Function(Image) onFrame,
    Duration updateInterval = const Duration(milliseconds: 150),
  }) async {
    stop();

    _animationTimer = Timer.periodic(updateInterval, (timer) async {
      final image = await _generatePulseFrame();
      await onFrame(image);
    });
  }

  /// Start a blinking dot animation.
  ///
  /// Creates a simple on/off blinking effect.
  Future<void> startBlink({
    required Future<void> Function(Image) onFrame,
    Duration updateInterval = const Duration(milliseconds: 500),
  }) async {
    stop();

    _animationTimer = Timer.periodic(updateInterval, (timer) async {
      final image = await _generateBlinkFrame();
      await onFrame(image);
    });
  }

  /// Start a progress bar animation.
  ///
  /// Shows a horizontal progress bar that fills from left to right.
  Future<void> startProgress({
    required Future<void> Function(Image) onFrame,
    Duration updateInterval = const Duration(milliseconds: 80),
  }) async {
    stop();

    _animationTimer = Timer.periodic(updateInterval, (timer) async {
      final image = await _generateProgressFrame();
      await onFrame(image);
    });
  }

  /// Start a wave animation.
  ///
  /// Creates a vertical wave pattern that moves left to right.
  Future<void> startWave({
    required Future<void> Function(Image) onFrame,
    Duration updateInterval = const Duration(milliseconds: 100),
  }) async {
    stop();

    _animationTimer = Timer.periodic(updateInterval, (timer) async {
      final image = await _generateWaveFrame();
      await onFrame(image);
    });
  }

  /// Start a rotating square animation.
  ///
  /// Rotates a square icon continuously.
  Future<void> startRotatingSquare({
    required Future<void> Function(Image) onFrame,
    Duration updateInterval = const Duration(milliseconds: 100),
  }) async {
    stop();

    _animationTimer = Timer.periodic(updateInterval, (timer) async {
      final image = await _generateRotatingSquareFrame();
      await onFrame(image);
    });
  }

  /// Stop the current animation.
  void stop() {
    _animationTimer?.cancel();
    _animationTimer = null;
    _currentFrame = 0;
  }

  /// Dispose resources.
  void dispose() {
    stop();
  }

  // Setup canvas with high DPI scaling
  void _setupCanvas(Canvas canvas) {
    canvas.scale(devicePixelRatio, devicePixelRatio);
  }

  // Generate spinner frame
  Future<Image> _generateSpinnerFrame() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _setupCanvas(canvas);

    final paint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0; // Thicker line for better visibility

    final center = Offset(size / 2, size / 2);
    final radius = size / 2 - 3; // Adjust for thicker line

    final angle = (_currentFrame * 30) % 360;
    final rotationMatrix = Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..rotateZ(angle * math.pi / 180)
      ..translate(-center.dx, -center.dy);

    canvas.save();
    canvas.transform(rotationMatrix.storage);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi,
      false,
      paint,
    );

    canvas.restore();

    return await _imageFromCanvas(recorder);
  }

  // Generate pulse frame
  Future<Image> _generatePulseFrame() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _setupCanvas(canvas);

    final progress = (_currentFrame % 10) / 10.0;
    final scale = 0.35 + (progress * 0.65); // Slightly larger minimum size

    final paint = Paint()
      ..color = foregroundColor.withOpacity(
        0.9,
      ); // More opaque for better visibility

    final center = Offset(size / 2, size / 2);
    final radius = (size / 2 - 2) * scale; // More padding for clarity

    canvas.drawCircle(center, radius, paint);

    return await _imageFromCanvas(recorder);
  }

  // Generate blink frame
  Future<Image> _generateBlinkFrame() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _setupCanvas(canvas);

    final isOn = (_currentFrame % 2) == 0;

    if (isOn) {
      final paint = Paint()..color = foregroundColor;
      final center = Offset(size / 2, size / 2);
      final radius = size / 2 - 2; // More padding for better visibility

      canvas.drawCircle(center, radius, paint);
    }

    return await _imageFromCanvas(recorder);
  }

  // Generate progress frame
  Future<Image> _generateProgressFrame() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _setupCanvas(canvas);

    final progress = (_currentFrame % 13) / 12.0;

    final paint = Paint()..color = foregroundColor;

    final padding = 2.0; // Larger padding for better visibility
    final barHeight = size - 2 * padding;
    final barWidth = (size - 2 * padding) * progress;

    canvas.drawRect(
      Rect.fromLTWH(padding, padding, barWidth, barHeight),
      paint,
    );

    return await _imageFromCanvas(recorder);
  }

  // Generate wave frame
  Future<Image> _generateWaveFrame() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _setupCanvas(canvas);

    final paint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5; // Thicker line for better visibility

    final path = Path();
    final offset = (_currentFrame % size).toDouble();

    for (int i = 0; i < size; i++) {
      final x = i.toDouble();
      final y =
          size / 2 + (size / 4) * math.sin((i + offset) * 2 * math.pi / size);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    return await _imageFromCanvas(recorder);
  }

  // Generate rotating square frame
  Future<Image> _generateRotatingSquareFrame() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _setupCanvas(canvas);

    final paint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0; // Thicker line for better visibility

    final center = Offset(size / 2, size / 2);
    final angle = (_currentFrame * 10) % 360;

    final rotationMatrix = Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..rotateZ(angle * math.pi / 180)
      ..translate(-center.dx, -center.dy);

    canvas.save();
    canvas.transform(rotationMatrix.storage);

    final squareSize = (size - 6).toDouble(); // Adjust for thicker line
    final rect = Rect.fromLTWH(
      (size - squareSize.toInt()) / 2,
      (size - squareSize.toInt()) / 2,
      squareSize,
      squareSize,
    );

    canvas.drawRect(rect, paint);

    canvas.restore();

    return await _imageFromCanvas(recorder);
  }

  // Convert canvas to Image object with high DPI support
  Future<Image> _imageFromCanvas(ui.PictureRecorder recorder) async {
    final picture = recorder.endRecording();

    // Calculate high DPI image size (canvas already scaled by devicePixelRatio)
    final imageWidth = (size * devicePixelRatio).toInt();
    final imageHeight = (size * devicePixelRatio).toInt();

    final img = await picture.toImage(imageWidth, imageHeight);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Failed to convert image to bytes');
    }

    final pngBytes = byteData.buffer.asUint8List();
    final base64String = 'data:image/png;base64,${base64Encode(pngBytes)}';

    _currentFrame++;

    return Image.fromBase64(base64String)!;
  }
}
